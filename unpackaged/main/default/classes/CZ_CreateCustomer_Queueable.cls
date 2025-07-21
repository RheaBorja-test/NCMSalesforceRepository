public class CZ_CreateCustomer_Queueable implements Queueable, Database.AllowsCallouts{
    
    private List<Billing_Account__c> acctsToProcess;

    public CZ_CreateCustomer_Queueable(List<Billing_Account__c> billingAcctList) {
        this.acctsToProcess = billingAcctList;
    }



    public void execute(QueueableContext context) {
        
        final String logTag = '[CZ_CreateCustomer_Queueable] ';
        List<Billing_Account__c> baUpdates = new List<Billing_Account__c>();
        //Map<Id, String> resultMap = new Map<Id,String>();

        for(Billing_Account__c ba:acctsToProcess){
            System.debug(logTag + 'Creating ChargeZoom account for ' + ba.Name);

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
                System.debug(logTag + 'CZ createCustomer response: ' + resp);
                //ChargeZoomUtility.logResponse(resp.data.customerId, resp.data, 'CZ_LoadCustomerBatch');
                
                // Check if successful
                if(resp.code == 200){
                    System.debug(logTag + 'CZ create customer response: ' + resp.message + ' (' + resp.code + ')');
                    String czCustId = resp.data.customerId;
                    //resultMap.put(ba.Id, czCustId);
                    baUpdates.add(new Billing_Account__c(Id = ba.Id, CZ_CustomerId__c = czCustId));

                    // Activate the customer in cz.
                    //if(activateNewCustomers){
                        PaymentModel.CZCreateCustomerResponse statusResp = cz.updateCustomerStatus(czCustId, '1');
                        if(statusResp.code == 200){
                            System.debug(logTag+ czCustId + ' has been activated in ChargeZoom.');
                        } else {
                            System.debug(logTag + ' ERROR activating customer ' + czCustId + ' in ChargeZoom.' + statusResp.message);
                        }
                    //}

                } else {
                    System.debug(logTag + 'Error with CZ create customer api call: ' + resp.message);
                }
            } catch (Exception ex){
                System.debug('Error creating customer in ChargeZoom: ' + ex.getMessage());
            }
        }           
        
        if(!baUpdates.isEmpty()){
            Database.SaveResult[] saveResults = Database.update(baUpdates, false);
            Integer i=0;
            for(Database.SaveResult sr:saveResults){
                if( !sr.isSuccess() ){
                    Billing_Account__c ba = baUpdates[i];
                    System.debug(logTag + 'Error updating billing account ' + ba.Name + '. Error: ' + sr.getErrors()[0].getMessage());
                }
                i++;
            }
        }


        
    }
}