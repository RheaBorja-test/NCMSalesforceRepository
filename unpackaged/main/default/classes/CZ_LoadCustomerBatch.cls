public class CZ_LoadCustomerBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    

    public String billingAccountId {get;set;}
    public List<Id> billingAccountIdList {get;set;}
    public Boolean activateNewCustomers {get;set;}

    private final String logTag = '[CZ_LoadCustomerBatch]';
    private List<Billing_Account__c> baUpdates;


    public CZ_LoadCustomerBatch() {
       baUpdates = new List<Billing_Account__c>();
    }

    public CZ_LoadCustomerBatch(Id billingAccountId) {
        baUpdates = new List<Billing_Account__c>();
        this.billingAccountId = billingAccountId;
    }

    public CZ_LoadCustomerBatch(List<Id> billingAccountIdList) {
        baUpdates = new List<Billing_Account__c>();
        this.billingAccountIdList = billingAccountIdList;
    }


    public Database.QueryLocator start(Database.BatchableContext BC) {
        String qry = 'SELECT Id, Name, Billing_Street__c, Billing_City__c, Billing_State_Province__c, Billing_Zip_Postal_Code__c, Billing_Country__c, ' + 
                        'Account__r.Name, Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingStateCode, Account__r.ShippingPostalCode, Account__r.ShippingCountryCode, ' + 
                        'Primary_Contact__r.FirstName, Primary_Contact__r.LastName, Primary_Contact__r.Email, Primary_Contact__r.Phone ' + 
                    'FROM Billing_Account__c WHERE CZ_CustomerId__c = null AND Primary_contact__c != null';
        
        // If a Billing Account ID was passed to the batch, just process that one billing account.
        if(this.billingAccountId != null){
            qry += ' AND Id = \'' + this.billingAccountId + '\'';
        } 

        //If a list of Billing Account Ids was  passed to the batch, just process those billing accounts.
        if(this.billingAccountIdList != null){
            List<Id> billingAccountIdList = this.billingAccountIdList;
            qry += ' AND Id IN :billingAccountIdList';
        }

        System.debug(logTag + 'Query: ' + qry);
        return Database.getQueryLocator(qry);
    }


    public void execute(Database.BatchableContext BC, List<Billing_Account__c> scope) {
        
        System.debug(logTag + 'There are Billing Accounts to process (scope size).');

        
        for(Billing_Account__c ba : scope){
            PaymentModel.CZCreateCustomer cust = new PaymentModel.CZCreateCustomer();
            cust.customerCompanyName = ba.Account__r.Name;
            cust.customerFullName = ba.Account__r.Name;
            cust.customerFirstName = ba.Primary_Contact__r.FirstName;
            cust.customerLastName = ba.Primary_Contact__r.LastName;
            cust.customerContact = ba.Primary_Contact__r.Phone;
            cust.customerEmail = ba.Primary_Contact__r.Email;
            cust.bAddress1 = ba.Billing_Street__c;
            cust.bAddress2 = null;
            cust.bCity = ba.Billing_City__c;
            cust.bState = ba.Billing_State_Province__c;
            cust.bZipcode = ba.Billing_Zip_Postal_Code__c;
            cust.bCountry = ba.Billing_Country__c;
            cust.sAddress1 = ba.Account__r.ShippingStreet;
            cust.sAddress2 = null;
            cust.sCity = ba.Account__r.ShippingCity;
            cust.sState = ba.Account__r.ShippingStateCode;
            cust.sZipcode = ba.Account__r.ShippingPostalCode;
            cust.sCountry = ba.Account__r.ShippingCountryCode;

            try{
                ChargeZoomUtility cz = new ChargeZoomUtility();
                PaymentModel.CZCreateCustomerResponse resp = cz.createCustomer(cust);
                //System.debug(logTag + 'CZ createCustomer response: ' + resp);
                //ChargeZoomUtility.logResponse(resp.data.customerId, resp.data, 'CZ_LoadCustomerBatch');
                // Check if successful
                if(resp.code == 200){
                    System.debug(logTag + 'CZ create customer response: ' + resp.message + ' (' + resp.code + ')');
                    String czCustId = resp.data.customerId;
                    baUpdates.add(new Billing_Account__c(Id = ba.Id, CZ_CustomerId__c = czCustId));

                    // Activate the customer in cz.
                    if(this.activateNewCustomers){
                        PaymentModel.CZCreateCustomerResponse statusResp = cz.updateCustomerStatus(czCustId, '1');
                        if(statusResp.code == 200){
                            System.debug(logTag+ czCustId + ' has been activated in ChargeZoom.');
                        } else {
                            System.debug(logTag + ' ERROR activating customer ' + czCustId + ' in ChargeZoom.' + statusResp.message);
                        }
                    }

                } else {
                    System.debug(logTag + 'Error with CZ create customer api call: ' + resp.message);
                }
            } catch (Exception ex){
                System.debug('Error creating customer in ChargeZoom: ' + ex.getMessage());
            }

        }

    }


    public void finish(Database.BatchableContext BC) {
        System.debug(logTag + 'CZ_LoadCustomerBatch::finish');  
        
        if( !baUpdates.isEmpty() ){
            System.debug(logTag + 'There are ' + baUpdates.size() + ' Billing Accounts to udpate with a CZ Customer Id code.');
            Database.SaveResult[] saveResults = Database.update(baUpdates, false);
            Integer i=0;
            for(Database.SaveResult sr:saveResults){
                if( !sr.isSuccess() ){
                    Billing_Account__c ba = baUpdates[i];
                    System.debug(logTag + 'Error updating billing account ' + ba.Name + '. Error: ' + sr.getErrors()[0].getMessage());
                }
                i++;
            }
        } else {
            System.debug(logTag + 'No Billing Accounts to update.');
        }  
        
    }
}