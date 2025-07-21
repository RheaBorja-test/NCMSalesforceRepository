public class ChargeZoomSetup {
    
    public static void loadCustomers(){

        // Get all Billing Products last billed in May 2024
        AggregateResult[] mayBillingProducts = [select Billing_Account__c, count(id) from Billing_Product__c where Last_Billed_Date__c >= 2024-05-01 and Last_Billed_Date__c <= 2024-05-31 group by Billing_Account__c];
        System.debug('Total May accounts: ' + mayBillingProducts.size());
        Set<Id> billingAcctIdSet = new Set<Id>();

        for(AggregateResult ar:mayBillingProducts){ 
            billingAcctIdSet.add( String.valueOf(ar.get('Billing_Account__c')) ); 
        }


        // Get all Billing Products w/ a Next Bill Date of July 1, 2024.
        AggregateResult[] julyBillingProducts = [select Billing_Account__c, count(id) from Billing_Product__c where Next_Billing_Date__c >= 2024-07-01 group by Billing_Account__c];
        System.debug('Total July accounts: ' + julyBillingProducts.size());
        
        for(AggregateResult ar:julyBillingProducts){ 
            billingAcctIdSet.add( String.valueOf(ar.get('Billing_Account__c')) ); 
        }

        System.debug('There are ' + billingAcctIdSet.size() + ' Billing Accounts to create in Chargezoom.');

        List<Billing_Account__c> baList = [SELECT 
                                            Id, 
                                            Name,
                                            Account__r.Name,
                                            Account__r.ShippingStreet,
                                            Account__r.ShippingCity,
                                            Account__r.ShippingStateCode,
                                            Account__r.ShippingPostalCode,
                                            Account__r.ShippingCountryCode,
                                            Primary_Contact__r.FirstName,
                                            Primary_Contact__r.LastName,
                                            Primary_Contact__r.Phone,
                                            Primary_Contact__r.Email,
                                            Billing_Street__c,
                                            Billing_City__c,
                                            Billing_State_Province__c,
                                            Billing_Zip_Postal_Code__c,
                                            Billing_Country__c
                                        FROM Billing_Account__c
                                        WHERE Id IN :billingAcctIdSet
                                           	AND CZ_CustomerId__c = null];
        System.debug('Creating ' + baList.size() + ' accounts in Chargezoom.');

        // Create the customers in ChargeZoom
        CZ_CreateCustomer_Queueable czCreateJob = new CZ_CreateCustomer_Queueable(baList);
        System.enqueueJob(czCreateJob);
        

    }
}