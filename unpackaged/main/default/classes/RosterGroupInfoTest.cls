@isTest
public class RosterGroupInfoTest {
    
    @testSetup
    static void setup(){
        
        // Create some setup records..
        String logTag = 'RosterGroupInfoTest::setup';
        
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

        /// Child Account 2
        Account jeepAcct = new Account(
            RecordTypeId = acctRecType,
            ParentId = parentAccount.Id,
            Name = 'Sample Jeep Dodge Chrysler Fiat',
            BillingStreet = '1 Jeep Way',
            BillingCity = 'Sampleton',
            BillingState = 'North Carolina',
            BillingPostalCode = '28461',
            Validated_Account_Name__c = 'Sample Jeep Dodge Chrysler Fiat',
            Accounting_Invoice_Name__c = 'Sample Jeep Dodge, Inc',
            Legal_Entity_Name__c = 'Sample Jeep Dodge Chrysler Fiat, Inc',
            AccountSource = 'Marketing', // required
            Industry = 'Auto Retail New', // required
            Franchise_s__c = 'Jeep;Dodge;Chrysler;Fiat',
            NumberOfEmployees = 125,
            AnnualRevenue = 12000000.00
        );
        insert(jeepAcct);
        accountMap.put('Jeep Account',jeepAcct);
        System.debug(logTag + 'Inserted Jeep child account.');

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
                Email = 'hhenderson@samplejdc.com',
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
        System.debug(logTag + 'Inserted Jeep contacts.');
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

        ///User ncmBillingContactUser = [select id, name from user where profile.Name = 'Moderator' and IsActive = True LIMIT 1];
        //System.debug(logTag + 'User [' + ncmBillingContactUser.Name + ' selected as ncmBillingContactUser.');

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
                CommunityNickname = 'barneytest',
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
            Name = '2001 20 Group',
            Group_Name__c = '2001 20 Group',
            Moderator__c = billingContact.User_Id__c,
            NCM_Proprietor__c = ncmBillingContact.Id, //twentyGroupOwnerContact.Id,
            NCM_Support_Staff__c = ncmBillingContact.Id //supportStaffContact.Id,
        );
        insert(twentyGroup1);
        System.debug(logTag + 'Inserted a sample 20 Group.');



        // 20 Group Members
        List<X20_Groups_Member__c> twentyGroupMembers = new List<X20_Groups_Member__c>();
        twentyGroupMembers.add(
            new X20_Groups_Member__c(
                Group_ID__c = twentyGroup1.Id,
                Account__c = parentAccount.Id,
                Member_Number__c = 10,
                Billing_Account__c = parentBillingAccount.Id,
                Financial_Data_Contact__c = sampleContact2.Id,
                Start_Date__c = Date.today(),
                End_Date__c = Date.today().addYears(3)
            )
        );
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
            Group_Owner__c = ncmBillingContact.Id,
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
        
        /*
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
		*/
        
        

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
    
    @isTest
    static void validateNullCheck() {
        String s = RosterGroupInfo.nullCheck('test');
        System.assertEquals('test', s, 'nullCheck should return the same string');
        s = RosterGroupInfo.nullcheck(null);
        System.assertEquals('', s, 'nullCheck should return an empty string');
    }
    
    @isTest
    static void twentyMemberRosterTest(){
        
        Twenty_Groups__c test20Group = [SELECT Id, Name FROM Twenty_Groups__c limit 1];
        
        PageReference pageRef = Page.GroupRoster;
        Test.setCurrentPage(pageRef);
      	// Add parameters to page URL
        ApexPages.currentPage().getParameters().put('group', test20Group.Name);
      
        ApexPages.StandardController sc = new ApexPages.StandardController(test20Group);
        RosterGroupInfo con;
        
        Test.startTest();
        	con = new RosterGroupInfo(sc);
        Test.stopTest();
        
        // Test: was the members property populated correctly?
        System.assertNotEquals(null, con.members);
        
    }
    
    
    @isTest
    static void twentyCandidateRosterTest(){
        
        Twenty_Groups__c test20Group = [SELECT Id, Name FROM Twenty_Groups__c limit 1];
        //X20_Groups_Member__c testMemberAccount = [select id, Type__c from X20_Groups_Member__c limit 1];
        //testMemberAccount.Type__c = 'Candidate';
        
        PageReference pageRef = Page.GroupRoster;
        Test.setCurrentPage(pageRef);
      	// Add parameters to page URL
        ApexPages.currentPage().getParameters().put('group', test20Group.Name);
      	ApexPages.currentPage().getParameters().put('candidate', 'true');
        
        ApexPages.StandardController sc = new ApexPages.StandardController(test20Group);
        RosterGroupInfo con;
        
        Test.startTest();
        	con = new RosterGroupInfo(sc);
        Test.stopTest();
        
        // Test: was the members property populated correctly?
        System.assertNotEquals(null, con.members);
    }
    
    
    @isTest
    static void propMemberRosterTest(){
        
        Proprietary_Group__c testPropGroup = [SELECT Id, Name FROM Proprietary_Group__c limit 1];
        
        PageReference pageRef = Page.GroupRoster;
        Test.setCurrentPage(pageRef);
      	// Add parameters to page URL
        ApexPages.currentPage().getParameters().put('group', testPropGroup.Name);
      
        ApexPages.StandardController sc = new ApexPages.StandardController(testPropGroup);
        RosterGroupInfo con;
        
        Test.startTest();
        	con = new RosterGroupInfo(sc);
        Test.stopTest();
        
        // Test: was the members property populated correctly?
        System.assertNotEquals(null, con.members);
    }
    
    
    @isTest
    static void propCandidateRosterTest(){
        
        Proprietary_Group__c testPropGroup = [SELECT Id, Name FROM Proprietary_Group__c limit 1];
        
        PageReference pageRef = Page.GroupRoster;
        Test.setCurrentPage(pageRef);
      	// Add parameters to page URL
        ApexPages.currentPage().getParameters().put('group', testPropGroup.Name);
      	ApexPages.currentPage().getParameters().put('candidate', 'true');
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testPropGroup);
        RosterGroupInfo con;
        
        Test.startTest();
        	con = new RosterGroupInfo(sc);
        Test.stopTest();
        
        // Test: was the members property populated correctly?
        System.assertNotEquals(null, con.members);
        
    }
    
}