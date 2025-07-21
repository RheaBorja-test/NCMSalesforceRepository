@isTest
public class PropGroupControllerTest {
   
    @TestSetup
    static void testSetup() {

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
		
        // This section is needed to get past the Contact on Edit/Create Process Builders. 
        List<User> ncmUsers = new List<User>();
        Profile coordinatorProfile = [SELECT Id FROM Profile WHERE Name = 'NCM Coordinator'];                
        User ncmUser = new user(
            ProfileID = coordinatorProfile.Id,
            Username = 'bbillings@ncm.com',
            FirstName = 'Barney',
            LastName = 'Billings',
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
        ncmUsers.add(ncmUser);
            
        User ncmUser2 = new user(
            ProfileID = coordinatorProfile.Id,
            Username = 'tChavez@ncm.com',
            FirstName = 'Tommy',
            LastName = 'Chavez',
            Initials__c = 'TLC',
            Email = 'tChavez@ncmassociates.com',
            Street = '4717 Grand Ave., Ste 500',
            City = 'Kansas City',
            State = 'Missouri',
            PostalCode = '64112',
            Alias = 'test457',
            CommunityNickname = 'test457',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8'
        );
        ncmUsers.add(ncmUser2);
        insert(ncmUsers);

        /* NCM Contacts (Need atleast two)*/
        List<Contact> ncmContacts = new List<Contact>();
        Contact ncmContact = new Contact(
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
        ncmContacts.add(ncmContact);
        
        // Has Nickname
        Contact ncmContact2 = new Contact(
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('NCM Associates').getRecordTypeId(),
            AccountId = ncmAccount.Id,
            User_ID__c = ncmUser2.Id,
            FirstName = 'Tommy',
            Lastname = 'Chavez',
            Email = 'tommy.chavez@ncmassociates.com',
            MailingStreet = '4717 Grand Ave., Ste 500',
            MailingCity = 'Kansas City',
            MailingState = 'Missouri',
            MailingPostalCode = '64112', 
            Nickname__c = 'Tommynickname', 
            Title = 'Manager'          
        );
        ncmContacts.add(ncmContact2);
        insert(ncmContacts);

        String propGroupRecordTypeId = Schema.SObjectType.Proprietary_Group__c.getRecordTypeInfosByName().get('Quarterly').getRecordTypeId();
        // Create Prop Group where ncmContact is the orignal Group Owner.
        Proprietary_Group__c testPropGroup = new Proprietary_Group__c(
            RecordTypeId = propGroupRecordTypeId,
            Name = 'Central Auto Group - Proprietary Group',
            Group_Name__c = 'Central Auto Group - Proprietary Group',
            Group_Number__c = '8888',
            Group_Owner__c = ncmContact.Id, 
            Meetings_per_Year__c = 4,
            Account__c = ncmAccount.Id,
            Billing_Frequency__c = 'Quarterly',
            Contact__c = ncmContact.Id,
            Street__c = ncmAccount.BillingStreet,
            City__c = ncmAccount.BillingCity,
            State__c = ncmAccount.BillingState,
            Postal_Code__c = ncmAccount.BillingPostalCode,
            Rate_Type__c = 'Monthly Rate Schedule'
        );
        insert(testPropGroup);
      
        String retailEngagementRecType = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('Retail Solutions').getRecordTypeId();
        List<Engagement__c> newEngagements = new List<Engagement__c>();
        
        Engagement__c testEngagement = new Engagement__c(
            RecordTypeId = retailEngagementRecType,
            Name = 'Sample Engagement 1',
            Proprietary_Group__c = testPropGroup.Id,
            Account__c = ncmAccount.Id,
            Status__c = 'Tentative',
            Engagement_Type__c = '20 Group',
            Engagement_Description__c = 'Regular',
            Engagement_Owner__c = ncmContact.Id,
            City__c = 'Dallas',
            State_pl__c = 'TX',
            Country_pl__c = 'United States',
            Engagement_Start_Date__c = System.today().addDays(10),
            Engagement_Start__c = System.today().addDays(10), 
            Engagement_End__c = System.today().addDays(20)
        );
        newEngagements.add(testEngagement);   
        insert(newEngagements);

        String engAttendeeRecordTypeId = Schema.SObjectType.Engagement_Attendee__c.getRecordTypeInfosByName().get('Institute - Training Subscription Seats').getRecordTypeId();
        
        Engagement_Attendee__c attendee = new Engagement_Attendee__c(
            Name = 'Test Attendee',
            Account__c = ncmAccount.Id,
            Attendance_Status__c = 'Pending Class',
            Attendee_Type__c = 'Moderator',
            Engagement__c = testEngagement.Id,
            RecordTypeId = engAttendeeRecordTypeId,
            Contact__c = ncmContact.Id,
            Contact_Email__c = ncmContact.Email,
            Financial_Data_Account__c = ncmAccount.Id,
            Financial_Data_Number__c = 'FD1232',
            Financial_Data_Notes__c = 'Test Notes',
            Registration_Received__c = System.today()
        );
        insert(attendee);
    }
	
    // When the Group Owner is changed, add them as an Engagement Attendee to all the Engagements that are in the future with
    // the Status of 'Tentative’, 'Firm’, or 'Cancellation Inquiry’.
    // The old Group Owner should have their Engagement Attendee - Attendance Status changed to 'Cancelled'.
    @isTest
    static void groupOwnerChangedTest() {

        List<Contact> contacts = [SELECT Id, FirstName, LastName, Nickname__c FROM Contact ORDER BY FirstName];
        Contact oldContact = contacts[0]; // Barney
        Contact newContact = contacts[1]; // Tommy

        // Verify only one Moderator exists, and its assinged to the old Group Owner. 
        List<Engagement_Attendee__c> initialModerators = [
            SELECT Id, Contact__c, Attendance_Status__c FROM Engagement_Attendee__c WHERE Attendee_Type__c = 'Moderator'
        ];
        System.assertEquals(1, initialModerators.size(), 'There should be one initial Moderator.');
        System.assertEquals(oldContact.Id, initialModerators[0].Contact__c, 'Initial Moderator should be the old Group Owner.');

        // Update the Group Owner to the new contact
        Proprietary_Group__c propGroup = [SELECT Id, Group_Owner__c FROM Proprietary_Group__c WHERE Group_Owner__c = :oldContact.Id LIMIT 1];
        propGroup.Group_Owner__c = newContact.Id;

        Test.startTest();
            update propGroup;
        Test.stopTest();
        
        // The old one should have Attendance Status = 'Cancelled'.
        Engagement_Attendee__c cancelledAttendee = [
            SELECT Id, Contact__c, Engagement__c, Attendance_Status__c
            FROM Engagement_Attendee__c
            WHERE Contact__c =:oldContact.Id AND Attendee_Type__c = 'Moderator'LIMIT 1
        ];
        
        System.debug('Check the cancelledAttendee Attendance Status. It should be set to "Cancelled" ' + cancelledAttendee.Attendance_Status__c);
        System.assertEquals('Cancelled', cancelledAttendee.Attendance_Status__c, 'The old Group Owner/Engagement Attendee Attendance Status should be Cancelled');
        
    }
    
    // Added more Asserts to verify Collateral Name, Arrival, and Departure Dates on the newly created Attendee. 
    @isTest
    static void checkEngagementAttendeeFieldsTest() {

        List<Contact> contacts = [SELECT Id, FirstName, LastName, Nickname__c FROM Contact ORDER BY FirstName];
        Contact oldContact = contacts[0]; // Barney
        Contact newContact = contacts[1]; // Tommy 

        // Update the Group Owner to the new contact
        Proprietary_Group__c propGroup = [SELECT Id, Group_Owner__c FROM Proprietary_Group__c WHERE Group_Owner__c = :oldContact.Id LIMIT 1];
        propGroup.Group_Owner__c = newContact.Id;

        Test.startTest();
            update propGroup;
        Test.stopTest();

        // Check that the Moderator now reflects the new Group Owner
        Engagement_Attendee__c updatedModerator = [
            SELECT Id, Contact__c, Contact__r.Nickname__c, Contact__r.LastName, Collateral_Name__c, Engagement__c, 
                   Arrival__c, Departure__c, Engagement__r.Engagement_Start__c, Engagement__r.Engagement_End__c 
            FROM Engagement_Attendee__c 
            WHERE Contact__c =:newContact.Id AND Attendee_Type__c = 'Moderator'LIMIT 1
        ];
        
        // Verify the new Engagement Attendee fields match for ticket SALES - 2060. 
        System.assertEquals(updatedModerator.Collateral_Name__c, updatedModerator.Contact__r.Nickname__c + ' ' + updatedModerator.Contact__r.LastName, 'Check Collateral Name');
        System.assertEquals(updatedModerator.Engagement__r.Engagement_Start__c.addDays(-1), updatedModerator.Arrival__c, 'The new Attendee Arrival Date should be the day prior of the Engagement Start Date.');
        System.assertEquals(updatedModerator.Engagement__r.Engagement_End__c, updatedModerator.Departure__c, 'The new Attendee Departure__c Date should be the day of the Engagement End Date.');
    }

}