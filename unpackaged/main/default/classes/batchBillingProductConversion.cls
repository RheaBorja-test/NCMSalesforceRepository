global class batchBillingProductConversion  implements Database.Batchable<sObject>, Database.Stateful {
    public accountingBridgeControllers accBrdCon = new accountingBridgeControllers();
    
    public final date tDay = date.today();
    global final boolean advance;
    global final string query;
    global final id invId;
    
    global batchBillingProductConversion(string qry, boolean adv, id invoiceId){
        advance = adv;
        this.query = qry;
        invId = invoiceId;
    }
    
    global database.Querylocator start(Database.BatchableContext BC){
        Database.QueryLocator result = Database.getQueryLocator(query);
        return result;
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        list<c2g__codaInvoiceLineItem__c> inLnItms = new list<c2g__codaInvoiceLineItem__c>();
        list<Billing_Product__c> bProds = new list<Billing_Product__c>();
        for(sObject sObj : scope){
            Billing_Product__c bProd = (Billing_Product__c)sObj;
            bProds.add(bProd);
            inLnItms.add(accBrdCon.createLineItem(bProd, invId));
        }
        
        Database.SaveResult[] srList = Database.insert(inLnItms, false);
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted Sales Invoice Line Item. Sales Invoice Line Item ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    system.debug(err.getMessage());
                }
            }
        }
        
        list<Billing_Product__c> bPrds = new list<Billing_Product__c>();
        for (c2g__codaInvoiceLineItem__c lnItm: inLnItms){
            if (lnItm.id != null){
                for(Billing_Product__c bProd : bProds){
                    if (lnItm.Billing_Product__c == bProd.id){
                        bPrds.add(accBrdCon.chkNextBill(bProd));
                        break;
                    }
                }
            }
        }
        
        if(bPrds.size() > 0){
            database.update(bPrds, false);
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}