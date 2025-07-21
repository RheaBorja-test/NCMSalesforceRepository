global class FFtoCZBalanceBatch implements Database.Batchable<SObject>,Database.Stateful, Database.AllowsCallouts, Schedulable {
    
    global List<String> sINList;
    global List<String> correctionsMade;
    global List<String> manualCorrectionsNeeded;
    global ChargeZoomUtility czu;

    public FFtoCZBalanceBatch() {
        this.correctionsMade = new  List<String>();
        this.manualCorrectionsNeeded = new  List<String>();
        this.sINList = new List<String>();
    }

    public void execute(System.SchedulableContext sc) {
        Integer x = (Integer) FFtoCZBalanceBatchSettings__c.getInstance().Qty__c;
        Database.executeBatch(new FFtoCZBalanceBatch(), x);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {        
        List<String> sINList = this.sINList;
        this.czu = new ChargeZoomUtility();
        String INVOICED = 'Invoiced';
        String qry = 'SELECT Id, Name, CZ_InvoiceId__c, c2g__OutstandingValue__c ' +
                    'FROM c2g__codaInvoice__c WHERE CZ_Invoicing_Status__c = :INVOICED' + 
                    ' AND LastModifiedDate = LAST_N_DAYS:' + 
                    (Integer) FFtoCZBalanceBatchSettings__c.getInstance().Days__c;
        if(sINList.size() > 1) {
            qry = 'SELECT Id, Name, CZ_InvoiceId__c, c2g__OutstandingValue__c ' +
                    'FROM c2g__codaInvoice__c WHERE Name IN :sINList';
        }
        return Database.getQueryLocator(qry);
    }

    global void execute(Database.BatchableContext BC, List<c2g__codaInvoice__c> scope) {
        for(c2g__codaInvoice__c inv : scope) {
            if(String.isNotEmpty(inv.CZ_InvoiceId__c)) {
                try {
                    PaymentModel.CZInvoicesDetail czInv = czu.getInvoice(inv.CZ_InvoiceId__c);
                    Double diff = Double.valueOf(czInv.data.invoiceBalance.remove(',')) - (Double) inv.c2g__OutstandingValue__c;
                    System.debug('~~~diff: ' + diff);
                    if(diff > 0) {
                        PaymentModel.CZCheckPayment cp = new PaymentModel.CZCheckPayment();
                        cp.checkNumber = 'adjustment';
                        cp.invoiceId = czInv.data.invoiceId;
                        cp.payAmount = diff;
                        cp.paymentDate = String.valueOf(Date.today());
                
                        PaymentModel.CZCheckPaymentResponse resp = czu.createOfflinePayment(cp);
                        // Check if successful
                        if(resp.code == 200){
                            String czPymtId = resp.data.transactionID;
                            this.correctionsMade.add(inv.Name + ' payment added $' + diff + ' - ' + resp.data.transactionID);
                        } else {
                            Logger.logErrorEvent('FFtoCZBalanceBatch', null, UserInfo.getName(),'api call - ' + resp.code,  resp.message, JSON.serializePretty(cp));
                        }
                    } else if(diff < 0) {
                        this.manualCorrectionsNeeded.add(inv.Name);
                    }
                } catch(Exception ex) {
                    Logger.logException('FFtoCZBatch', inv.Id, ex);
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        //Log Corrections made and needed.
        List<ExceptionLogEvent__e> eventList = new List<ExceptionLogEvent__e>();

        for(String s : this.correctionsMade) {
            ExceptionLogEvent__e logEvent = new ExceptionLogEvent__e();
            logEvent.Source__c = 'CZ Correction Made';
            logEvent.User_Name__c = 'Nightly Batch';
            logEvent.Error_Type__c = 'Correction';
            logEvent.Description__c = s;
            logEvent.Date_Time__c = DateTime.Now();
            eventList.add(logEvent);
        }

        for(String s : this.manualCorrectionsNeeded) {
            ExceptionLogEvent__e logEvent = new ExceptionLogEvent__e();
            logEvent.Source__c = 'Manual CZ Correction Required';
            logEvent.User_Name__c = 'Nightly Batch';
            logEvent.Error_Type__c = 'Correction';
            logEvent.Description__c = s + ' has a higher balance in FF than in CZ';
            logEvent.Date_Time__c = DateTime.Now();
            eventList.add(logEvent);
        }
        EventBus.publish(eventList);
    }
}