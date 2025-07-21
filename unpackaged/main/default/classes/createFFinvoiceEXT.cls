public class createFFinvoiceEXT {
    public apexpages.standardcontroller stdController;
    public id oppId;
    public Opportunity opp;
    public list<OpportunityLineItem> oppLnItms;
    
	public createFFinvoiceEXT(apexpages.standardcontroller stdController){
        this.stdController = stdController;
        oppId = ApexPages.currentPage().getParameters().get('id');
    }
    
    public Opportunity getopp(){
        opp = [select id, AccountId, OEM_Record__c, Billing_Street__c, Billing_State__c, OEM_Record__r.OEM_Account__c,
               	Billing_Zip_Code__c, Billing_Contact__c, Billing_City__c, Invoice_Date__c, Billing_Account__c, Billing_Account__r.Account__c 
               from Opportunity 
               where id = :oppId];
        
        return opp;
    }
    
    public list<OpportunityLineItem> getoppLnItms(){
        if (opp == null){
            getopp();
        }
        oppLnItms = [select id, Product2Id, Quantity, UnitPrice, Description, Ready_to_Invoice__c, Invoiced__c,
                     	Dimension_1__c, Dimension_2__c, Dimension_3__c, Dimension_4__c, Billing_Product__c
                     from OpportunityLineItem 
                     where OpportunityId = :oppId and Invoiced__c = false];
        
        return oppLnItms;
    }
    
    public PageReference createInvoice(){
        boolean isSuccess = true;
        try{
            update opp;
        } catch(DMLexception er) {
            system.debug(er);
            apexpages.addMessage(new apexpages.message(ApexPages.Severity.ERROR, 'Could not Update Opportunity: ' + er.getMessage()));
            isSuccess = false;
        }
        try{
            update oppLnItms;
        } catch(DMLexception er) {
            system.debug(er);
            apexpages.addMessage(new apexpages.message(ApexPages.Severity.ERROR, 'Could not Update Opportunity Line Items: ' + er.getMessage()));
            isSuccess = false;
        }
        
        boolean hsLineItems = false;
        for (OpportunityLineItem lnItm : oppLnItms){
            if (lnItm.Invoiced__c == false && lnItm.Ready_to_Invoice__c == true) {
                hsLineItems = true;
                break;
            }
        }
        
        c2g__CodaInvoice__c inv = new c2g__CodaInvoice__c();
        if (isSuccess && hsLineItems){
            inv.c2g__Opportunity__c = opp.id;
            inv.c2g__InvoiceDate__c = opp.Invoice_Date__c;
            inv.Billing_City__c = opp.Billing_City__c;
            inv.Billing_Contact2__c = opp.Billing_Contact__c;
            inv.Billing_State__c = opp.Billing_State__c;
            inv.Billing_Street__c = opp.Billing_Street__c;
            inv.Billing_Zip_Code__c = opp.Billing_Zip_Code__c;
            inv.c2g__DeriveCurrency__c = true;
            inv.c2g__DeriveDueDate__c = true;
            inv.c2g__Dimension1__c = oppLnItms.get(0).Dimension_1__c;
            inv.c2g__Dimension2__c = oppLnItms.get(0).Dimension_2__c;
            
            inv.Billing_Account__c = opp.Billing_Account__c;
            if (opp.Billing_Account__c != null){
                inv.c2g__Account__c = opp.Billing_Account__r.Account__c;
            } else if(opp.OEM_Record__c != null){
                inv.c2g__Account__c = opp.OEM_Record__r.OEM_Account__c;
            } else {
                inv.c2g__Account__c = opp.AccountId;
            }
            
            try{
                insert inv;
            } catch(DMLexception er) {
                system.debug(er);
                apexpages.addMessage(new apexpages.message(ApexPages.Severity.ERROR, 'Could not Create Invoice: ' + er.getMessage()));
                isSuccess = false;
            } 
        } else if (hsLineItems == false){
            apexpages.addMessage(new apexpages.message(ApexPages.Severity.WARNING, 'No Line Items were marked to be Invoiced'));
            isSuccess = false;
        }
        
        if (isSuccess){
            PageReference invURL = new PageReference('/' + inv.id);
            invURL.setRedirect(true);
            return invURL;
        } else {
            return null;
        }
        
    }
}