//Because of CZ api limitations, this batch should be run with a batchsize of 1.
//Should be scheduled to run each night after midnight to pick up the previous days changes.
public class BillingAccountChargeZoomSync implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    private final String logTag = '[BillingAccountChargeZoomSync]';
    public Integer count = 0;
    public Date overrideDate {get;set;}
    
    public BillingAccountChargeZoomSync() {}

    public Database.QueryLocator start(Database.BatchableContext bc){
        System.debug(logTag + 'Starting.');
                
        Date theDate = this.overrideDate != null ? overrideDate : Date.today().addDays(-1);
		System.debug(logTag + 'theDate: ' + theDate);
        
        // We want to update ChargeZoom if the Billing Contact's Email has changed also - so we will need to query the ContactHistory
        // object for all contacts whose Email changed yesterday and sync their billing account info over to CZ as well.
        Set<Id> updatedContactIdSet = new Set<Id>();
        for(ContactHistory ch:[SELECT ContactId from ContactHistory WHERE CreatedDate >= :theDate and Field = 'Email']){
            updatedContactIdSet.add(ch.ContactId);
        }
		System.debug(logTag + 'updatedContactIdSet has ' + updatedContactIdSet.size() + ' contacts that have changed.');
        
        String qry = 'SELECT Id, Name, CZ_CustomerId__c, Primary_Contact__r.FirstName, Primary_Contact__r.LastName,' + 
        ' Billing_Street__c, Billing_City__c, Billing_State_Province__c, Billing_Zip_Postal_Code__c, Billing_Country__c,' +
        ' Primary_Contact__r.Email, Primary_Contact__r.Phone, Account__r.Name FROM Billing_Account__c' + 
        ' WHERE CZ_CustomerId__c != null ' +
            'AND (LastModifiedDate >= :theDate OR Primary_Contact__c IN :updatedContactIdSet)';
        
        System.debug(logTag + 'query: ' + qry);

        return Database.getQueryLocator(qry);
    }

    public void execute(Database.BatchableContext bc, List<Billing_Account__c> scope){
        
        for(Billing_Account__c ba: scope) {
            System.debug(logTag + '\t' + ba.Name);
            PaymentModel.CZCreateCustomer custData = new PaymentModel.CZCreateCustomer();
            custData.customerCompanyName = ba.Account__r.Name;
            custData.customerFullName = ba.Account__r.Name;
            custData.customerFirstName = ba.Primary_Contact__r.FirstName;
            custData.customerLastName = ba.Primary_Contact__r.LastName;
            custData.customerContact = ba.Primary_Contact__r.Phone;
            custData.customerEmail = ba.Primary_Contact__r.Email;
            custData.bAddress1 = ba.Billing_Street__c;
            custData.bCity = ba.Billing_City__c;
            custData.bState = ba.Billing_State_Province__c;
            custData.bZipcode = ba.Billing_Zip_Postal_Code__c;
            custData.bCountry = ba.Billing_Country__c;
            PaymentModel.CZCreateCustomerResponse resp = new ChargeZoomUtility().editCustomer(custData, ba.CZ_CustomerId__c);
            if(resp.code == 200) {
                count++;
            } else {
                System.debug(logTag + resp.message);
                Logger.logErrorEvent(logTag, null, UserInfo.getName(), String.valueOf(resp.code), resp.message, ba.CZ_CustomerId__c, ba.Id);
            }
        }
    }

    public void finish(Database.BatchableContext bc){
        System.debug(logTag + 'There were ' + count + ' Billing Account records synced with ChargeZoom.');
    }
}