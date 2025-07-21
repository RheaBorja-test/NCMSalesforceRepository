@isTest
public class CZ_LoadCustomerBatch_Test {
    
    @TestSetup
    static void makeData(){

        String acctRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NCM Client').getRecordTypeId();
        Account parentAccount = new Account(
            RecordTypeId = acctRecType,
            Name = 'Sample Auto Group',
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
            Franchise_s__c = 'Chevrolet;Dodge;Ford;Jeep',
            NumberOfEmployees = 400,
            AnnualRevenue = 30000000.00,
            c2g__codaAccountTradingCurrency__c = 'USD'
        );
        insert(parentAccount);
    

        // Contacts
        String contactRecType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId();
        
        Contact sampleContact1 = new Contact(
            RecordTypeId = contactRecType,
            FirstName = 'Marv',
            LastName = 'Sampleton',
            Title = 'CEO',
            NCM_Department__c = 'Executive',
            NCM_Title__c = 'Owner',
            AccountId = parentAccount.Id,
            Email = 'marv.sampleton@ncmassociates.com',
            MailingStreet = '100 Automotive Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        insert sampleContact1;

        Billing_Account__c ba = [SELECT Id, Name, Primary_Contact__c, CZ_CustomerId__c FROM Billing_Account__c WHERE RecordType.Name = 'Billing Account' LIMIT 1];
        ba.Primary_Contact__c = sampleContact1.Id;
        update ba;
    }


    @IsTest
    static void batchTest1(){      
        
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());
        
        Test.startTest();
        CZ_LoadCustomerBatch lcb = new CZ_LoadCustomerBatch();
        Database.executeBatch(lcb);
        Test.stopTest();
        
        Billing_Account__c ba2 = [SELECT Id, Name, Primary_Contact__c, CZ_CustomerId__c FROM Billing_Account__c WHERE RecordType.Name = 'Billing Account' LIMIT 1];
        Assert.areEqual('CUS-1234', ba2.CZ_CustomerId__c);
    }

    @IsTest
    static void batchTest2(){      
        
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());
        Billing_Account__c ba = [SELECT Id, Name, Primary_Contact__c, CZ_CustomerId__c FROM Billing_Account__c WHERE RecordType.Name = 'Billing Account' LIMIT 1];
        
        Test.startTest();
        CZ_LoadCustomerBatch lcb = new CZ_LoadCustomerBatch(ba.Id);
        lcb.activateNewCustomers = true;
        Database.executeBatch(lcb);
        Test.stopTest();
        
        Billing_Account__c ba2 = [SELECT Id, Name, Primary_Contact__c, CZ_CustomerId__c FROM Billing_Account__c WHERE RecordType.Name = 'Billing Account' LIMIT 1];
        Assert.areEqual('CUS-1234', ba2.CZ_CustomerId__c);
    }

    @IsTest
    static void batchTest3(){      
        
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());
        List<Id> baList = new List<Id>();
        for(Billing_Account__c ba : [SELECT Id FROM Billing_Account__c WHERE RecordType.Name = 'Billing Account']) {
            baList.add(ba.Id);
        }
        
        Test.startTest();
        CZ_LoadCustomerBatch lcb = new CZ_LoadCustomerBatch(baList);
        Database.executeBatch(lcb);
        Test.stopTest();
        
        Billing_Account__c ba2 = [SELECT Id, Name, Primary_Contact__c, CZ_CustomerId__c FROM Billing_Account__c WHERE RecordType.Name = 'Billing Account' LIMIT 1];
        Assert.areEqual('CUS-1234', ba2.CZ_CustomerId__c);
    }
}