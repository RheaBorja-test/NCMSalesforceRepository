@isTest
public class EngagementAttendeeService_Tests {

    @TestSetup
    static void setup(){

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
            City__c = 'Dallas',
            State_pl__c = 'TX',
            Country_pl__c = 'United States' 
        );
        newEngagements.add(testEngagement1);
        
        Engagement__c testEngagement2 = new Engagement__c(
            RecordTypeId = retailEngagementRecType,
            Name = 'Sample Engagement 2',
            X20_Group__c = test20Group.Id,
            Status__c = 'Tentative',
            Engagement_Type__c = '20 Group',
            Engagement_Description__c = 'Regular',
            Engagement_Owner__c = ncmBillingContact.Id,
            City__c = 'Dallas', 
            State_pl__c = 'TX', 
            Country_pl__c = 'United States'
            
        );
        newEngagements.add(testEngagement2);

        Engagement__c testEngagement3 = new Engagement__c(
            RecordTypeId = retailEngagementRecType,
            Name = 'Sample Engagement 3',
            X20_Group__c = test20Group.Id,
            Status__c = 'Tentative',
            Engagement_Type__c = '20 Group',
            Engagement_Description__c = 'Regular',
            Engagement_Owner__c = ncmBillingContact.Id, 
            City__c = 'Dallas', 
            State_pl__c = 'TX', 
            Country_pl__c = 'United States' 
        );
        newEngagements.add(testEngagement3);

        /************** checkAttendeeStatus method section start *********** */
        /** This section covers the EngagementAttendeeUtilityReportQueueable.cls **/
        // IN THE FUTURE DERRICK SOME OF THIS CAN BE MERGED INTO THE CODE ABOVE //
         
        Account financialAccount = new Account(
            Name = 'Test Financial Account', 
            ShippingPostalCode = '12345'
        );
        insert(financialAccount);
        
        Contact contact = new Contact(
            FirstName = 'Firstname', 
            LastName = 'Lastname', 
            Email = 'test@example.com'
        );
        insert(contact);

        Area_of_Focus__c focus = new Area_of_Focus__c(
            Name = 'Test Focus Area'
        );
        insert(focus);

        Educational_Program__c program = new Educational_Program__c(
            Name = 'Test Program', 
            Area_of_Focus__c = focus.Id
        );
        insert(program);

        Course__c course = new Course__c(
            Name = 'Test Course',
            Course_ID__c = '123456789',
            Educational_Program__c = program.Id,
            Composite_PTA__c = true
        );
        insert(course);

        String engRecordTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('NCM Institute Class - Onsite').getRecordTypeId();
        
        Engagement__c engagement = new Engagement__c(
            Name = 'Test Engagement US Onsite',
            Account__c = financialAccount.Id,
            Country_pl__c = 'United States',
            RecordTypeId = engRecordTypeId,
            Engagement_Start__c = System.today().addDays(10),
            Course__c  = course.Id
        );
        newEngagements.add(engagement);
 
        String engRecTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('NCM Institute Class - Live Session Virtual Training').getRecordTypeId();
        
        Engagement__c engagement1 = new Engagement__c(
            Name = 'Test Engagement1 Virtual Training',
            Account__c = financialAccount.Id,
            Country_pl__c = '',
            RecordTypeId = engRecTypeId,
            Engagement_Start__c = System.today().addDays(10),
            Course__c  = course.Id
        );
        newEngagements.add(engagement1);
        
        Engagement__c engagement2 = new Engagement__c(
            Name = 'Test Engagement2 Canada Onsite',
            Account__c = financialAccount.Id,
            Country_pl__c = 'Canada',
            RecordTypeId = engRecordTypeId,
            Engagement_Start__c = System.today().addDays(20),
            Course__c  = course.Id
        );
        newEngagements.add(engagement2);
		
		Engagement__c engagement3 = new Engagement__c(
            Name = 'Test Engagement3 Canada Virtual Training',
            Account__c = financialAccount.Id,
            Country_pl__c = 'Canada',
            RecordTypeId = engRecTypeId,
            Engagement_Start__c = System.today().addDays(20),
            Course__c  = course.Id
        );
        newEngagements.add(engagement3);  
        insert(newEngagements);
        
        // Need this RecordType to get access to the 'Registration Confirmed' Attendance Status value.
        String engAttendeeRecordTypeId = Schema.SObjectType.Engagement_Attendee__c.getRecordTypeInfosByName().get('Institute - Training Subscription Seats').getRecordTypeId();
        List<Engagement_Attendee__c> newAttendees = new List<Engagement_Attendee__c>();
        
        Engagement_Attendee__c attendee = new Engagement_Attendee__c(
            Name = 'Test Attendee',
            Account__c = financialAccount.Id,
            Attendance_Status__c = 'Pending Class',
            Engagement__c = engagement.Id,
            RecordTypeId = engAttendeeRecordTypeId,
            Contact__r = contact,
            Contact_Email__c = contact.Email,
            Financial_Data_Account__c = financialAccount.Id,
            Financial_Data_Number__c = 'FD1232',
            Financial_Data_Notes__c = 'Test Notes',
            Registration_Received__c = System.today()
        );
        newAttendees.add(attendee);
        
        Engagement_Attendee__c attendee1 = new Engagement_Attendee__c(
            Name = 'Test Attendee1',
            Account__c = financialAccount.Id,
            Attendance_Status__c = 'Pending Class',
            Engagement__c = engagement1.Id,
            RecordTypeId = engAttendeeRecordTypeId,
            Contact__r = contact,
            Contact_Email__c = contact.Email,
            Financial_Data_Account__c = financialAccount.Id,
            Financial_Data_Number__c = 'FD1234',
            Financial_Data_Notes__c = 'Test Notes',
            Registration_Received__c = System.today()
        );
        newAttendees.add(attendee1);
        
        Engagement_Attendee__c attendee2 = new Engagement_Attendee__c(
            Name = 'Test Attendee2',
            Account__c = financialAccount.Id,
            Attendance_Status__c = 'Pending Class',
            Engagement__c = engagement2.Id,
            RecordTypeId = engAttendeeRecordTypeId,
            Contact__r = contact,
            Contact_Email__c = contact.Email,
            Financial_Data_Account__c = financialAccount.Id,
            Financial_Data_Number__c = 'FD1233',
            Financial_Data_Notes__c = 'Test Notes',
            Registration_Received__c = System.today()
        );
        newAttendees.add(attendee2);
        
        Engagement_Attendee__c attendee3 = new Engagement_Attendee__c(
            Name = 'Test Attendee3',
            Account__c = financialAccount.Id,
            Attendance_Status__c = 'Registration Confirmed',
            Engagement__c = engagement3.Id,
            RecordTypeId = engAttendeeRecordTypeId,
            Contact__r = contact,
            Contact_Email__c = contact.Email,
            Financial_Data_Account__c = financialAccount.Id,
            Financial_Data_Number__c = 'FD1235',
            Financial_Data_Notes__c = 'Test Notes',
            Registration_Received__c = System.today()
        );
        newAttendees.add(attendee3);
        insert(newAttendees);
         /************** sendUtilityReportCSV method section end *********** */
        
        Engagement_Activity__c ea = new Engagement_Activity__c(
            Name = 'Test Activity',
            Engagement__c = newEngagements[0].Id
        );
        insert(ea);
        
        // Files needed for the Send Welcome Emails test. 
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        ContentVersion welcomeLetter = new ContentVersion(
            Title = 'NCM Welcome Letter 3 7 23',
            VersionData = Blob.valueOf('Sample PDF Data'),
            PathOnClient = 'NCM Welcome Letter 3 7 23.pdf',
            IsMajorVersion = true
        );
        contentVersionList.add(welcomeLetter);
        
        ContentVersion emailLogo = new ContentVersion(
            Title = 'NCM_Email_Logo',
            VersionData = Blob.valueOf('Sample Logo Data'),
            PathOnClient = 'NCM_Email_Logo.pdf',
            IsMajorVersion = true
        );
        contentVersionList.add(emailLogo);
        insert(contentVersionList);
        
    }
   
    @isTest
    static void testDuplicateAttendee(){
        //Remove an attendee from an engagement and make their Activity Participation is deleted.
        List<Engagement__c> testEngagements = [select id from Engagement__c ];
        String attendeeRecType = Schema.SObjectType.Engagement_Attendee__c.getRecordTypeInfosByName().get('Engagement Attendee').getRecordTypeId();
        Contact c = [SELECT Id, Name, Email, AccountId FROM Contact LIMIT 1];
        User testUser = [select id, name from user where IsActive = true and Profile.Name = 'System Administrator' limit 1];
        User currentUser = [select id, name from user where Id = :UserInfo.getUserId()];
        Engagement_Attendee__c testAttendee;
        
        System.runAs(testUser){
            testAttendee = new Engagement_Attendee__c(
                RecordTypeId = attendeeRecType,
                Contact__c = c.Id,
                Account__c = c.AccountId,
                Age_Group__c = 'Adult',
                Attendance_Status__c = 'Tentative',
                Attendee_Type__c = 'Member',
                Engagement__c = testEngagements[0].Id,
                In_Meeting_Room__c = true
            ); 
            insert(testAttendee);

            Engagement_Activity__c ea = [SELECT Id FROM Engagement_Activity__c LIMIT 1];

            Activity_Participation__c ap = new Activity_Participation__c(
                Engagement_Attendee__c = testAttendee.Id,
                Engagement_Activity__c = ea.Id
            );
            insert ap;

            // New: add 'Engagement_Attendee_Bypass_Attendance_Status' permission set to the current user so they can change the attendee status to Removed.
            PermissionSet permSet = [select id, name from permissionset where name = 'Engagement_Attendee_Bypass_Attendance_Status' limit 1];
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = currentUser.Id,
                PermissionSetId = permSet.Id
            );
            insert(psa);

        }

        
        Test.startTest();
            System.runAs(currentUser){
                TriggerHandler.clearBypass('EngagementAttendeeService.removeFromActivities');
                testAttendee.Attendance_Status__c = 'Duplicate';
                update(testAttendee);
            }
        Test.stopTest();

        Engagement_Attendee__c attResult = [select id, name, In_Meeting_Room__c from Engagement_Attendee__c where ID = :testAttendee.Id];
        Assert.isFalse(attResult.In_Meeting_Room__c);

    }


    @isTest
    static void bulkAddEngagementAttendeesTEST(){
        // insert a bunch of attendees at once and see if their Attendee_No__c field is set properly.


        List<Engagement__c> testEngagements = [select id from Engagement__c ];
        
        
        List<Engagement_Attendee__c> newAttendees = new List<Engagement_Attendee__c>();
        String attendeeRecType = Schema.SObjectType.Engagement_Attendee__c.getRecordTypeInfosByName().get('Engagement Attendee').getRecordTypeId();
        for(Contact c:[SELECT Id, Name, Email, AccountId FROM Contact]){
            newAttendees.add(
                new Engagement_Attendee__c(
                    RecordTypeId = attendeeRecType,
                    Contact__c = c.Id,
                    Account__c = c.AccountId,
                    Age_Group__c = 'Adult',
                    Attendance_Status__c = 'Tentative',
                    Attendee_Type__c = 'Member',
                    Engagement__c = testEngagements[0].Id
                )
            );
            newAttendees.add(
                new Engagement_Attendee__c(
                    RecordTypeId = attendeeRecType,
                    Contact__c = c.Id,
                    Account__c = c.AccountId,
                    Age_Group__c = 'Adult',
                    Attendance_Status__c = 'Tentative',
                    Attendee_Type__c = 'Guest',
                    Engagement__c = testEngagements[1].Id
                )
            );
            newAttendees.add(
                new Engagement_Attendee__c(
                    RecordTypeId = attendeeRecType,
                    Contact__c = c.Id,
                    Account__c = c.AccountId,
                    Age_Group__c = 'Candidate',
                    Attendance_Status__c = 'Tentative',
                    Attendee_Type__c = 'Member',
                    Engagement__c = testEngagements[2].Id
                )
            );
        }

        Test.startTest();
            insert(newAttendees);
        Test.stopTest();

        for(Engagement_Attendee__c ea : [select Id, Name, Attendee_No__c, Engagement__r.Engagement_Number__c, Contact__r.Name FROM Engagement_Attendee__c WHERE Engagement__c = :testEngagements[0].Id]){
            System.debug('Engagement 1: Attendee Number ' + ea.Attendee_No__c + ' assigned to attendee id ' + ea.Id);
            Assert.isNotNull(ea.Attendee_No__c, 'No Attendee Number assigned to ' + ea.Id);
            System.debug('Test: Name: ' + ea.Name);
            Assert.isTrue(ea.Name.contains(ea.Contact__r.Name));
            Assert.isTrue(ea.Name.contains(String.valueOf(ea.Attendee_No__c)));
            Assert.isTrue(ea.Name.contains(ea.Engagement__r.Engagement_Number__c));
        }
        
        for(Engagement_Attendee__c ea : [select Id, Attendee_No__c FROM Engagement_Attendee__c WHERE Engagement__c = :testEngagements[1].Id]){
            System.debug('Engagement 2: Attendee Number ' + ea.Attendee_No__c + ' assigned to attendee id ' + ea.Id);
            Assert.isNotNull(ea.Attendee_No__c, 'No Attendee Number assigned to ' + ea.Id);
        }
        
        for(Engagement_Attendee__c ea : [select Id, Attendee_No__c FROM Engagement_Attendee__c WHERE Engagement__c = :testEngagements[2].Id]){
            System.debug('Engagement 3: Attendee Number ' + ea.Attendee_No__c + ' assigned to attendee id ' + ea.Id);
            Assert.isNotNull(ea.Attendee_No__c, 'No Attendee Number assigned to ' + ea.Id);
        }        
    }

    //this method added by Tim Osborn on 8/28/2023 to cover after update trigger that was added for SALES-970
    @isTest
    static void testRemoveFromActivities(){
        //Remove an attendee from an engagement and make their Activity Participation is deleted.
        List<Engagement__c> testEngagements = [select id from Engagement__c ];
        String attendeeRecType = Schema.SObjectType.Engagement_Attendee__c.getRecordTypeInfosByName().get('Engagement Attendee').getRecordTypeId();
        Contact c = [SELECT Id, Name, Email, AccountId FROM Contact LIMIT 1];
        User testUser = [select id, name from user where IsActive = true and Profile.Name = 'System Administrator' limit 1];
        User currentUser = [select id, name from user where Id = :UserInfo.getUserId()];
        Engagement_Attendee__c testAttendee;

        System.runAs(testUser){
            testAttendee = new Engagement_Attendee__c(
                RecordTypeId = attendeeRecType,
                Contact__c = c.Id,
                Account__c = c.AccountId,
                Age_Group__c = 'Adult',
                Attendance_Status__c = 'Tentative',
                Attendee_Type__c = 'Member',
                Engagement__c = testEngagements[0].Id
            ); 
            insert(testAttendee);

            Engagement_Activity__c ea = [SELECT Id FROM Engagement_Activity__c LIMIT 1];

            Activity_Participation__c ap = new Activity_Participation__c(
                Engagement_Attendee__c = testAttendee.Id,
                Engagement_Activity__c = ea.Id
            );
            insert(ap);

            // New: add 'Engagement_Attendee_Bypass_Attendance_Status' permission set to the current user so they can change the attendee status to Removed.
            PermissionSet permSet = [select id, name from permissionset where name = 'Engagement_Attendee_Bypass_Attendance_Status' limit 1];
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = currentUser.Id,
                PermissionSetId = permSet.Id
            );
            insert(psa);

        }
        
        Test.startTest();
            System.runAs(currentUser){
                TriggerHandler.clearBypass('EngagementAttendeeService.removeFromActivities');
                testAttendee.Attendance_Status__c = 'Removed';
                update(testAttendee);
            }
        Test.stopTest();

        Engagement_Attendee__c attResult = [select id, name, Attendance_Status__c from Engagement_Attendee__c where ID = :testAttendee.Id];
        Assert.areEqual('Removed', attResult.Attendance_Status__c);

    }

    @isTest
    static void attendeeContactChanged_Test(){
        //Remove an attendee from an engagement and make their Activity Participation is deleted.
        List<Engagement__c> testEngagements = [select id from Engagement__c ];
        String attendeeRecType = Schema.SObjectType.Engagement_Attendee__c.getRecordTypeInfosByName().get('Engagement Attendee').getRecordTypeId();
        Contact c = [SELECT Id, Name, Email, AccountId FROM Contact LIMIT 1];
        Engagement_Attendee__c testAttendee = new Engagement_Attendee__c(
            RecordTypeId = attendeeRecType,
            Contact__c = c.Id,
            Account__c = c.AccountId,
            Age_Group__c = 'Adult',
            Attendance_Status__c = 'Tentative',
            Attendee_Type__c = 'Member',
            Engagement__c = testEngagements[0].Id
        ); 
        insert(testAttendee);

        Contact newContact = [select id, name from Contact where Id != :c.Id LIMIT 1];
        testAttendee.Contact__c = newContact.id;

        Test.startTest();
            update(testAttendee);
        Test.stopTest();

        Engagement_Attendee__c attResult = [select id, name from Engagement_Attendee__c where ID = :testAttendee.Id];
        Assert.isTrue(attResult.Name.contains(newContact.Name));

    }
    
    //Test covers EngagementAttendeeUtilityReportQueueable
    @isTest
    static void checkAttendeeStatus_US_Confirmed() {
        
        Engagement_Attendee__c attendee = [SELECT Id, 
                                                  Name, 
                                                  Contact__r.Name,
                                                  Contact_Email__c,
                                                  Engagement__c,
                                                  Engagement__r.Name, 
                                                  Engagement__r.RecordType.Name,
                                                  Engagement__r.Country_pl__c,
                                                  Financial_Data_Account__r.Name,
                                                  Financial_Data_Account__r.ShippingPostalCode,                                               
                                                  Financial_Data_Number__c,
                                                  Financial_Data_Notes__c,
                                                  Last_Time_Rescheduled__c,
                                                  Registration_Received__c,
                                                  Attendance_Status__c, 
                                           		  Engagement__r.Engagement_Start_Date__c,
                                                  Engagement__r.Engagement_Start__c
                                           FROM   Engagement_Attendee__c 
                                           WHERE  Financial_Data_Number__c = 'FD1232' LIMIT 1
                                           ];
        
        Engagement_Attendee__c newAttendee = attendee.clone(true);
        //newAttendee.Id = attendee.Id;
        newAttendee.Attendance_Status__c = 'Registration Confirmed';
        Test.startTest();
        	update(newAttendee);
        Test.stopTest();
        
        Assert.areEqual('Registration Confirmed', newAttendee.Attendance_Status__c);        
    }
    
    //Test covers EngagementAttendeeUtilityReportQueueable
    @isTest
    static void checkAttendeeStatus_US_Vitual() {
         
        Engagement_Attendee__c attendee = [SELECT Id, 
                                                  Name, 
                                                  Contact__r.Name,
                                                  Contact_Email__c,
                                                  Engagement__c,
                                                  Engagement__r.Name, 
                                                  Engagement__r.RecordType.Name,
                                                  Engagement__r.Country_pl__c,
                                                  Financial_Data_Account__r.Name,
                                                  Financial_Data_Account__r.ShippingPostalCode,                                               
                                                  Financial_Data_Number__c,
                                                  Financial_Data_Notes__c,
                                                  Last_Time_Rescheduled__c,
                                                  Registration_Received__c,
                                                  Attendance_Status__c, 
                                           		  Engagement__r.Engagement_Start_Date__c,
                                                  Engagement__r.Engagement_Start__c
                                           FROM   Engagement_Attendee__c 
                                           WHERE  Financial_Data_Number__c = 'FD1234' LIMIT 1
                                           ];
 
        Engagement_Attendee__c newAttendee = attendee.clone(true);
        newAttendee.Attendance_Status__c = 'Registration Confirmed';
        Test.startTest();
        	update(newAttendee);
        Test.stopTest();
        
        Assert.areEqual('Registration Confirmed', newAttendee.Attendance_Status__c);         
    }
    
    //Test covers EngagementAttendeeUtilityReportQueueable
    @isTest
    static void checkAttendeeStatus_CA_Confirmed() {

        Engagement_Attendee__c attendee = [SELECT Id, 
                                                  Name, 
                                                  Contact__r.Name,
                                                  Contact_Email__c,
                                                  Engagement__c,
                                                  Engagement__r.Name, 
                                                  Engagement__r.RecordType.Name,
                                                  Engagement__r.Country_pl__c,
                                                  Financial_Data_Account__r.Name,
                                                  Financial_Data_Account__r.ShippingPostalCode,                                               
                                                  Financial_Data_Number__c,
                                                  Financial_Data_Notes__c,
                                                  Last_Time_Rescheduled__c,
                                                  Registration_Received__c,
                                                  Attendance_Status__c, 
                                           		  Engagement__r.Engagement_Start_Date__c,
                                                  Engagement__r.Engagement_Start__c
                                           FROM   Engagement_Attendee__c 
                                           WHERE  Financial_Data_Number__c = 'FD1233' LIMIT 1
                                           ];
 
        Engagement_Attendee__c newAttendee = attendee.clone(true);
        newAttendee.Attendance_Status__c = 'Registration Confirmed';
        Test.startTest();
        	update(newAttendee);
        Test.stopTest();
        
        Assert.areEqual('Registration Confirmed', newAttendee.Attendance_Status__c);         
    }    
    
     //Test covers EngagementAttendeeUtilityReportQueueable
    @isTest
    static void checkAttendeeStatus_US_AfterInsert() {

        Account financialAccount = [Select Id, name From Account Where Name = 'Test Financial Account'];
        Contact contact = [Select Id, FirstName, Email From Contact Where FirstName = 'FirstName'];
		Course__c course = [Select Id, Name From Course__c Where Name =  'Test Course'];
       
        String engRecordTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('NCM Institute Class - Onsite').getRecordTypeId();
        
        Engagement__c engagement = new Engagement__c(
            Name = 'Test Engagement US Onsite',
            Account__c = financialAccount.Id,
            Country_pl__c = 'United States',
            RecordTypeId = engRecordTypeId,
            Engagement_Start__c = System.today().addDays(10),
            Course__c  = course.Id
        );
        insert(engagement);
      
        // Need this RecordType to get access to the 'Registration Confirmed' Attendance Status value.
        String engAttendeeRecordTypeId = Schema.SObjectType.Engagement_Attendee__c.getRecordTypeInfosByName().get('Institute - Training Subscription Seats').getRecordTypeId();
        
        Engagement_Attendee__c attendee = new Engagement_Attendee__c(
            Name = 'Test Attendee',
            Account__c = financialAccount.Id,
            Attendance_Status__c = 'Registration Confirmed',
            Engagement__c = engagement.Id,
            RecordTypeId = engAttendeeRecordTypeId,
            Contact__r = contact,
            Contact_Email__c = contact.Email,
            Financial_Data_Account__c = financialAccount.Id,
            Financial_Data_Number__c = 'FD1232',
            Financial_Data_Notes__c = 'Test Notes',
            Registration_Received__c = System.today()
        );
             
        Test.startTest();
        	 insert(attendee);
        Test.stopTest();
        
        Assert.areEqual('Registration Confirmed', attendee.Attendance_Status__c);        
    }
    
    @isTest
    static void checkAttendeeStatus_US_Rebooking() {

        Account financialAccount = [Select Id, name From Account Where Name = 'Test Financial Account'];
        Contact contact = [Select Id, FirstName, Email From Contact Where FirstName = 'FirstName'];
		Course__c course = [Select Id, Name From Course__c Where Name =  'Test Course'];
       
        String engRecordTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('NCM Institute Class - Onsite').getRecordTypeId();
        
        Engagement__c engagement = new Engagement__c(
            Name = 'Test Engagement US Onsite',
            Account__c = financialAccount.Id,
            Country_pl__c = 'United States',
            RecordTypeId = engRecordTypeId,
            Engagement_Start__c = System.today().addDays(10),
            Course__c  = course.Id
        );
        insert(engagement);
      
        // Need this RecordType to get access to the 'Registration Confirmed' Attendance Status value.
        String engAttendeeRecordTypeId = Schema.SObjectType.Engagement_Attendee__c.getRecordTypeInfosByName().get('Institute - Paid Seat').getRecordTypeId();
        
        Engagement_Attendee__c attendee = new Engagement_Attendee__c(
            Name = 'Test Attendee',
            Account__c = financialAccount.Id,
            Attendance_Status__c = 'Registration Confirmed',
            Engagement__c = engagement.Id,
            RecordTypeId = engAttendeeRecordTypeId,
            Contact__r = contact,
            Contact_Email__c = contact.Email,
            Financial_Data_Account__c = financialAccount.Id,
            Financial_Data_Number__c = 'FD1232',
            Financial_Data_Notes__c = 'Test Notes',
            Registration_Received__c = System.today()
        );
        insert(attendee);             
             
        Test.startTest();
        	 attendee.Attendance_Status__c = 'Rebooking';
        	 update(attendee);
        Test.stopTest();
        
        Assert.areEqual('Rebooking', attendee.Attendance_Status__c);        
    }
    
    // test covers EngagmentAttendeeService.cls, and EngagementInstituteWelcomeEmailsBatch.cls
    @isTest
    static void sendWelcomeEmailOnsite() {

        Account financialAccount = [Select Id, name From Account Where Name = 'Test Financial Account'];
        Contact contact = [Select Id, FirstName, Email From Contact Where FirstName = 'FirstName'];
		//Course__c course = [Select Id, Name From Course__c Where Name =  'Test Course']; // Causes 101 Error. Really not needed. 
        
        String engRecordTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('NCM Institute Class - Onsite').getRecordTypeId();
        
        Engagement__c engagement = new Engagement__c(
            Name = 'Test Engagement US Onsite',
            Account__c = financialAccount.Id,
            State_pl__c = 'TX',
            Country_pl__c = 'United States',
            RecordTypeId = engRecordTypeId,
            Engagement_Start__c = System.today().addDays(5),
            Engagement_End__c = System.today().addDays(10),
           // Course__c  = course.Id, 
            Status__c = 'Firm',
            Location_Times__c = 'These are the Location Times',
            Campus_Room__c = '4th Floor - DAB',
            Class_Requirements__c = 'These are the Class Requirements',
            Travel_Lodging_Instructions__c = 'These are the Travel Lodging Instructions',
            Homework__c = 'These are the Homework instructions'
        );
        insert(engagement);
      
        // Need this RecordType to get access to the 'Registration Confirmed' Attendance Status value.
        String engAttendeeRecordTypeId = Schema.SObjectType.Engagement_Attendee__c.getRecordTypeInfosByName().get('Institute - Paid Seat').getRecordTypeId();
        
        Engagement_Attendee__c attendee = new Engagement_Attendee__c(
            Name = 'Test Attendee',
            Account__c = financialAccount.Id,
            Attendance_Status__c = 'Attended',
            Engagement__c = engagement.Id,
            RecordTypeId = engAttendeeRecordTypeId,
            Contact__r = contact,
            Contact_Email__c = contact.Email,
            Financial_Data_Account__c = financialAccount.Id,
            Financial_Data_Number__c = 'FD1232',
            Financial_Data_Notes__c = 'Test Notes',
            Registration_Received__c = System.today()
        );
        insert(attendee);
        
        ContentVersion contentVersionWelcomeLetter = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Title = 'NCM Welcome Letter 3 7 23' LIMIT 1];       
        ContentVersion contentVersionEmailLogo = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Title = 'NCM_Email_Logo' LIMIT 1];
       
        List<ContentDocumentLink> contentDocumentList = new List<ContentDocumentLink>();                                                                     
        ContentDocumentLink welcomeLink = new ContentDocumentLink(
        	ContentDocumentId = contentVersionWelcomeLetter.ContentDocumentId,
            LinkedEntityId = engagement.Id,  
            ShareType = 'V', 
            Visibility = 'AllUsers'
        );
        contentDocumentList.add(welcomeLink);
        
        ContentDocumentLink logoLink = new ContentDocumentLink(
        	ContentDocumentId = contentVersionEmailLogo.ContentDocumentId,
            LinkedEntityId = engagement.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        contentDocumentList.add(logoLink); 
        insert(contentDocumentList); 
        
        Test.startTest();   
        	 attendee.Attendance_Status__c = 'Registration Confirmed';
        	 update(attendee);
        Test.stopTest();
      
    }
    
     // test covers EngagmentAttendeeService.cls, and EngagementInstituteWelcomeEmailsBatch.cls
    @isTest
    static void sendWelcomeEmailOffsite() {

        Account financialAccount = [Select Id, name From Account Where Name = 'Test Financial Account'];
        Contact contact = [Select Id, FirstName, Email From Contact Where FirstName = 'FirstName'];
		//Course__c course = [Select Id, Name From Course__c Where Name =  'Test Course']; // Causes 101 Error. Really not needed. 
        
        String engRecordTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('NCM Institute Class - Offsite').getRecordTypeId();
        
        Engagement__c engagement = new Engagement__c(
            Name = 'Test Engagement US Onsite',
            Account__c = financialAccount.Id,
            State_pl__c = 'TX',
            Country_pl__c = 'United States',
            RecordTypeId = engRecordTypeId,
            Engagement_Start__c = System.today().addDays(5),
            Engagement_End__c = System.today().addDays(10),
         ///   Course__c  = course.Id, 
            Status__c = 'Firm',
            Location_Times__c = 'These are the Location Times',
            Campus_Room__c = 'Offsite',
            Class_Requirements__c = 'These are the Class Requirements',
            Travel_Lodging_Instructions__c = 'These are the Travel Lodging Instructions',
            Homework__c = 'These are the Homework instructions'
        );
        insert(engagement);
      
        // Need this RecordType to get access to the 'Registration Confirmed' Attendance Status value.
        String engAttendeeRecordTypeId = Schema.SObjectType.Engagement_Attendee__c.getRecordTypeInfosByName().get('Institute - Paid Seat').getRecordTypeId();
        
        Engagement_Attendee__c attendee = new Engagement_Attendee__c(
            Name = 'Test Attendee',
            Account__c = financialAccount.Id,
            Attendance_Status__c = 'Tentative',
            Engagement__c = engagement.Id,
            RecordTypeId = engAttendeeRecordTypeId,
            Contact__r = contact,
            Contact_Email__c = contact.Email,
            Financial_Data_Account__c = financialAccount.Id,
            Financial_Data_Number__c = 'FD1232',
            Financial_Data_Notes__c = 'Test Notes',
            Registration_Received__c = System.today()
        );
        insert(attendee);
        
        ContentVersion contentVersionWelcomeLetter = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Title = 'NCM Welcome Letter 3 7 23' LIMIT 1];       
        ContentVersion contentVersionEmailLogo = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Title = 'NCM_Email_Logo' LIMIT 1];
        
        List<ContentDocumentLink> contentDocumentList = new List<ContentDocumentLink>();                                                                     
        ContentDocumentLink welcomeLink = new ContentDocumentLink(
        	ContentDocumentId = contentVersionWelcomeLetter.ContentDocumentId,
            LinkedEntityId = engagement.Id,  
            ShareType = 'V', 
            Visibility = 'AllUsers'
        );
        contentDocumentList.add(welcomeLink);
        
        ContentDocumentLink logoLink = new ContentDocumentLink(
        	ContentDocumentId = contentVersionEmailLogo.ContentDocumentId,
            LinkedEntityId = engagement.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        contentDocumentList.add(logoLink); 
        insert(contentDocumentList);

        Test.startTest();  
        	 attendee.Attendance_Status__c = 'Registration Confirmed';
        	 update(attendee);
        Test.stopTest();
      
    }

    // test covers EngagmentAttendeeService.cls, and EngagementInstituteWelcomeEmailsBatch.cls
    @isTest
    static void sendWelcomeEmailOffsiteOnInsert() {

        Account financialAccount = [Select Id, name From Account Where Name = 'Test Financial Account'];
        Contact contact = [Select Id, FirstName, Email From Contact Where FirstName = 'FirstName'];
		//Course__c course = [Select Id, Name From Course__c Where Name =  'Test Course'];
        
        String engRecordTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('NCM Institute Class - Offsite').getRecordTypeId();
        
        Engagement__c engagement = new Engagement__c(
            Name = 'Test Engagement US Onsite',
            Account__c = financialAccount.Id,
            State_pl__c = 'TX',
            Country_pl__c = 'United States',
            RecordTypeId = engRecordTypeId,
            Engagement_Start__c = System.today().addDays(5),
            Engagement_End__c = System.today().addDays(10),
          //  Course__c  = course.Id, 
            Status__c = 'Firm',
            Location_Times__c = 'These are the Location Times',
            Campus_Room__c = 'Offsite',
            Class_Requirements__c = 'These are the Class Requirements',
            Travel_Lodging_Instructions__c = 'These are the Travel Lodging Instructions',
            Homework__c = 'These are the Homework instructions'
        );
        insert(engagement);
        
        ContentVersion contentVersionWelcomeLetter = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Title = 'NCM Welcome Letter 3 7 23' LIMIT 1];       
        ContentVersion contentVersionEmailLogo = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Title = 'NCM_Email_Logo' LIMIT 1];
       
        List<ContentDocumentLink> contentDocumentList = new List<ContentDocumentLink>();                                                                     
        ContentDocumentLink welcomeLink = new ContentDocumentLink(
        	ContentDocumentId = contentVersionWelcomeLetter.ContentDocumentId,
            LinkedEntityId = engagement.Id,  
            ShareType = 'V', 
            Visibility = 'AllUsers'
        );
        contentDocumentList.add(welcomeLink);
        
        ContentDocumentLink logoLink = new ContentDocumentLink(
        	ContentDocumentId = contentVersionEmailLogo.ContentDocumentId,
            LinkedEntityId = engagement.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        contentDocumentList.add(logoLink); 
        insert(contentDocumentList);
      
        // Need this RecordType to get access to the 'Registration Confirmed' Attendance Status value.
        String engAttendeeRecordTypeId = Schema.SObjectType.Engagement_Attendee__c.getRecordTypeInfosByName().get('Institute - Paid Seat').getRecordTypeId();
        
        Engagement_Attendee__c attendee = new Engagement_Attendee__c(
            Name = 'Test Attendee',
            Account__c = financialAccount.Id,
            Attendance_Status__c = 'Registration Confirmed',
            Engagement__c = engagement.Id,
            RecordTypeId = engAttendeeRecordTypeId,
            Contact__r = contact,
            Contact_Email__c = contact.Email,
            Financial_Data_Account__c = financialAccount.Id,
            Financial_Data_Number__c = 'FD1232',
            Financial_Data_Notes__c = 'Test Notes',
            Registration_Received__c = System.today()
        );
        
        Test.startTest();  
        	attendee.Attendance_Status__c = 'Registration Confirmed';
        	insert(attendee);
        Test.stopTest();
          
    }
    
    @isTest
    static void attendeeTypeHasChanged(){
        List<Engagement__c> testEngagements = [SELECT ID, Engagement_Number__c FROM Engagement__c ];
        String attendeeRecType = Schema.SObjectType.Engagement_Attendee__c.getRecordTypeInfosByName().get('Institute - Training Subscription Seats').getRecordTypeId();
        Contact c = [SELECT Id, Name, Email, AccountId FROM Contact LIMIT 1];
        Engagement_Attendee__c testAttendee = new Engagement_Attendee__c(
            RecordTypeId = attendeeRecType,
            Contact__c = c.Id,
            Account__c = c.AccountId,
            Age_Group__c = 'Adult',
            Attendance_Status__c = 'Attended',
            Attendee_Type__c = 'Member',
            Engagement__c = testEngagements[0].Id
        ); 
        insert(testAttendee);

        Test.startTest();
            testAttendee.Attendee_Type__c = 'Instructor';
            update(testAttendee);
        Test.stopTest();

        Engagement_Attendee__c attResult = [select id, name, Attendee_Type__c, Attendee_No__c, Attendee_Code__c FROM Engagement_Attendee__c WHERE  ID = :testAttendee.Id];
        String attName = c.Name;
        attName += ' (' + String.valueOf(attResult.Attendee_Type__c) + ') - ' + attResult.Attendee_Code__c;
        System.debug('AttendeeName: ' + attName + ' attResult.Name: ' + attResult.Name);
		
        // Check to see if Attendee Name was updated after the Attendee Type was changed. 
        Assert.areEqual(attName, attResult.Name); 

    }
    
    @isTest
    static void attendeeNameHasChanged(){
        List<Engagement__c> testEngagements = [SELECT ID, Engagement_Number__c FROM Engagement__c ];
        String attendeeRecType = Schema.SObjectType.Engagement_Attendee__c.getRecordTypeInfosByName().get('Institute - Training Subscription Seats').getRecordTypeId();
        Contact c = [SELECT Id, Name, Email, AccountId FROM Contact LIMIT 1];
        Engagement_Attendee__c testAttendee = new Engagement_Attendee__c(
            RecordTypeId = attendeeRecType,
            Contact__c = c.Id,
            Account__c = c.AccountId,
            Age_Group__c = 'Adult',
            Attendance_Status__c = 'Attended',
            Attendee_Type__c = 'Member',
            Engagement__c = testEngagements[0].Id
        ); 
        insert(testAttendee);
	
        Test.startTest();
            testAttendee.Name = 'Tom';
            update(testAttendee);
        Test.stopTest();

        Engagement_Attendee__c attResult = [select id, name, Attendee_Type__c, Attendee_No__c, Attendee_Code__c FROM Engagement_Attendee__c WHERE  ID = :testAttendee.Id];
        String attName = c.Name;
        attName += ' (' + String.valueOf(attResult.Attendee_Type__c) + ') - ' + attResult.Attendee_Code__c;
        System.debug('AttendeeName: ' + attName + ' attResult.Name: ' + attResult.Name);
		
        // Check to see if Attendee Name was updated after the Attendee Name was changed. 
        Assert.areEqual(attName, attResult.Name); 

    }
    
}