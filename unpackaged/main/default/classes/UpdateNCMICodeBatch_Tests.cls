@isTest
public class UpdateNCMICodeBatch_Tests {

    @testSetup
    static void testSetup(){
        
        // Normal Account
        List<Account> testAccounts = new List<Account>();
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
        testAccounts.add(activeAccount);

        Account inactiveAccount = new Account(
            Name = 'Inactive Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NCM Client').getRecordTypeId(),
            BillingStreet = '2 Auto Way',
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
        testAccounts.add(inactiveAccount);
        insert(testAccounts);
        
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
        testContacts.add(activeContact);

        Contact inactiveContact = new Contact(
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId(),
            FirstName = 'Len',
            LastName = 'Clayton',
            Title = 'CEO',
            NCM_Department__c = 'Executive',
            NCM_Title__c = 'Owner',
            AccountId = inactiveAccount.Id,
            Email = 'len@ncmassociates.com',
            MailingStreet = '444 New Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        testContacts.add(inactiveContact);
        insert(testContacts);
        
        
        // Billing Account
        List<Billing_Account__c> testBillingAccts = new List<Billing_Account__c>();
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
        testBillingAccts.add(activeBillingAcct);
        Billing_Account__c inactiveBillingAcct = new Billing_Account__c(
            Account__c = inactiveAccount.Id,
            Billing_Street__c = inactiveAccount.BillingStreet,
            Billing_City__c = inactiveAccount.BillingCity,
            Billing_State_Province__c = inactiveAccount.BillingState,
            Billing_Zip_Postal_Code__c = inactiveAccount.BillingPostalCode,
            Billing_Country__c = inactiveAccount.BillingCountry,
            Primary_Contact__c = inactiveContact.Id,
            Status__c = 'Validated'
        );
        testBillingAccts.add(inactiveBillingAcct);
        insert(testBillingAccts);

        // Add the Primary Billing Account (Finance Account) to the parent account.
        activeAccount.Primary_Billing_Account__c = activeBillingAcct.Id;
        update(activeAccount);
        inactiveAccount.Primary_Billing_Account__c = inactiveBillingAcct.Id;
        update(inactiveAccount);
        

        List<Training_Subscription__c> tsList = new List<Training_Subscription__c>();
        Training_Subscription__c testTS1 = new Training_Subscription__c(
        	RecordTypeId = Schema.SObjectType.Training_Subscription__c.getRecordTypeInfosByName().get('Standard').getRecordTypeId(),
        	Account__c = activeAccount.Id,
            Contact__c = activeContact.Id,
            Plan__c = 'Basic',
            Start_Date__c = Date.today().addDays(-1),
            End_Date__c = Date.today().addYears(1),
            Price__c = 500.00
        );
        tsList.add(testTS1);
        Training_Subscription__c testTS2 = new Training_Subscription__c(
        	RecordTypeId = Schema.SObjectType.Training_Subscription__c.getRecordTypeInfosByName().get('Standard').getRecordTypeId(),
        	Account__c = inactiveAccount.Id,
            Contact__c = inactiveContact.Id,
            Plan__c = 'Basic',
            Start_Date__c = Date.today().addDays(-1),
            End_Date__c = Date.today().addYears(1),
            Price__c = 500.00
        );
        tsList.add(testTS2);
        insert(tsList);
        
        
        // Training Subscription Terms
        List<Training_Subscription_Term__c> tstList = new List<Training_Subscription_Term__c>();
        Training_Subscription_Term__c testTST1 = new Training_Subscription_Term__c(
            RecordTypeId = Schema.SObjectType.Training_Subscription_Term__c.getRecordTypeInfosByName().get('Monthly').getRecordTypeId(),
        	Account__c = activeAccount.Id,
            Contact__c = activeContact.Id,
            Start_Date__c = Date.today().addDays(-1),
            End_Date_Code__c = Date.today().addYears(1),
            Training_Subscription__c = testTS1.Id
        );
        tstList.add(testTST1);
        Training_Subscription_Term__c testTST2 = new Training_Subscription_Term__c(
            RecordTypeId = Schema.SObjectType.Training_Subscription_Term__c.getRecordTypeInfosByName().get('Monthly').getRecordTypeId(),
        	Account__c = activeAccount.Id,
            Contact__c = activeContact.Id,
            Start_Date__c = Date.today().addDays(-90),
            End_Date_Code__c = Date.today().addMonths(14),
            Training_Subscription__c = testTS1.Id
        );
        tstList.add(testTST2);
        Training_Subscription_Term__c testTST3 = new Training_Subscription_Term__c(
            RecordTypeId = Schema.SObjectType.Training_Subscription_Term__c.getRecordTypeInfosByName().get('Monthly').getRecordTypeId(),
        	Account__c = activeAccount.Id,
            Contact__c = activeContact.Id,
            Start_Date__c = Date.today().addDays(-120),
            End_Date_Code__c = Date.today().addMonths(18),
            Training_Subscription__c = testTS1.Id
        );
        tstList.add(testTST3);
        Training_Subscription_Term__c testTST4 = new Training_Subscription_Term__c(
            RecordTypeId = Schema.SObjectType.Training_Subscription_Term__c.getRecordTypeInfosByName().get('Monthly').getRecordTypeId(),
        	Account__c = inactiveAccount.Id,
            Contact__c = inactiveContact.Id,
            Start_Date__c = Date.today().addDays(-120),
            End_Date_Code__c = Date.today().addMonths(18),
            Training_Subscription__c = testTS2.Id
        );
        tstList.add(testTST4);
        insert(tstList);
        


        // TSAs
        List<Training_Subscription_Account__c> tsaList = new List<Training_Subscription_Account__c>();

		Training_Subscription_Account__c testTSA1 = new Training_Subscription_Account__c(
        	RecordTypeId = Schema.SObjectType.Training_Subscription_Account__c.getRecordTypeInfosByName().get('Standard').getRecordTypeId(),
        	Account__c = activeAccount.Id,
            Billing_Account__c = activeBillingAcct.Id,
            Contact__c = activeContact.Id,
            End_Date__c = Date.today().addYears(1),
            Training_Subscription__c = testTST1.Id
        );
        tsaList.add(testTSA1);

        Training_Subscription_Account__c testTSA2 = new Training_Subscription_Account__c(
        	RecordTypeId = Schema.SObjectType.Training_Subscription_Account__c.getRecordTypeInfosByName().get('Standard').getRecordTypeId(),
        	Account__c = activeAccount.Id,
            Billing_Account__c = activeBillingAcct.Id,
            Contact__c = activeContact.Id,
            End_Date__c = Date.today().addYears(1),
            Training_Subscription__c = testTST2.Id
        );
        tsaList.add(testTSA2);

        Training_Subscription_Account__c testTSA3 = new Training_Subscription_Account__c(
        	RecordTypeId = Schema.SObjectType.Training_Subscription_Account__c.getRecordTypeInfosByName().get('Standard').getRecordTypeId(),
        	Account__c = activeAccount.Id,
            Billing_Account__c = activeBillingAcct.Id,
            Contact__c = activeContact.Id,
            End_Date__c = Date.today().addYears(1),
            Training_Subscription__c = testTST3.Id
        );
        tsaList.add(testTSA3);
        Training_Subscription_Account__c testTSA4 = new Training_Subscription_Account__c(
        	RecordTypeId = Schema.SObjectType.Training_Subscription_Account__c.getRecordTypeInfosByName().get('Standard').getRecordTypeId(),
        	Account__c = inactiveAccount.Id,
            Billing_Account__c = inactiveBillingAcct.Id,
            Contact__c = inactiveContact.Id,
            End_Date__c = Date.today().addYears(1),
            Training_Subscription__c = testTST4.Id
        );
        tsaList.add(testTSA4);
        insert(tsaList);        
        
    }
    
    



    
    static testMethod void accountUpdatedToNCMITrue(){
        
        // When an account has active TSAs its NCMi checkbox should not be changed to FALSE when a TST expires.

        Account testAcct = [select id, name from Account where BillingStreet = '1 Auto Way' LIMIT 1];

        // Setup: update the TST to end today so the batch will process it.
        Training_Subscription_Term__c testTST = [select Id, Start_Date__c, End_Date_Code__c from Training_Subscription_Term__c where Account__c = :testAcct.Id LIMIT 1];
        testTST.End_Date_Code__c = Date.today();
        update(testTST);
        
		 
        // Execute: run the batch job now.
        Test.startTest();
        	Database.executeBatch(new UpdateNCMICodeBatch());
        Test.stopTest();
        
        
        // TEST: Did the batch update the NCMI_Client_Code field on the account?
        Account acctResult = [select Id, NCMI_Client_Code__c from Account where Id = :testAcct.Id]; // We only created one account in @testSetup so the query is simple.
        System.assertEquals(True, acctResult.NCMI_Client_Code__c, 'NCMI Client Code should remain True since there are other TSAs that are active.'); 
        
    }





    static testMethod void acctWithNoActiveTSAsIsSetToFalse_TEST(){
        
        // An account with NO active TSAs left will have its NCMi checkbox set to FALSE when a TST expires.

        Account testAcct = [select id, name from Account where BillingStreet = '2 Auto Way' LIMIT 1];

        // Setup: update the TST to end today so the batch will process it.
        List<Training_Subscription_Term__c> tstList = [select Id, Start_Date__c, End_Date_Code__c from Training_Subscription_Term__c where Account__c = :testAcct.Id];
        System.debug('The inactive account has ' + tstList.size() + ' TST records.');
        System.assertEquals(1, tstList.size());
        
        for(Training_Subscription_Term__c tst : tstList){
            tst.End_Date_Code__c = Date.today().addDays(-1);
        }
        update(tstList);
        
		 
        // Execute: run the batch job now.
        Test.startTest();
        	Database.executeBatch(new UpdateNCMICodeBatch());
        Test.stopTest();
        
        
        // TEST: Did the batch update the NCMI_Client_Code field on the account?
        Account acctResult = [select Id, NCMI_Client_Code__c from Account where Id = :testAcct.Id]; // We only created one account in @testSetup so the query is simple.
        System.assertEquals(False, acctResult.NCMI_Client_Code__c, 'NCMI Client Code should be FALSE since there are no TSAs that are active.'); 
        
    }



    
    
    // Helper methods.
    private static Account getTestAccount(){
        return [select Id, Name, NCMI_Client_Code__c from Account];
    }
    
    private static Training_Subscription_Account__c getTSA(){
        return [select Id, Account__c, Status_Formula__c, Term_Start_Date__c, Term_Termination_Date__c from Training_Subscription_Account__c];
    }
    
    private static Training_Subscription_Term__c getTST(){
        return [select Id, Start_Date__c, End_Date_Code__c from Training_Subscription_Term__c];
    }
}