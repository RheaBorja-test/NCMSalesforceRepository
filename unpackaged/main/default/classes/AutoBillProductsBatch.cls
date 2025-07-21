//This batch should be called with a batch size of 25 or less
//There is a custom setting AutoBillProductsBatchSettings__c.qty used to set batch size when scheduled.

global class AutoBillProductsBatch implements Database.Batchable<SObject>,Database.Stateful, Schedulable{
    public Id ffCompanyId;
	public Id companyCurrencyId;
    public String ffAccountRef;
    public String CC = 'Candidate Composite';
    public String SF = 'Setup Fee';

    public List<Id> invoiceIds;

    global void execute(System.SchedulableContext sc) {
        Integer x = (Integer) AutoBillProductsBatchSettings__c.getInstance().Qty__c;
        Database.executeBatch(new AutoBillProductsBatch(), x);
    }
    
    public AutoBillProductsBatch() {
        //instantiate list to collect ids of invoices created
        this.invoiceIds = new List<Id>();

        this.ffCompanyId = [SELECT Name, Id, CreatedDate
                            FROM c2g__codaCompany__c
                            ORDER BY CreatedDate ASC
                            LIMIT 1].Id;
        this.companyCurrencyId = [SELECT c2g__OwnerCompany__c, Name
                                    FROM c2g__codaAccountingCurrency__c
                                    WHERE Name = 'USD'
                                    LIMIT 1].Id;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //Query for Active billing products for candidate composite that are due to be billed.        
        String ACTIVE = 'Active';
        String query = 'SELECT Id, Name, Dimension_1__c, Dimension_2__c, Dimension_3__c, Dimension_4__c, Product__c, '
			+ 'Product__r.Type__c, Description__c, Value__c, Next_Billing_Date__c, Last_Billed_Date__c, Quantity__c, '
			+ 'Billing_Frequency__c, Recurring_Billing_Day__c, Final_Bill_Date__c, Billing_Account__c, '
            + 'Billing_Account__r.Primary_Contact__c, Billing_Account__r.Account__c, Billing_Account__r.Billing_Street__c, '
            + 'Billing_Account__r.Billing_City__c, Billing_Account__r.Billing_State_Province__c, Billing_Account__r.Billing_Country__c, '
            + 'Billing_Account__r.Billing_Zip_Postal_Code__c '
			+ 'FROM Billing_Product__c WHERE (Product__r.Type__c = :CC OR Product__r.Type__c = :SF) AND '
            + 'Billing_Product_Status__c = :ACTIVE AND Next_Billing_Date__c <= TODAY';
        System.debug(query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Billing_Product__c> scope) {
        String logTag = 'AutoBillProducts::execute';
        List<c2g__codaInvoiceLineItem__c> lineItemList = new List<c2g__codaInvoiceLineItem__c>();
        List<c2g__codaInvoice__c> invoiceList = new List<c2g__codaInvoice__c>();
        List<SObject> sObs = new List<SObject>();

        Map<Id,Billing_Product__c> bpMap = new Map<Id,Billing_Product__c>(scope);

        for(Billing_Product__c bProd : scope) {
            //Create an Invoice Line Item for each billing product
            c2g__codaInvoiceLineItem__c ili = new c2g__codaInvoiceLineItem__c(
                c2g__Product__c = bProd.Product__c,
                c2g__DeriveUnitPriceFromProduct__c = false,
                c2g__Quantity__c = bProd.Quantity__c,
                c2g__LineDescription__c = bProd.Description__c,
                c2g__UnitPrice__c = bProd.Value__c,
                c2g__TaxValue1__c = 0,
                c2g__DeriveTaxRate1FromCode__c = false,
                c2g__CalculateTaxValue1FromRate__c = false,
                Billing_Product__c = bProd.id,
                c2g__Dimension1__c = bProd.Dimension_1__c,
                c2g__Dimension2__c = bProd.Dimension_2__c,
                c2g__Dimension3__c = bProd.Dimension_3__c,
                c2g__Dimension4__c = bProd.Dimension_4__c
            );
            
            //use an external Id field to reference the Line Items to the correct Invoice.
            String extId = bProd.Id + String.valueOf(Date.today());
            c2g__codaInvoice__c invoiceReference = new c2g__codaInvoice__c(AutoBillExtId__c = extId);
            ili.c2g__Invoice__r = invoiceReference;
            lineItemList.add(ili);

            //create a sales invoice for each billing product
            c2g__codaInvoice__c invoice = new c2g__codaInvoice__c(
                c2g__Account__c = bProd.Billing_Account__r.Account__c,
                Billing_Account__c = bProd.Billing_Account__r.Id,
                c2g__InvoiceStatus__c = 'In Progress',
                c2g__OwnerCompany__c = ffCompanyId,
                c2g__InvoiceCurrency__c = companyCurrencyId,
                c2g__CopyAccountValues__c = false,  // disable copy of tax code details from account record
                c2g__CustomerReference__c = ffAccountRef,
                Billing_Street__c = bProd.Billing_Account__r ?.Billing_Street__c,
                Billing_City__c = bProd.Billing_Account__r ?.Billing_City__c,
                Billing_State__c = bProd.Billing_Account__r ?.Billing_State_Province__c,
                Billing_Zip_Code__c = bProd.Billing_Account__r ?.Billing_Zip_Postal_Code__c,
                Billing_Country__c = bProd.Billing_Account__r ?.Billing_Country__c,
                AutoBillExtId__c = extId
            );
            invoiceList.add(invoice);
        }
        //combine the lists into one list to insert, adding the invoices before the line items 
        //so the external Id reference works correctly
        sObs.addAll(invoiceList);
        sObs.addAll(lineItemList);

        //Insert Invoices and Line Items and log any errors
        List<Database.SaveResult> results = Database.insert(sObs, false);
        Logger.logErrorList(logTag, results, sObs);

        //find successful inserts to post and update billing products
        String p = c2g__codaInvoiceLineItem__c.SObjectType.getDescribe().getKeyPrefix();
        System.debug('~~~InvoiceLineItem prefix: ' + p);
        List<Id> invIdList = new List<Id>();
        List<Billing_Product__c> billProdsList = new List<Billing_Product__c>();
        for(Integer i = 0; i < results.size(); i++) {
            System.debug('~~~sObs[i]: ' + sObs[i]);
            if(results[i].isSuccess() && String.valueOf(sObs[i].Id).left(3).equals(p)) { 
                c2g__codaInvoiceLineItem__c ili = (c2g__codaInvoiceLineItem__c) sObs[i];
                billProdsList.add(bpMap.get(ili.Billing_Product__c));
            } else if (results[i].isSuccess()) {
                c2g__codaInvoice__c inv = (c2g__codaInvoice__c) sObs[i];
                invIdList.add(inv.Id);
            }
        }
        this.invoiceIds.addAll(invIdList);

        //post the invoices by setting the c2g__TriggerPosting__c = 'Synchronous' or 'Asynchronous'
        List<c2g__codaInvoice__c> invPostList = new List<c2g__codaInvoice__c>();
        for(Id invId : invIdList) {
            invPostList.add(new c2g__codaInvoice__c(Id = invId, c2g__TriggerPosting__c = 'Asynchronous'));
        }
        List<Database.SaveResult> dsrList = Database.update(invPostList, false);
        Logger.logErrorList(logTag, dsrList, invPostList);

        //update the billing products with next billing date, etc.
        List<Billing_Product__c> bpList = new List<Billing_Product__c>();
        for(Billing_Product__c bp : billProdsList) {
            if(bp.Product__r.Type__c.equalsIgnoreCase(CC)) {
                bpList.add(new Billing_Product__c(Id = bp.Id,
                        Next_Billing_Date__c = getDate(bp),
                        Last_Billed_Date__c = Date.today()));
            } else if(bp.Product__r.Type__c.equalsIgnoreCase(SF)) {
                bpList.add(new Billing_Product__c(Id = bp.Id,
                        Last_Billed_Date__c = Date.today(),
                        Final_Bill_Date__c = Date.today(),
                        Billing_Product_Status__c = 'Inactive'));
            }
        }
        if(bpList.size() > 0) {
            List<Database.SaveResult> dsrList2 = Database.update(bpList, false);
            Logger.logErrorList(logTag, dsrList2, bpList);
        }
    }

    global void finish(Database.BatchableContext BC) {
        //send the list of invoice ids to CZ
        if(invoiceIds.size() > 0) {
            //shedule the batch to run in x minutes so that FF asynch processes have time to complete
            Integer x = (Integer) AutoBillProductsBatchSettings__c.getInstance().Delay__c;
            if(!Test.isRunningTest()) {
                System.scheduleBatch(new SendInvoicesToCZBatch(invoiceIds), 'SendInvoices', x, 1);
            }
        }        
    }

    public static Date getDate(Billing_Product__c bp) {
        integer mnth;
		integer yr;

        mnth = Date.Today().addMonths(1).month();
        yr = Date.Today().addMonths(1).year();
        return Date.newInstance(yr, mnth, integer.valueof(bp.Recurring_Billing_Day__c));
    }
}