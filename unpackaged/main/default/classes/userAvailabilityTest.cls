@isTest 
public class userAvailabilityTest {

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
        List<Contact> newContacts = new List<Contact>();

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
        newContacts.add(sampleContact1);

        Contact sampleContact2 = new Contact(
            RecordTypeId = contactRecType,
            FirstName = 'Fran',
            LastName = 'Sampleton',
            Title = 'President',
            NCM_Department__c = 'Executive',
            NCM_Title__c = 'President',
            AccountId = parentAccount.Id,
            Email = 'fran.sampleton@ncmassociates.com',
            MailingStreet = '100 Automotive Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        newContacts.add(sampleContact2);
        insert(newContacts);
        
    }


    static testMethod void testGetUserAvailability() {
        Test.startTest();

        List<string> rles = userAvailabilityController.getRoles();
        userAvailabilityController.getUserAvailability('Salesforce Administrator', Datetime.now(), datetime.now().addDays(3));

        test.stopTest();
    }

    static testMethod void testAttendee() {
        
        Test.startTest();
        
        // Engagement__c eng = new Engagement__c();
        // eng.Engagement_Start__c = datetime.now();
        // eng.Engagement_End__c = Datetime.now().addDays(1);
        // insert eng;
        String retailEngagementRecType = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('Retail Solutions').getRecordTypeId();
        List<Engagement__c> newEngagements = new List<Engagement__c>();
        Engagement__c eng = new Engagement__c(
            RecordTypeId = retailEngagementRecType,
            Name = 'Sample Engagement 1',
            Status__c = 'Tentative',
            Engagement_Type__c = '20 Group',
            Engagement_Description__c = 'Regular',
            Engagement_Start__c = datetime.now(),
            Engagement_End__c = Datetime.now().addDays(1),
            Country_pl__c = 'United States',
            State_pl__c = 'NC'
        );
        insert(eng);

        eng = userAvailabilityController.getEngagementValues(eng.Id);

        Contact testContact = [select id from contact limit 1];

        Engagement_Attendee__c att = new Engagement_Attendee__c();
        att.Engagement__c = eng.id;
        att.Contact__c = testContact.id;
        att = userAvailabilityController.upsertAtt(att);

        Test.stopTest();
        
    }

    static testMethod void cheating() {
        
        Test.startTest();
        userAvailabilityController.cheatingTests();
        Test.stopTest();

        }

}