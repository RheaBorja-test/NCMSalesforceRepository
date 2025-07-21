@isTest 
public with sharing class EngagementRosterPDFControllerTest {
    
    @TestSetup
    static void makeData(){
        String acctRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NCM Client').getRecordTypeId();
        String contactRecType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId();

        Account testAccount = new Account(
            RecordTypeId = acctRecType,
            Name = 'Sample Nissan of Metroville',
            BillingStreet = '1 Sample Way',
            BillingCity = 'Sampleville',
            BillingState = 'North Carolina',
            BillingPostalCode = '28461',
            BillingCountry = 'United States',
            Validated_Account_Name__c = 'Sample Nissan of Metroville',
            Accounting_Invoice_Name__c = 'Sample Nissan of Metroville, Inc',
            Legal_Entity_Name__c = 'Sample Nissan of Metroville, Inc',
            AccountSource = 'Marketing', // required
            Industry = 'Auto Retail New', // required
            Franchise_s__c = 'Nissan',
            NumberOfEmployees = 400,
            AnnualRevenue = 30000000.00
        );
        insert(testAccount);
       
        // Insert 20 Contacts
        List<Contact> newContacts = new List<Contact>();
        for(Integer i=0; i<20; i++){
            newContacts.add(
                new Contact(
                    RecordTypeId = contactRecType,
                    AccountId = testAccount.Id,
                    FirstName = 'Contact',
                    LastName = 'Number' + i,
                    Email = 'contact.number' + i + '@samplenisson.com',
                    MailingStreet = '100 Automotive Way',
                    MailingCity = 'Southport',
                    MailingState = 'North Carolina',
                    MailingPostalCode = '28461'
                )
            );
        }
        insert(newContacts);

        // Create a Billing Account for the customer.
        Billing_Account__c testBillingAccount = new Billing_Account__c(
            RecordTypeId = Schema.SObjectType.Billing_Account__c.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId(),    
            Account__c = testAccount.Id,
            Billing_Street__c = testAccount.BillingStreet,
            Billing_City__c = testAccount.BillingCity,
            Billing_State_Province__c = testAccount.BillingState,
            Billing_Zip_Postal_Code__c = testAccount.BillingPostalCode,
            Billing_Country__c = testAccount.BillingCountry,
            Primary_Contact__c = newContacts[0].Id,
            Status__c = 'Validated'
        );
        insert(testBillingAccount);



        /* NCM Account & Contacts */
        Account ncmAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NCM Management Group').getRecordTypeId(),
            Name = 'NCM Associates',
            Validated_Account_Name__c = 'NCM Associates',
            Accounting_Invoice_Name__c = 'NCM Associates',
            Legal_Entity_Name__c = 'NCM Associates',
            AccountSource = 'Marketing', // required
            Industry = 'Other', // required
            BillingStreet = '4717 Grand Ave., Ste 500',
            BillingCity = 'Kansas City',
            BillingState = 'Missouri',
            BillingPostalCode = '64112'
        );
        insert(ncmAccount);

        User ncmUser;
        String sbxName = UserInfo.getUserName().substringAfterLast('.').toUpperCase();
        String userName = 'bbillingsly@ncm.com.' + sbxName; // Set this so we use the same exact username for the query and creation.
        List<User> ncmUserResults = [SELECT Id, Name FROM User WHERE UserName = :userName LIMIT 1];
        Profile coordinatorProfile = [select id from profile where name = 'NCM Coordinator'];
        if( ncmUserResults.isEmpty() ){
            
            ncmUser = new user(
                ProfileID = coordinatorProfile.Id,
                Username = userName,
                FirstName = 'Barney',
                LastName = 'Billingsly',
                Initials__c = 'BXB',
                Email = 'mdemeglio@ncmassociates.com',
                Street = '4717 Grand Ave., Ste 500',
                City = 'Kansas City',
                State = 'Missouri',
                PostalCode = '64112',
                Alias = 'test456',
                CommunityNickname = 'test456',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'GMT',
                LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'UTF-8'
            );
            insert(ncmUser);
        } else {
            ncmUser = ncmUserResults[0];
        }


        /* NCM Contacts */
        List<Contact> ncmContacts = new List<Contact>();
        Contact ncmBillingContact = new Contact(
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('NCM Associates').getRecordTypeId(),
            AccountId = ncmAccount.Id,
            User_ID__c = ncmUser.Id,
            FirstName = 'Barney',
            Lastname = 'Billingsly',
            Email = 'barney.billingsly@ncmassociates.com',
            MailingStreet = '4717 Grand Ave., Ste 500',
            MailingCity = 'Kansas City',
            MailingState = 'Missouri',
            MailingPostalCode = '64112', 
            Nickname__c = 'Billings', 
            Title = 'Manager'          
        );
        ncmContacts.add(ncmBillingContact);
        insert(ncmContacts);



        // Create 20 Group
        String twentyGroupRecType = Schema.SObjectType.Twenty_Groups__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId();
        Twenty_Groups__c test20Group = new Twenty_Groups__c(
            RecordTypeId = twentyGroupRecType,
            Status__c = 'Active',
            Start_Date__c = Date.today().addMonths(-6),
            Name = '2001',
            Group_Name__c = '2001',
            Shipping_Not_Required__c = False,
            NCM_Proprietor__c = ncmBillingContact.Id, 
            NCM_Support_Staff__c = ncmBillingContact.Id
        );
        insert(test20Group);
        
        // 20 Group Member
        X20_Groups_Member__c test20GroupMember = new X20_Groups_Member__c(
            Group_ID__c = test20Group.Id,
            Account__c = testAccount.Id,
            Member_Number__c = 1,
            Billing_Account__c = testBillingAccount.Id,
            Financial_Data_Contact__c = newContacts[0].Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addYears(3),
            Type__c = 'Full Member',
            Status__c = 'Active'
        );
        insert(test20GroupMember);

        // Create 20 Group member Contacts
        List<X20_Group_Member_Contact__c> twentyGroupContacts = new List<X20_Group_Member_Contact__c>();
        for(Contact ct:newContacts){
            twentyGroupContacts.add(
                new X20_Group_Member_Contact__c(
                    X20_Group__c = test20Group.Id,
                    X20_Groups_Member__c = test20GroupMember.Id,
                    Contact__c = ct.Id,
                    Contact_Active_Date__c = Date.today(),
                    Contact_Status__c = 'Active',
                    Contact_Type__c = 'Member',
                    Member_Email__c = ct.Email
                )
            );
        }
        insert(twentyGroupContacts);

        // Engagement
        String retailEngagementRecType = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('Retail Solutions').getRecordTypeId();
        List<Engagement__c> newEngagements = new List<Engagement__c>();
        Engagement__c testEngagement1 = new Engagement__c(
            RecordTypeId = retailEngagementRecType,
            Name = 'Sample Engagement 1',
            X20_Group__c = test20Group.Id,
            Status__c = 'Tentative',
            Engagement_Type__c = '20 Group',
            Engagement_Description__c = 'Regular',
            Engagement_Owner__c = ncmBillingContact.Id,
            City__c = 'Dallas', // Updated Derrick May 07 - 1396 (Needed to cover VR's on Engagement)
            State_pl__c = 'TX', // Updated Derrick May 07 - 1396 (Needed to cover VR's on Engagement)
            Country_pl__c = 'United States' // Updated Derrick May 07 - 1396 (Needed to cover VR's on Engagement)
        );
        insert testEngagement1;
        
        List<Engagement_Attendee__c> eAList = new List<Engagement_Attendee__c>();
        for(Contact ct:newContacts) {
            eAList.add(
                new Engagement_Attendee__c(
                    Engagement__c = testEngagement1.Id,
                    Contact__c = ct.Id, 
                    Attendee_Type__c = 'Member',
                    In_Meeting_Room__c = true,
                    Age_Group__c = 'Adult',
                    Attendance_Status__c = 'Confirmed'
                )
            );
        }
        insert eAList;
        
        eAList[1].Age_Group__c = 'Teen';
        eAList[1].Attendee_Type__c = 'Guest';
        eAList[1].Associated_Attendee__c = eAList[0].Id;
        eAList[1].In_Meeting_Room__c = false;
        eAList[2].Age_Group__c = 'Teen';
        eAList[2].Attendee_Type__c = 'Guest';
        eAList[2].Associated_Attendee__c = eAList[0].Id;
        eAList[2].In_Meeting_Room__c = false;
        update new List<Engagement_Attendee__c>{eAList[1], eAList[2]};

        Engagement_Activity__c ea = new Engagement_Activity__c(
            Name = 'Test Activity',
            Engagement__c = testEngagement1.Id
        );
        insert ea;

        List<Activity_Participation__c> aPList = new List<Activity_Participation__c>();
        for(Engagement_Attendee__c eAtt: eAList) {
            aPList.add(
                new Activity_Participation__c(
                    Engagement_Attendee__c = eAtt.Id,
                    Engagement_Activity__c = ea.Id
                )
            );
        }
        insert aPList;
    }

    @isTest
    static void testPage() {
        Engagement__c eng = [SELECT Id FROM Engagement__c LIMIT 1];
        Pagereference testPage = Page.EngagementRosterPDF;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(eng.Id));
        
       ApexPages.StandardController sc = new  ApexPages.StandardController(eng);     
       EngagementRosterPDFController ext = new EngagementRosterPDFController(sc); 

       Assert.areEqual(12, ext.fontSize);
    }
}