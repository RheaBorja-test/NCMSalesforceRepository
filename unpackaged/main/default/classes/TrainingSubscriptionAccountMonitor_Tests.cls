@isTest 
public class TrainingSubscriptionAccountMonitor_Tests {
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
            Start_Date__c = Date.today(),
            End_Date_Code__c = Date.today().addYears(1),
            Training_Subscription__c = testTS1.Id
        );
        insert(testTST1);
        // Training_Subscription_Term__c testTST2 = new Training_Subscription_Term__c(
        //     RecordTypeId = Schema.SObjectType.Training_Subscription_Term__c.getRecordTypeInfosByName().get('Monthly').getRecordTypeId(),
        // 	Account__c = activeAccount.Id,
        //     Contact__c = activeContact.Id,
        //     Start_Date__c = Date.today().addDays(-90),
        //     End_Date_Code__c = Date.today(),
        //     Training_Subscription__c = testTS1.Id
        // );
        // tstList.add(testTST2);
        
        // insert(tstList);
        


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

        // Training_Subscription_Account__c testTSA2 = new Training_Subscription_Account__c(
        // 	RecordTypeId = Schema.SObjectType.Training_Subscription_Account__c.getRecordTypeInfosByName().get('Standard').getRecordTypeId(),
        // 	Account__c = activeAccount.Id,
        //     Billing_Account__c = activeBillingAcct.Id,
        //     Contact__c = activeContact.Id,
        //     End_Date__c = Date.today().addYears(1),
        //     Training_Subscription__c = testTST2.Id
        // );
        // tsaList.add(testTSA2);

        // Training_Subscription_Account__c testTSA3 = new Training_Subscription_Account__c(
        // 	RecordTypeId = Schema.SObjectType.Training_Subscription_Account__c.getRecordTypeInfosByName().get('Standard').getRecordTypeId(),
        // 	Account__c = activeAccount.Id,
        //     Billing_Account__c = activeBillingAcct.Id,
        //     Contact__c = activeContact.Id,
        //     End_Date__c = Date.today().addYears(1),
        //     Training_Subscription__c = testTST3.Id
        // );
        // tsaList.add(testTSA3);
        
        // insert(tsaList);        
        
    }


    @isTest
    private static void tsaIsStartingTest(){
        
        Test.startTest();
            Database.executeBatch(new TrainingSubscriptionAccountMonitorBatch());
        Test.stopTest();

        Account acctResult = [select ncmi_client_code__c from account];
        Assert.areEqual(true, acctResult.NCMI_Client_Code__c,'NCMI Client Code should be true since the TST starts today.');   

    }
    
    
    @isTest
    private static void tsaIsEndingTest(){
        
        Account testAcct = [select id, ncmi_client_code__c from account];
        testAcct.NCMI_Client_Code__c = true;
        update(testAcct);
        
        Training_Subscription_Term__c tst = [select id from Training_Subscription_Term__c];
        tst.Start_Date__c = Date.today().addYears(-1);
        tst.End_Date_Code__c = Date.today();
        update(tst);
        
        Test.startTest();
            Database.executeBatch(new TrainingSubscriptionAccountMonitorBatch());
        Test.stopTest();

        Account acctResult = [select ncmi_client_code__c from account];
        Assert.areEqual(false, acctResult.NCMI_Client_Code__c,'NCMI Client Code should be true since the TST starts today.');   

    }
}