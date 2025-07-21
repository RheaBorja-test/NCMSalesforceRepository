//@isTest
public class SampleDataFactory {

    public static Engagement__c createEngagement_20G(Id twentyGroupId, Id engagementRecTypeId, Id ncmBillingContactId){
        
        // Create a Dim4 record for the Engagement
        c2g__codaDimension4__c testDim4 = new c2g__codaDimension4__c(
            Name = 'Sample Dim4',
            c2g__ReportingCode__c = '444',
            c2g__PostingAllowed__c = 'All Dates'
        );
        insert(testDim4);
        
        // Create the engagement
        Engagement__c testEngagement = new Engagement__c(
            X20_Group__c = twentyGroupId,
            RecordTypeId = engagementRecTypeId,
            Engagement_Owner__c = ncmBillingContactId,
            Name = 'Sample Engagement',
            Status__c = 'Tentative',
            Engagement_Type__c = '20 Group',
            Engagement_Description__c = 'Regular', 
            City__c = 'Dallas',
            State_pl__c = 'TX', 
            Country_pl__c = 'United States',
            Dimension_4__c = testDim4.Id,
            Engagement_Start__c = DateTime.now().addDays(10),
            Engagement_End__c = DateTime.now().addDays(13)
        );
        insert(testEngagement);
        

        // Add Attendees to the Engagement..
        List<Engagement_Attendee__c> newAttendees = new List<Engagement_Attendee__c>();
        for(Contact ct:[SELECT Id, Name, AccountId FROM Contact]){
            Engagement_Attendee__c att = new Engagement_Attendee__c(
                Contact__c = ct.id,
                Account__c = ct.AccountId,
                Name = ct.Name,
                Engagement__c = testEngagement.Id,
                Arrival__c = Datetime.now().addDays(30),
                Departure__c = Datetime.now().addDays(34),
                Attendance_Status__c = 'Confirmed',
                Attendee_Type__c = 'Member',
                Attendee_Notes__c = 'Test'
            );
            newAttendees.add(att);
        }
        insert(newAttendees);

        return testEngagement;
    }
        
    
    
    
    public static void create20GroupAccountData(){

        Account testAccount = new Account(
            Name = 'Metroville Dodge', 
            BillingStreet = '111 Main St', 
            BillingCity = 'Metroville', 
            BillingStateCode = 'NC', 
            BillingPostalCode = '27554'
        );
        insert(testAccount);

        // Insert 3 contacts
        List<Contact> testContacts = new List<Contact>();
        String contactRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId();
        for(Integer i=0;i<3;i++){
            Contact newContact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact' + i,
                Email = 'test.contact'+i+'@noemail.com',
                AccountId = testAccount.Id,
                RecordTypeId = contactRecTypeId,
                MailingStreet = '4717 Grand Ave., Ste 500',
                MailingCity = 'Kansas City',
                MailingState = 'Missouri',
                MailingPostalCode = '64112'
            );
            testContacts.add(newContact);
        }
        insert(testContacts);

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
            MailingPostalCode = '64112'
        );
        insert(ncmBillingContact);
        
        
        // Added: Derrick 3.27.2024
        String twentyGroupRecType = Schema.SObjectType.Twenty_Groups__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId();
        Twenty_Groups__c test20Group = new Twenty_Groups__c(
            RecordTypeId = twentyGroupRecType,
            Status__c = 'Active',
            Start_Date__c = Date.today().addMonths(-6),
            Name = '2001',
            Group_Name__c = '2001',
            Moderator__c = ncmBillingContact.User_Id__c,
            NCM_Proprietor__c = ncmBillingContact.Id, //twentyGroupOwnerContact.Id,
            NCM_Support_Staff__c = ncmBillingContact.Id //supportStaffContact.Id,
        );
        insert(test20Group);


        // 20 Group Member
        X20_Groups_Member__c sample20GroupMember = new X20_Groups_Member__c(
            Group_ID__c = test20Group.Id,
            Account__c = testAccount.Id,
            Member_Number__c = 1,
            //Billing_Account__c = parentBillingAccount.Id,
            //Financial_Data_Contact__c = sampleContact2.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addYears(3),
            Type__c = 'Full Member',
            Status__c = 'Active'
        );
        insert(sample20GroupMember);

        System.debug('SampleDataFactory.sample20GroupMember is complete.');

        
        // Create a 20 Group Member Contact for each of the Contacts we created up above.
        List<X20_Group_Member_Contact__c> twentyGroupContacts = new List<X20_Group_Member_Contact__c>();
        
        for(Contact ct:testContacts){
            
            X20_Group_Member_Contact__c grpContact = new X20_Group_Member_Contact__c(
                X20_Group__c = test20Group.Id,
                X20_Groups_Member__c = sample20GroupMember.Id,
                Contact__c = ct.Id,
                Member_Email__c = ct.Email,
                Contact_Active_Date__c = Date.today(),
                Contact_Status__c = 'Active',
                Contact_Type__c = 'Member'
            );
            
            twentyGroupContacts.add(grpContact);
        }
        insert(twentyGroupContacts);
    }
    


    public static void createPropAnd20GroupData(){

        final String logTag = '[createPropAnd20GroupData]';

        Account testAccount = new Account(
            Name = 'Metroville Dodge', 
            BillingStreet = '111 Main St', 
            BillingCity = 'Metroville', 
            BillingStateCode = 'NC', 
            BillingPostalCode = '27554'
        );
        insert(testAccount);

        // Insert 3 contacts
        List<Contact> testContacts = new List<Contact>();
        String contactRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId();
        for(Integer i=0;i<3;i++){
            Contact newContact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact' + i,
                Email = 'test.contact'+i+'@noemail.com',
                AccountId = testAccount.Id,
                RecordTypeId = contactRecTypeId,
                MailingStreet = '4717 Grand Ave., Ste 500',
                MailingCity = 'Kansas City',
                MailingState = 'Missouri',
                MailingPostalCode = '64112'
            );
            testContacts.add(newContact);
        }
        insert(testContacts);

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
            MailingPostalCode = '64112'
        );
        insert(ncmBillingContact);

        String twentyGroupRecType = Schema.SObjectType.Twenty_Groups__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId();
        Twenty_Groups__c test20Group = new Twenty_Groups__c(
            RecordTypeId = twentyGroupRecType,
            Status__c = 'Active',
            Start_Date__c = Date.today().addMonths(-6),
            Name = '2001',
            Group_Name__c = '2001',
            Moderator__c = ncmBillingContact.User_Id__c,
            NCM_Proprietor__c = ncmBillingContact.Id, //twentyGroupOwnerContact.Id,
            NCM_Support_Staff__c = ncmBillingContact.Id //supportStaffContact.Id,
        );
        insert(test20Group);


        // 20 Group Member
        X20_Groups_Member__c sample20GroupMember = new X20_Groups_Member__c(
            Group_ID__c = test20Group.Id,
            Account__c = testAccount.Id,
            Member_Number__c = 1,
            //Billing_Account__c = parentBillingAccount.Id,
            //Financial_Data_Contact__c = sampleContact2.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addYears(3),
            Type__c = 'Full Member',
            Status__c = 'Active'
        );
        insert(sample20GroupMember);

        /* Proprietary Groups */
        Proprietary_Group__c propGroup1 = new Proprietary_Group__c(
            RecordTypeId = Schema.SObjectType.Proprietary_Group__c.getRecordTypeInfosByName().get('Quarterly').getRecordTypeId(),
            Name = 'Central Auto Group - Proprietary Group',
            Group_Name__c = 'Central Auto Group - Proprietary Group',
            Group_Number__c = '8888',
            Group_Owner__c = ncmBillingContact.Id,
            Meetings_per_Year__c = 4,
            Account__c = testAccount.Id,
            Billing_Frequency__c = 'Quarterly',
            Contact__c = testContacts[0].Id,
            Street__c = testAccount.BillingStreet,
            City__c = testAccount.BillingCity,
            State__c = testAccount.BillingState,
            Postal_Code__c = testAccount.BillingPostalCode,
            Rate_Type__c = 'Monthly Rate Schedule'
        );
        insert(propGroup1);
        System.debug(logTag + 'Inserted 1 Proprietary Group: ' + propGroup1.Name);


        /**** Proprietary Accounts ****/
       
        Proprietary_Account__c propAcct = new Proprietary_Account__c(
            Proprietary_Group__c = propGroup1.Id,
            Account__c = testAccount.Id,
            Member_Number__c = '10',
            Shipping_Address__c = testAccount.BillingStreet,
            Shipping_City__c = testAccount.BillingCity,
            Shipping_State__c = testAccount.BillingState,
            Shipping_Postal_Code__c = testAccount.BillingPostalCode,
            Shipping_Country__c = testAccount.BillingCountry,
            Billing_Account__c = testAccount.Primary_Billing_Account__c,
            Contact__c =  testContacts[0].Id, //sampleContact1.Id,
            Financial_Statement_Contact__c = testContacts[1].Id, //sampleContact2.Id,
            Start_Date__c = Date.today(),
            Type__c = 'Full Member',
            Status__c = 'Active'
        );
        insert(propAcct);
        
        /**** Proprietary Account Contacts ****/
        List<Proprietary_Account_Contact__c> propAcctContacts = new List<Proprietary_Account_Contact__c>();
        
        for(Contact c : testContacts){
            propAcctContacts.add(
                new Proprietary_Account_Contact__c(
                    RecordTypeId = Schema.SObjectType.Proprietary_Account_Contact__c.getRecordTypeInfosByName().get('Proprietary Contact').getRecordTypeId(),
                    Proprietary_Account__c = propAcct.Id,
                    Contact__c = c.Id,
                    Contact_Type__c = 'Member',
                    Department_NCM_Classification__c = 'Administrative',
                    Member_Email__c = c.Email,
                    Name = c.FirstName + ' ' + c.LastName,
                    Proprietary_Group__c = propGroup1.Id,
                    Status__c = 'Active'
                )
            );
        }
        insert(propAcctContacts);
        
    }




    public static void createPropGroupData(){
        
        String logTag = '[createPropGroupData]';
        Map<String,Account> accountMap = new Map<String,Account>();
        Map<String, List<Contact>> contactMap = new Map<String, List<Contact>>();
        List<Contact> customerContacts = new List<Contact>();
        String acctRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NCM Client').getRecordTypeId();
        String contactRecType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId();


        
        Account parentAccount = new Account(
            RecordTypeId = acctRecType,
            Name = 'Central Auto Group',
            BillingStreet = '1 Auto Way',
            BillingCity = 'Sampleton',
            BillingState = 'North Carolina',
            BillingPostalCode = '28461',
            BillingCountry = 'United States',
            Validated_Account_Name__c = 'Central Auto Group',
            Accounting_Invoice_Name__c = 'Central Auto Group, Inc',
            Legal_Entity_Name__c = 'Central Auto Group, Inc',
            AccountSource = 'Marketing', // required
            Industry = 'Auto Retail New', // required
            Franchise_s__c = 'Chevrolet;Dodge;Ford;Jeep',
            NumberOfEmployees = 400,
            AnnualRevenue = 30000000.00
        );
        insert(parentAccount);
        System.debug(logTag + 'Inserted sample parent account.');
        accountMap.put('Dealer Parent', parentAccount);

        // Contacts
        List<Contact> newContacts = new List<Contact>();
        Contact sampleContact1 = new Contact(
            RecordTypeId = contactRecType,
            FirstName = 'Rex',
            LastName = 'Bingleton',
            Title = 'CEO',
            NCM_Department__c = 'Executive',
            NCM_Title__c = 'Owner',
            AccountId = parentAccount.Id,
            Email = 'rex@centralautogroup.com',
            MailingStreet = '100 Automotive Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        newContacts.add(sampleContact1);

        Contact sampleContact2 = new Contact(
            RecordTypeId = contactRecType,
            FirstName = 'Terresa',
            LastName = 'Lesterman',
            Title = 'President',
            NCM_Department__c = 'Executive',
            NCM_Title__c = 'President',
            AccountId = parentAccount.Id,
            Email = 'tlesternam@sampleauto.com',
            MailingStreet = '100 Automotive Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        newContacts.add(sampleContact2);

        Contact sampleContact3 = new Contact(
            RecordTypeId = contactRecType,
            FirstName = 'Max',
            LastName = 'Knucklebuster',
            Title = 'Parts and Service Manager',
            NCM_Department__c = 'Customer Service',
            NCM_Title__c = 'Manager',
            AccountId = parentAccount.Id,
            Email = 'max@sampleauto.com',
            MailingStreet = '100 Automotive Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        newContacts.add(sampleContact3);
        insert(newContacts);
        contactMap.put('Dealer Parent', newContacts);
        System.debug(logTag + 'Inserted sample parent contacts');
        customerContacts.addAll(newContacts);

        Billing_Account__c parentBillingAccount = new Billing_Account__c(
            Account__c = parentAccount.Id,
            Billing_Street__c = parentAccount.BillingStreet,
            Billing_City__c = parentAccount.BillingCity,
            Billing_State_Province__c = parentAccount.BillingState,
            Billing_Zip_Postal_Code__c = parentAccount.BillingPostalCode,
            Billing_Country__c = parentAccount.BillingCountry,
            Primary_Contact__c = sampleContact2.Id,
            Status__c = 'Validated'
        );
        insert(parentBillingAccount);

        // Add the Primary Billing Account (Finance Account) to the parent account.
        parentAccount.Primary_Billing_Account__c = parentBillingAccount.Id;
        update(parentAccount);

        /// Child Account 1
        Account fordAcct = new Account(
            RecordTypeId = acctRecType,
            ParentId = parentAccount.Id,
            Name = 'Central Ford',
            BillingStreet = '1 Ford Way',
            BillingCity = 'Sampleton',
            BillingState = 'North Carolina',
            BillingPostalCode = '28461',
            Validated_Account_Name__c = 'Central Ford',
            Accounting_Invoice_Name__c = 'Central Ford, Inc',
            Legal_Entity_Name__c = 'Central Ford, Inc',
            AccountSource = 'Marketing', // required
            Industry = 'Auto Retail New', // required
            Franchise_s__c = 'Ford',
            NumberOfEmployees = 100,
            AnnualRevenue = 5000000.00
        );
        insert(fordAcct);
        accountMap.put('Ford Account', fordAcct);
        System.debug(logTag + 'Inserted Ford child account.');

        // Contacts
        newContacts = new List<Contact>();
        Contact sampleContact4 = new Contact(
            RecordTypeId = contactRecType,
            AccountId = fordAcct.Id,
            FirstName = 'Glen',
            LastName = 'Silverton',
            Title = 'CEO',
            NCM_Department__c = 'Executive',
            NCM_Title__c = 'Owner',
            Email = 'glen@centralford.com',
            MailingStreet = '1 Ford Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        newContacts.add(sampleContact4);

        Contact sampleContact5 = new Contact(
            RecordTypeId = contactRecType,
            AccountId = fordAcct.Id,
            FirstName = 'Nadine',
            LastName = 'Livermore',
            Title = 'President',
            NCM_Department__c = 'Executive',
            NCM_Title__c = 'President',
            Email = 'nlivermore@centralford.com',
            MailingStreet = '1 Ford Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        newContacts.add(sampleContact5);

        Contact sampleContact6 = new Contact(
            RecordTypeId = contactRecType,
            AccountId = fordAcct.Id,
            FirstName = 'Peter',
            LastName = 'Olecroft',
            Title = 'Parts and Service Manager',
            NCM_Department__c = 'Customer Service',
            NCM_Title__c = 'Manager',
            Email = 'pete@centralford.com',
            MailingStreet = '1 Ford Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        newContacts.add(sampleContact6);
        insert(newContacts);
        contactMap.put('Ford Dealer', newContacts);
        System.debug(logTag + 'Inserted Ford contacts.');
        customerContacts.addAll(newContacts);

        /// Child Account 2
        Account jeepAcct = new Account(
            RecordTypeId = acctRecType,
            ParentId = parentAccount.Id,
            Name = 'Central Toyota',
            BillingStreet = '1 Central Way',
            BillingCity = 'Sampleton',
            BillingState = 'North Carolina',
            BillingPostalCode = '28461',
            Validated_Account_Name__c = 'Central Toyota',
            Accounting_Invoice_Name__c = 'Central Toyota, Inc',
            Legal_Entity_Name__c = 'Central Toyota, Inc',
            AccountSource = 'Marketing', // required
            Industry = 'Auto Retail New', // required
            Franchise_s__c = 'Toyota',
            NumberOfEmployees = 125,
            AnnualRevenue = 12000000.00
        );
        insert(jeepAcct);
        accountMap.put('Toyota Account',jeepAcct);
        System.debug(logTag + 'Inserted Toyota child account.');

        // Contacts
        newContacts = new List<Contact>();
        newContacts.add(
            new Contact(
                RecordTypeId = contactRecType,
                AccountId = jeepAcct.Id,
                FirstName = 'Hank',
                LastName = 'Henderson',
                Title = 'CEO',
                NCM_Department__c = 'Executive',
                NCM_Title__c = 'Owner',
                Email = 'hhenderson@centraltoyota.com',
                MailingStreet = '1 Central Way',
                MailingCity = 'Southport',
                MailingState = 'North Carolina',
                MailingPostalCode = '28461'
            )
        );
        newContacts.add(
            new Contact(
                RecordTypeId = contactRecType,
                AccountId = jeepAcct.Id,
                FirstName = 'Harriet',
                LastName = 'Henderson',
                Title = 'President',
                NCM_Department__c = 'Executive',
                NCM_Title__c = 'President',
                Email = 'hh@samplejdc.com',
                MailingStreet = '1 Jeep Way',
                MailingCity = 'Southport',
                MailingState = 'North Carolina',
                MailingPostalCode = '28461'
            )
        );

        newContacts.add(
            new Contact(
                RecordTypeId = contactRecType,
                AccountId = jeepAcct.Id,
                FirstName = 'Haney',
                LastName = 'Henderson',
                Title = 'Parts and Service Manager',
                NCM_Department__c = 'Customer Service',
                NCM_Title__c = 'Manager',
                Email = 'haney.henderson@samplejdc.com',
                MailingStreet = '1 Jeep Way',
                MailingCity = 'Southport',
                MailingState = 'North Carolina',
                MailingPostalCode = '28461'
            )
        );
        insert(newContacts);
        contactMap.put('Jeep Account', newContacts);
        customerContacts.addAll(newContacts);


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
        accountMap.put('NCM Account', ncmAccount);
        System.debug(logTag + 'Inserted NCM account.');

        
        User ncmUser;
        String userName = 'ncmUnitTestUser123@ncm.com'; // Set this so we use the same exact username for the query and creation.
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
                Alias = 'bbills',
                CommunityNickname = 'barney123',
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
            MailingPostalCode = '64112'
        );
        ncmContacts.add(ncmBillingContact);
        insert(ncmContacts);
        contactMap.put('NCM Account', new List<Contact>{ncmBillingContact});
        System.debug(logTag + 'Inserted ' + ncmContacts.size() + ' NCM contacts');

        
        /* NCM Billing Account */
        Billing_Account__c ncmBillingAcct = new Billing_Account__c(
            Name = 'NCM Billing Account',
            Account__c = ncmAccount.Id,
            Primary_Contact__c = ncmBillingContact.Id
        );
        insert(ncmBillingAcct);
        System.debug(logTag + 'Inserted NCM billing account');
        

        // Get the User ID from the newly created ncmBillingContact contact
        Contact billingContact = [select Id, Name, User_Id__c from Contact where Email = :ncmBillingContact.Email LIMIT 1];
        System.debug(logTag + 'Billing Contact user Id: ' + billingContact.User_Id__c);

     


        /* Proprietary Groups */
        Proprietary_Group__c propGroup1 = new Proprietary_Group__c(
            RecordTypeId = Schema.SObjectType.Proprietary_Group__c.getRecordTypeInfosByName().get('Quarterly').getRecordTypeId(),
            Name = 'Central Auto Group - Proprietary Group',
            Group_Name__c = 'Central Auto Group - Proprietary Group',
            Group_Number__c = '8888',
            Group_Owner__c = billingContact.Id,
            Meetings_per_Year__c = 4,
            Account__c = parentAccount.Id,
            Billing_Account__c = parentBillingAccount.Id,
            Billing_Frequency__c = 'Quarterly',
            Contact__c = sampleContact1.Id,
            Street__c = parentAccount.BillingStreet,
            City__c = parentAccount.BillingCity,
            State__c = parentAccount.BillingState,
            Postal_Code__c = parentAccount.BillingPostalCode,
            Rate_Type__c = 'Monthly Rate Schedule'
        );
        insert(propGroup1);
        System.debug(logTag + 'Inserted 1 Proprietary Group: ' + propGroup1.Name);


        /**** Proprietary Accounts ****/
       
        List<Proprietary_Account__c> propAccts = new List<Proprietary_Account__c>();
        for(Account acct : [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Primary_Billing_Account__c, (select id, name from Contacts) from Account where RecordTypeId = :acctRecType]){
            List<Contact> acctContacts = acct.Contacts;
            
            propAccts.add(
                new Proprietary_Account__c(
                    Proprietary_Group__c = propGroup1.Id,
                    Account__c = acct.Id,
                    Member_Number__c = '10',
                    Shipping_Address__c = acct.BillingStreet,
                    Shipping_City__c = acct.BillingCity,
                    Shipping_State__c = acct.BillingState,
                    Shipping_Postal_Code__c = acct.BillingPostalCode,
                    Shipping_Country__c = acct.BillingCountry,
                    Billing_Account__c = acct.Primary_Billing_Account__c,
                    Contact__c =  acctContacts[0].Id, //sampleContact1.Id,
                    Financial_Statement_Contact__c = acctContacts[0].Id, //sampleContact2.Id,
                    Start_Date__c = Date.today(),
                    Type__c = 'Full Member',
                    Status__c = 'Active'
                )
            );
        }
        insert(propAccts);
        System.debug(logTag + 'Inserted ' + propAccts.size() + ' Proprietary Accounts.');
        
        Map<Id, Proprietary_Account__c> propAcctMap = new Map<Id, Proprietary_Account__c>();
        for(Proprietary_Account__c pa : propAccts){
            propAcctMap.put(pa.Account__c, pa);
        }

        /**** Proprietary Account Contacts ****/
        List<Proprietary_Account_Contact__c> propAcctContacts = new List<Proprietary_Account_Contact__c>();
        
        for(Contact c : customerContacts){
            propAcctContacts.add(
                new Proprietary_Account_Contact__c(
                    RecordTypeId = Schema.SObjectType.Proprietary_Account_Contact__c.getRecordTypeInfosByName().get('Proprietary Contact').getRecordTypeId(),
                    Proprietary_Account__c = propAcctMap.get(c.AccountId).Id,
                    Contact__c = c.Id,
                    Contact_Type__c = 'Member',
                    Department_NCM_Classification__c = 'Administrative',
                    Member_Email__c = c.Email,
                    Name = c.FirstName + ' ' + c.LastName,
                    Proprietary_Group__c = propGroup1.Id,
                    Status__c = 'Active'
                )
            );
        }
        insert(propAcctContacts);
        
    }
    

    
    public static Engagement__c createEngagement_Prop(Id propGroupId, Id engagementRecTypeId, Id ncmBillingContactId){
        
        Engagement__c testEngagement = new Engagement__c(
            Proprietary_Group__c  = propGroupId,
            RecordTypeId = engagementRecTypeId,
            Engagement_Owner__c = ncmBillingContactId,
            Name = 'Sample Proprietary Engagement',
            Status__c = 'Tentative',
            Engagement_Type__c = 'Special Meeting (Dealer)',
           // Engagement_Description__c = 'Regular' // Changed By Derrick 3.26.2024 This field does not exist for Prop Group 
            City__c = 'Dallas', // Updated Derrick May 07 - 1396 (Needed to cover VR's on Engagement)
            State_pl__c = 'TX', // Updated Derrick May 07 - 1396 (Needed to cover VR's on Engagement)
            Country_pl__c = 'United States' // Updated Derrick May 07 - 1396 (Needed to cover VR's on Engagement)
        );
        insert(testEngagement);
        

        // Add Attendees to the Engagement..
        List<Engagement_Attendee__c> newAttendees = new List<Engagement_Attendee__c>();
        
        for(Contact ct:[SELECT Id, Name, AccountId FROM Contact]){
            Engagement_Attendee__c att = new Engagement_Attendee__c(
                Contact__c = ct.id,
                Account__c = ct.AccountId,
                Name = ct.Name,
                Engagement__c = testEngagement.Id,
                Arrival__c = Datetime.now().addDays(30),
                Departure__c = Datetime.now().addDays(34),
                Attendance_Status__c = 'Confirmed',
                Attendee_Type__c = 'Member',
                Attendee_Notes__c = 'Test' 
            );
            newAttendees.add(att);
        }
        insert(newAttendees);

        return testEngagement;
    }
    
    
    public static Map<String, List<Sobject>> createData(){
        
        final String logTag = '[SampleDataFactory]';

        Map<String, List<Sobject>> testData = new Map<String, List<Sobject>>();
        
        Map<String,Account> accountMap = new Map<String,Account>();
        Map<String, List<Contact>> contactMap = new Map<String, List<Contact>>();
        List<Contact> customerContacts = new List<Contact>();
        String acctRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NCM Client').getRecordTypeId();
        String contactRecType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId();


        
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
            AnnualRevenue = 30000000.00
        );
        insert(parentAccount);
        System.debug(logTag + 'Inserted sample parent account.');
        accountMap.put('Dealer Parent', parentAccount);



        // Contacts
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

        Contact sampleContact3 = new Contact(
            RecordTypeId = contactRecType,
            FirstName = 'Louis',
            LastName = 'Sampleton',
            Title = 'Parts and Service Manager',
            NCM_Department__c = 'Customer Service',
            NCM_Title__c = 'Manager',
            AccountId = parentAccount.Id,
            Email = 'lou.sampleton@ncmassociates.com',
            MailingStreet = '100 Automotive Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        newContacts.add(sampleContact3);
        insert(newContacts);
        contactMap.put('Dealer Parent', newContacts);
        System.debug(logTag + 'Inserted sample parent contacts');
        customerContacts.addAll(newContacts);


        // Billing / Payable Accounts
        List<Billing_Account__c> billpayAccountList = new List<Billing_Account__c>();
        Billing_Account__c parentBillingAccount = new Billing_Account__c(
            RecordTypeId = Schema.SObjectType.Billing_Account__c.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId(),    
            Account__c = parentAccount.Id,
            Billing_Street__c = parentAccount.BillingStreet,
            Billing_City__c = parentAccount.BillingCity,
            Billing_State_Province__c = parentAccount.BillingState,
            Billing_Zip_Postal_Code__c = parentAccount.BillingPostalCode,
            Billing_Country__c = parentAccount.BillingCountry,
            Primary_Contact__c = sampleContact2.Id,
            Status__c = 'Validated'
        );
        billpayAccountList.add(parentBillingAccount);

        // Payable Account
        Billing_Account__c parentPayableAccount = new Billing_Account__c(
            RecordTypeId = Schema.SObjectType.Billing_Account__c.getRecordTypeInfosByName().get('Payable Account').getRecordTypeId(),    
            Account__c = parentAccount.Id,
            Billing_Street__c = parentAccount.BillingStreet,
            Billing_City__c = parentAccount.BillingCity,
            Billing_State_Province__c = parentAccount.BillingState,
            Billing_Zip_Postal_Code__c = parentAccount.BillingPostalCode,
            Billing_Country__c = parentAccount.BillingCountry,
            Primary_Contact__c = sampleContact2.Id,
            Status__c = 'Validated'
        );
        billpayAccountList.add(parentPayableAccount);
        insert(billpayAccountList);


        // Add the Primary Billing Account (Finance Account) to the parent account.
        parentAccount.Primary_Billing_Account__c = parentBillingAccount.Id;
        parentAccount.Primary_Payable_Account__c = parentPayableAccount.Id;
        update(parentAccount);


        // Shipping Label for Account.        
        Shipping_Label__c testShippingLabel = new Shipping_Label__c(
            Account__c = parentAccount.Id,
            Company_Name__c = parentAccount.Name,
            Contact__c = sampleContact1.Id,
            Contact_Name__c = sampleContact1.Name,
            Shipping_Street__c = '100 Howe St',
            Shipping_City__c = 'Southport',
            Shipping_State__c = 'North Carolina',
            Shipping_State_ISO__c = 'NC',
            Shipping_Postal__c = '28461',
            Shipping_Country__c = 'United States',
            Shipping_Country_ISO__c = 'US',
            Status__c = 'Active'
        );
        insert(testShippingLabel);







        /*
        /// Child Account 1
        Account fordAcct = new Account(
            RecordTypeId = acctRecType,
            ParentId = parentAccount.Id,
            Name = 'Sample Ford',
            BillingStreet = '1 Ford Way',
            BillingCity = 'Sampleton',
            BillingState = 'North Carolina',
            BillingPostalCode = '28461',
            Validated_Account_Name__c = 'Sample Ford',
            Accounting_Invoice_Name__c = 'Sample Ford, Inc',
            Legal_Entity_Name__c = 'Sample Ford, Inc',
            AccountSource = 'Marketing', // required
            Industry = 'Auto Retail New', // required
            Franchise_s__c = 'Ford',
            NumberOfEmployees = 100,
            AnnualRevenue = 5000000.00
        );
        insert(fordAcct);
        accountMap.put('Ford Account', fordAcct);
        System.debug(logTag + 'Inserted Ford child account.');

        // Contacts
        newContacts = new List<Contact>();
        Contact sampleContact4 = new Contact(
            RecordTypeId = contactRecType,
            AccountId = fordAcct.Id,
            FirstName = 'Glen',
            LastName = 'Glenderson',
            Title = 'CEO',
            NCM_Department__c = 'Executive',
            NCM_Title__c = 'Owner',
            Email = 'glen@sampleford.com',
            MailingStreet = '1 Ford Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        newContacts.add(sampleContact4);

        Contact sampleContact5 = new Contact(
            RecordTypeId = contactRecType,
            AccountId = fordAcct.Id,
            FirstName = 'Grace',
            LastName = 'Glenderson',
            Title = 'President',
            NCM_Department__c = 'Executive',
            NCM_Title__c = 'President',
            Email = 'grace@sampleford.com',
            MailingStreet = '1 Ford Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        newContacts.add(sampleContact5);

        Contact sampleContact6 = new Contact(
            RecordTypeId = contactRecType,
            AccountId = fordAcct.Id,
            FirstName = 'Gavin',
            LastName = 'Glenderson',
            Title = 'Parts and Service Manager',
            NCM_Department__c = 'Customer Service',
            NCM_Title__c = 'Manager',
            Email = 'gavin@sampleford.com',
            MailingStreet = '1 Ford Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        newContacts.add(sampleContact6);
        insert(newContacts);
        contactMap.put('Ford Dealer', newContacts);
        System.debug(logTag + 'Inserted Ford contacts.');
        customerContacts.addAll(newContacts);

        */



        /// Canadian Account
        Account canadaAcct = new Account(
            RecordTypeId = acctRecType,
            ParentId = parentAccount.Id,
            Name = 'Ontario CJDR',
            BillingStreet = '5280 Cixie Rd',
            BillingCity = 'Mississauga',
            BillingState = 'Ontario',
            BillingPostalCode = 'L4W 2A7',
            BillingCountry = 'Canada',
            Validated_Account_Name__c = 'Ontario CJDR',
            Accounting_Invoice_Name__c = 'Ontario CJDR',
            Legal_Entity_Name__c = 'Ontario CJDR',
            AccountSource = 'Marketing', // required
            Industry = 'Auto Retail New', // required
            Franchise_s__c = 'Jeep;Dodge;Chrysler;Fiat',
            NumberOfEmployees = 125,
            AnnualRevenue = 12000000.00
        );
        insert(canadaAcct);
        accountMap.put('Canada Account',canadaAcct);
        System.debug(logTag + 'Inserted Canada Jeep child account.');

        // Contacts
        List<Contact> canadaAcctContacts = new List<Contact>();
        canadaAcctContacts.add(
            new Contact(
                RecordTypeId = contactRecType,
                AccountId = canadaAcct.Id,
                FirstName = 'Hank',
                LastName = 'Henderson',
                Title = 'CEO',
                NCM_Department__c = 'Executive',
                NCM_Title__c = 'Owner',
                Email = 'hhenderson@samplejdc.com',
                MailingStreet = '1 Jeep Way',
                MailingCity = 'Southport',
                MailingState = 'North Carolina',
                MailingPostalCode = '28461'
            )
        );
        canadaAcctContacts.add(
            new Contact(
                RecordTypeId = contactRecType,
                AccountId = canadaAcct.Id,
                FirstName = 'Harriet',
                LastName = 'Henderson',
                Title = 'President',
                NCM_Department__c = 'Executive',
                NCM_Title__c = 'President',
                Email = 'hh@samplejdc.com',
                MailingStreet = '1 Jeep Way',
                MailingCity = 'Southport',
                MailingState = 'North Carolina',
                MailingPostalCode = '28461'
            )
        );

        canadaAcctContacts.add(
            new Contact(
                RecordTypeId = contactRecType,
                AccountId = canadaAcct.Id,
                FirstName = 'Haney',
                LastName = 'Henderson',
                Title = 'Parts and Service Manager',
                NCM_Department__c = 'Customer Service',
                NCM_Title__c = 'Manager',
                Email = 'haney.henderson@samplejdc.com',
                MailingStreet = '1 Jeep Way',
                MailingCity = 'Southport',
                MailingState = 'North Carolina',
                MailingPostalCode = '28461'
            )
        );
        insert(canadaAcctContacts);
        contactMap.put('Canada Account', newContacts);
        System.debug(logTag + 'Inserted Jeep contacts.');
        customerContacts.addAll(canadaAcctContacts);


        // Billing Account for Canada account
        Billing_Account__c canadaAcctBillingAccount = new Billing_Account__c(
            RecordTypeId = Schema.SObjectType.Billing_Account__c.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId(),    
            Account__c = canadaAcct.Id,
            Billing_Street__c = canadaAcct.BillingStreet,
            Billing_City__c = canadaAcct.BillingCity,
            Billing_State_Province__c = canadaAcct.BillingState,
            Billing_Zip_Postal_Code__c = canadaAcct.BillingPostalCode,
            Billing_Country__c = canadaAcct.BillingCountry,
            Primary_Contact__c = canadaAcctContacts[0].Id,
            Status__c = 'Validated'
        );
        insert(canadaAcctBillingAccount);

        
        Shipping_Label__c canadaShippingLabel = new Shipping_Label__c(
            Account__c = canadaAcct.Id,
            Company_Name__c = canadaAcct.Name,
            Contact__c = canadaAcctContacts[0].Id,
            Contact_Name__c = canadaAcctContacts[0].Name,
            Shipping_Street__c = canadaAcct.BillingStreet,
            Shipping_City__c = canadaAcct.BillingCity,
            Shipping_State__c = canadaAcct.BillingState,
            Shipping_State_ISO__c = 'ON',
            Shipping_Postal__c = canadaAcct.BillingPostalCode,
            Shipping_Country__c = canadaAcct.BillingCountry,
            Shipping_Country_ISO__c = 'CA',
            Status__c = 'Active'
        );
        insert(canadaShippingLabel);



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
        accountMap.put('NCM Account', ncmAccount);
        System.debug(logTag + 'Inserted NCM account.');

        ///User ncmBillingContactUser = [select id, name from user where profile.Name = 'Moderator' and IsActive = True LIMIT 1];
        //System.debug(logTag + 'User [' + ncmBillingContactUser.Name + ' selected as ncmBillingContactUser.');

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
            MailingPostalCode = '64112'
        );
        ncmContacts.add(ncmBillingContact);
        insert(ncmContacts);
        contactMap.put('NCM Account', new List<Contact>{ncmBillingContact});
        System.debug(logTag + 'Inserted ' + ncmContacts.size() + ' NCM contacts');

        
        /* NCM Billing Account */
        Billing_Account__c ncmBillingAcct = new Billing_Account__c(
            Name = 'NCM Billing Account',
            Account__c = ncmAccount.Id,
            Primary_Contact__c = ncmBillingContact.Id
        );
        insert(ncmBillingAcct);
        System.debug(logTag + 'Inserted NCM billing account');
        



        // Sample Dimensions and Products
        c2g__codaDimension1__c testDimension1 = new c2g__codaDimension1__c(
            Name = 'Test Dimension1',
            c2g__ReportingCode__c = '2000',
            Conductor_CC_Email__c = 'mdemeglio@ncmassociates.com'
        );
        insert(testDimension1);

        c2g__codaDimension2__c testDimension2 = new c2g__codaDimension2__c(
            Name = 'Test Dimension2',
            NCM_Employee__c = ncmBillingContact.Id,
            Billing_Account__c = parentBillingAccount.Id,
            Payable_Account__c = parentPayableAccount.Id,
            c2g__ExternalId__c = 'TestDim2',
            c2g__ReportingCode__c = 'ABC123'
        );
        insert(testDimension2);


        // 20G Quarterly Product and Shipping
        List<Product2> testProducts = new List<Product2>();
        Product2 test20GroupQuarterlyProduct = new Product2(
            IsActive = true,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('20 Groups').getRecordTypeId(),
            Name = '20 Group Quarterly Product',
            Dimension_1__c = testDimension1.Id,
            Product_Value__c = 500.00,
            Production_Run_Type__c = 'Not Applicable',
            Family = '20 Groups',
            Locked_Frequency__c = 'Quarterly',
            Shipped_Product__c = True // Required for trigger entry criteria!
        );
        testProducts.add(test20GroupQuarterlyProduct);

        // 20G Monthly Product
        Product2 test20GroupMonthlyProduct = new Product2(
            IsActive = true,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('20 Groups').getRecordTypeId(),
            Name = '20 Group Monthly Product',
            Dimension_1__c = testDimension1.Id,
            Product_Value__c = 500.00,
            Production_Run_Type__c = 'Not Applicable',
            Family = '20 Groups',
            Locked_Frequency__c = 'Monthly',
            Shipped_Product__c = True // Required for trigger entry criteria!
        );
        testProducts.add(test20GroupMonthlyProduct);


        // SHIPPING PRODUCTS
        Product2 testUSQuarterlyShippingProduct = new Product2(
            IsActive = true,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('20 Groups').getRecordTypeId(),
            Name = 'SHIPPING & HANDLING - US - QUARTERLY',
            Dimension_1__c = testDimension1.Id,
            Product_Value__c = 12.00,
            Production_Run_Type__c = 'Not Applicable',
            Family = '20 Groups',
            Locked_Frequency__c = 'Quarterly',
            Shipped_Product__c = False 
        );
        testProducts.add(testUSQuarterlyShippingProduct);

        Product2 testUSMonthlyShippingProduct = new Product2(
            IsActive = true,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('20 Groups').getRecordTypeId(),
            Name = 'SHIPPING & HANDLING - US - MONTHLY',
            Dimension_1__c = testDimension1.Id,
            Product_Value__c = 10.00,
            Production_Run_Type__c = 'Not Applicable',
            Family = '20 Groups',
            Locked_Frequency__c = 'Monthly',
            Shipped_Product__c = False 
        );
        testProducts.add(testUSMonthlyShippingProduct);

        Product2 testCanadaQtrlyShippingProduct = new Product2(
            IsActive = true,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('20 Groups').getRecordTypeId(),
            Name = 'SHIPPING & HANDLING - Canada - QUARTERLY',
            Dimension_1__c = testDimension1.Id,
            Product_Value__c = 10.00,
            Production_Run_Type__c = 'Not Applicable',
            Family = '20 Groups',
            Locked_Frequency__c = 'Quarterly',
            Shipped_Product__c = False 
        );
        testProducts.add(testCanadaQtrlyShippingProduct);

        Product2 testCanadaMonthlyShippingProduct = new Product2(
            IsActive = true,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('20 Groups').getRecordTypeId(),
            Name = 'SHIPPING & HANDLING - Canada - MONTHLY',
            Dimension_1__c = testDimension1.Id,
            Product_Value__c = 10.00,
            Production_Run_Type__c = 'Not Applicable',
            Family = '20 Groups',
            Locked_Frequency__c = 'Quarterly',
            Shipped_Product__c = False 
        );
        testProducts.add(testCanadaMonthlyShippingProduct);

        insert(testProducts);





        /* 20 Groups */
        // Get the User ID from the newly created ncmBillingContact contact
        Contact billingContact = [select Id, Name, User_Id__c from Contact where Email = :ncmBillingContact.Email LIMIT 1];
        System.debug(logTag + 'Billing Contact user Id: ' + billingContact.User_Id__c);

        List<Twenty_Groups__c> newTwentyGroups = new List<Twenty_Groups__c>();
        String twentyGroupRecType = Schema.SObjectType.Twenty_Groups__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId();
        Twenty_Groups__c twentyGroup1 = new Twenty_Groups__c(
            RecordTypeId = twentyGroupRecType,
            Status__c = 'Active',
            Start_Date__c = Date.today().addMonths(-6),
            Name = '2001',
            Group_Name__c = '2001',
            Moderator__c = billingContact.User_Id__c,
            NCM_Proprietor__c = ncmBillingContact.Id, //twentyGroupOwnerContact.Id,
            NCM_Support_Staff__c = ncmBillingContact.Id, //supportStaffContact.Id,
            Shipping_Not_Required__c = False
        );
        insert(twentyGroup1);
        System.debug(logTag + 'Inserted a sample 20 Group.');



        // 20 Group Members
        List<X20_Groups_Member__c> twentyGroupMembers = new List<X20_Groups_Member__c>();
        X20_Groups_Member__c parentAcct20GroupMember = new X20_Groups_Member__c(
            Group_ID__c = twentyGroup1.Id,
            Account__c = parentAccount.Id,
            Member_Number__c = 1,
            Billing_Account__c = parentBillingAccount.Id,
            Financial_Data_Contact__c = sampleContact2.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addYears(3),
            Type__c = 'Full Member',
            Status__c = 'Active'
        );
        twentyGroupMembers.add(parentAcct20GroupMember);

        
        X20_Groups_Member__c canadaAcct20GMember = new X20_Groups_Member__c(
            Group_ID__c = twentyGroup1.Id,
            Account__c = canadaAcct.Id,
            Member_Number__c = 2,
            Billing_Account__c = canadaAcctBillingAccount.Id,
            Financial_Data_Contact__c = canadaAcctContacts[0].Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addYears(3),
            Type__c = 'Full Member',
            Status__c = 'Active'
        );
        twentyGroupMembers.add(canadaAcct20GMember);

        insert(twentyGroupMembers);
        System.debug(logTag + 'Inserted ' + twentyGroupMembers.size() + ' 20 Group Member records.');

        
        
        // 20 Group Member Contacts
        List<X20_Group_Member_Contact__c> twentyGroupContacts = new List<X20_Group_Member_Contact__c>();
        twentyGroupContacts.add(
            new X20_Group_Member_Contact__c(
                X20_Group__c = twentyGroup1.Id,
                X20_Groups_Member__c = twentyGroupMembers[0].Id,
                Contact__c = sampleContact1.Id,
                Contact_Active_Date__c = Date.today(),
                Contact_Status__c = 'Active',
                Contact_Type__c = 'Member',
                Member_Email__c = sampleContact1.Email
            )
        );
        insert(twentyGroupContacts);
        System.debug(logTag + 'Inserted ' + twentyGroupContacts.size() + ' 20 Group Member Contacts.');


        /* Proprietary Groups */
        Proprietary_Group__c propGroup1 = new Proprietary_Group__c(
            RecordTypeId = Schema.SObjectType.Proprietary_Group__c.getRecordTypeInfosByName().get('Quarterly').getRecordTypeId(),
            Name = 'Sample Auto Group - Proprietary Group',
            Group_Name__c = 'Sample Auto Group - Proprietary Group',
            Group_Number__c = '8888',
            Group_Owner__c = billingContact.Id,
            Meetings_per_Year__c = 4,
            Account__c = parentAccount.Id,
            Billing_Account__c = parentBillingAccount.Id,
            Billing_Frequency__c = 'Quarterly',
            Contact__c = sampleContact1.Id,
            Street__c = parentAccount.BillingStreet,
            City__c = parentAccount.BillingCity,
            State__c = parentAccount.BillingState,
            Postal_Code__c = parentAccount.BillingPostalCode,
            Rate_Type__c = 'Monthly Rate Schedule'
        );
        insert(propGroup1);
        System.debug(logTag + 'Inserted 1 Proprietary Group: ' + propGroup1.Name);


        

        Proprietary_Account__c propAcct1 = new Proprietary_Account__c(
            Proprietary_Group__c = propGroup1.Id,
            Account__c = parentAccount.Id,
            Shipping_Address__c = parentAccount.BillingStreet,
            Shipping_City__c = parentAccount.BillingCity,
            Shipping_State__c = parentAccount.BillingState,
            Shipping_Postal_Code__c = parentAccount.BillingPostalCode,
            Shipping_Country__c = parentAccount.BillingCountry,
            Billing_Account__c = parentBillingAccount.Id,
            Contact__c = sampleContact1.Id,
            Financial_Statement_Contact__c = sampleContact2.Id,
            Start_Date__c = Date.today(),
            Type__c = 'Full Member',
            Status__c = 'Active'
        );
        insert(propAcct1);
        System.debug(logTag + 'Inserted Proprietary Account.');


        /**** Proprietary Account Contacts ****/
        List<Proprietary_Account_Contact__c> propAcctContacts = new List<Proprietary_Account_Contact__c>();
        
        // Loop through all the sample contacts
        for(Contact c : customerContacts){
            propAcctContacts.add(
                new Proprietary_Account_Contact__c(
                    RecordTypeId = Schema.SObjectType.Proprietary_Account_Contact__c.getRecordTypeInfosByName().get('Proprietary Contact').getRecordTypeId(),
                    Proprietary_Account__c = propAcct1.Id,
                    Contact__c = c.Id,
                    Contact_Type__c = 'Member',
                    Department_NCM_Classification__c = 'Administrative',
                    Member_Email__c = c.Email,
                    Name = c.FirstName + ' ' + c.LastName,
                    Proprietary_Group__c = propGroup1.Id,
                    Status__c = 'Active'
                )
            );
        }



        /**** Billing Products ****/

        // MD: Temp - add some billing products to simulate products that were already on the group account prior to new ones being added.
        // Insert a Billing Product that requires shipping fees.
        Billing_Product__c testBP1 = new Billing_Product__c(
            RecordTypeId = Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId(),
            X20_Group_Account_Member__c = canadaAcct20GMember.Id, // required for trigger entry criteria
            Billing_Product_Status__c = 'Active', // required for trigger entry criteria
            Product__c = test20GroupQuarterlyProduct.Id,
            Shipping_Label_New__c = canadaShippingLabel.Id,
            Starting_Price__c = 500.00,
            Value__c = 500.00,
            Billing_Account__c = canadaAcctBillingAccount.Id,
            Billing_Frequency__c = 'Quarterly',
            Billing_Product_Type__c = 'Revenue',
            Dimension_1__c = testDimension1.Id,
            Dimension_2__c = testDimension2.Id,
            Last_Billed_Date__c = Date.today(),
            Next_Billing_Date__c = Date.today().addMonths(3),
            Recurring_Billing_Day__c = 16
        );
        System.debug('SETUP: 20Group Member Id: ' + canadaAcct20GMember.Id);
        insert(testBP1);
        System.debug(logTag + 'Added a shippable billing product during setup.');
        




        System.debug(logTag + '**** END of Data Setup ****');
        return testData;
    }

}