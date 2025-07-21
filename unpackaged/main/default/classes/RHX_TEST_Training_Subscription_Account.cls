@isTest
public class RHX_TEST_Training_Subscription_Account {

    @testSetup
    static void testSetup(){
        
        // Normal Account
        Account activeAccount = new Account(
            Name = 'Active Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NCM Client').getRecordTypeId(),
            BillingStreet = '1 Auto Way',
            BillingCity = 'Sampleton',
            BillingState = 'North Carolina',
            BillingPostalCode = '28461',
            BillingCountry = 'United States',
            Validated_Account_Name__c = 'Sample Auto Group',
            Accounting_Invoice_Name__c = 'Sample Auto Group, Inc',
            Legal_Entity_Name__c = 'Sample Auto Group, Inc',
            AccountSource = 'Marketing', // required
            Industry = 'Auto Retail New', // required
            Franchise_s__c = 'Chevrolet',
            NumberOfEmployees = 400,
            AnnualRevenue = 30000000.00,
            NCMI_Client_Code__c = True
        );
        insert(activeAccount);

       
        
        // Primary Contact
        List<Contact> testContacts = new List<Contact>();
        Contact activeContact = new Contact(
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId(),
            FirstName = 'Marv',
            LastName = 'Sampleton',
            Title = 'CEO',
            NCM_Department__c = 'Executive',
            NCM_Title__c = 'Owner',
            AccountId = activeAccount.Id,
            Email = 'marv.sampleton@ncmassociates.com',
            MailingStreet = '100 Automotive Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        insert(activeContact);

        
        
        
        // Billing Account
        Billing_Account__c activeBillingAcct = new Billing_Account__c(
            Account__c = activeAccount.Id,
            Billing_Street__c = activeAccount.BillingStreet,
            Billing_City__c = activeAccount.BillingCity,
            Billing_State_Province__c = activeAccount.BillingState,
            Billing_Zip_Postal_Code__c = activeAccount.BillingPostalCode,
            Billing_Country__c = activeAccount.BillingCountry,
            Primary_Contact__c = activeContact.Id,
            Status__c = 'Validated'
        );
        insert(activeBillingAcct);
        

        // Add the Primary Billing Account (Finance Account) to the parent account.
        activeAccount.Primary_Billing_Account__c = activeBillingAcct.Id;
        update(activeAccount);
        

        Training_Subscription__c testTS1 = new Training_Subscription__c(
        	RecordTypeId = Schema.SObjectType.Training_Subscription__c.getRecordTypeInfosByName().get('Standard').getRecordTypeId(),
        	Account__c = activeAccount.Id,
            Contact__c = activeContact.Id,
            Plan__c = 'Basic',
            Start_Date__c = Date.today().addDays(-1),
            End_Date__c = Date.today().addYears(1),
            Price__c = 500.00
        );
        insert(testTS1);
        
        
        
        // Training Subscription Terms
        Training_Subscription_Term__c testTST1 = new Training_Subscription_Term__c(
            RecordTypeId = Schema.SObjectType.Training_Subscription_Term__c.getRecordTypeInfosByName().get('Monthly').getRecordTypeId(),
        	Account__c = activeAccount.Id,
            Contact__c = activeContact.Id,
            Start_Date__c = Date.today().addDays(-1),
            End_Date_Code__c = Date.today().addYears(1),
            Training_Subscription__c = testTS1.Id
        );
        insert(testTST1);
        


        // TSAs
        Training_Subscription_Account__c testTSA1 = new Training_Subscription_Account__c(
        	RecordTypeId = Schema.SObjectType.Training_Subscription_Account__c.getRecordTypeInfosByName().get('Standard').getRecordTypeId(),
        	Account__c = activeAccount.Id,
            Billing_Account__c = activeBillingAcct.Id,
            Contact__c = activeContact.Id,
            End_Date__c = Date.today().addYears(1),
            Training_Subscription__c = testTST1.Id
        );
        insert(testTSA1);
        
    }
    


	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM Training_Subscription_Account__c ORDER BY LastModifiedDate DESC LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Training_Subscription_Account__c()
            );
        }
    	

       rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}