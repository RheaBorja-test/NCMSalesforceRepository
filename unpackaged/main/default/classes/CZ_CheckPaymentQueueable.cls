public class CZ_CheckPaymentQueueable implements Queueable, Database.AllowsCallouts{

    private List<CZ_Check_Payment__e> cpList;
    

    public CZ_CheckPaymentQueueable(List<CZ_Check_Payment__e> cpList) {
        this.cpList = cpList;
    }

    public void execute(QueueableContext context) {
        ChargeZoomUtility cz = new ChargeZoomUtility();
        String logTag = 'CZ_CheckPaymentQueueable::execute';
        List<c2g__codaTransactionLineItem__c> tliUpdates = new List<c2g__codaTransactionLineItem__c>();

        for(CZ_Check_Payment__e check: this.cpList) {
            try {
                PaymentModel.CZCheckPayment cp = new PaymentModel.CZCheckPayment();
                cp.checkNumber = check.checkNumber__c;
                cp.invoiceId = check.invoiceId__c;
                cp.payAmount = check.payAmount__c;
                cp.paymentDate = String.valueOf(check.paymentDate__c);
        
                PaymentModel.CZCheckPaymentResponse resp = cz.createOfflinePayment(cp);
                System.debug(logTag + 'CZ createOfflinePayment response: ' + resp);
                
                // Check if successful
                if(resp.code == 200){
                    String czPymtId = resp.data.transactionID;
                    tliUpdates.add(new c2g__codaTransactionLineItem__c(Id = check.tliId__c, CZ_OfflinePymtId__c = czPymtId));
                } else {
                    System.debug(logTag + 'Error with CZ create check payment api call: ' + resp.message);
                    Logger.logErrorEvent(logTag, null, UserInfo.getName(),'api call - ' + resp.code,  resp.message, JSON.serializePretty(cp));
                }
            } catch (Exception ex){
                System.debug('Error creating check payment in ChargeZoom: ' + ex.getMessage());
                Logger.logErrorEvent(logTag, null, UserInfo.getName(), ex.getTypeName(), ex.getMessage(), ex.getStackTraceString(), check.tliId__c);
            }  
        }  

        if(!tliUpdates.isEmpty()){
            Database.SaveResult[] dsrList = Database.update(tliUpdates, false);
            //check for 'UNABLE_TO_LOCK_ROW' errors to retry otherwise log errors
            for(Integer i = 0; i < dsrList.size(); i++) {
                if(!dsrList[i].isSuccess()) {
                    if(dsrList[i].getErrors()[0].getStatusCode().Name() == 'UNABLE_TO_LOCK_ROW') {
                        retryDML(tliUpdates[i], 0, dsrList[i]);
                    } else {
                        Logger.logErrorEvent(logTag, null, UserInfo.getName(), dsrList[i].getErrors()[0].getStatusCode().Name(), dsrList[i].getErrors()[0].getMessage(), JSON.serializePretty(tliUpdates[i]), tliUpdates[i].Id);
                    }
                }
            }
        }
    }

    public static void retryDML(c2g__codaTransactionLineItem__c tli, Integer counter, Database.SaveResult dsr) {
        System.debug('~~~retryDML: '  + counter);
        String logTag = 'CZ_CheckPaymentQueueable::retryDML::' + counter ;
        if(counter < 5) {
            try {
                update tli;
            } catch (Exception ex) {
                if(ex.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                    counter++;
                    retryDML(tli, counter, dsr);
                } else {
                    Logger.logException(logTag, tli.Id, ex);
                }
            }
        } else {
            Logger.logErrorEvent(logTag, null, UserInfo.getName(), dsr.getErrors()[0].getStatusCode().Name(), dsr.getErrors()[0].getMessage(), JSON.serializePretty(tli), tli.Id);
        }
    }
}