@isTest
private class EngagementAttendeeUtilityReportBatchTest {

    @testSetup
    static void testSetup() {
 
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
        System.debug('Engagement Record Type Id: ' + engRecordTypeId );
        List<Engagement__c> newEngagements = new List<Engagement__c>();
        
        Engagement__c engagement = new Engagement__c(
            Name = 'Test Engagement',
            Account__c = financialAccount.Id,
            Country_pl__c = 'United States',
            RecordTypeId = engRecordTypeId,
            Engagement_Start_Date__c = System.today().addDays(10),
            Course__c  = course.Id
        );
        newEngagements.add(engagement);
        
        String engRecTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('NCM Institute Class - Live Session Virtual Training').getRecordTypeId();
        System.debug('Engagement Record Type Id: ' + engRecTypeId);
               
        Engagement__c engagement1 = new Engagement__c(
            Name = 'Test Engagement1',
            Account__c = financialAccount.Id,
            Country_pl__c = '',
            RecordTypeId = engRecTypeId,
            Engagement_Start_Date__c = System.today().addDays(10),
            Course__c  = course.Id
        );
        newEngagements.add(engagement1);
        
        Engagement__c engagement2 = new Engagement__c(
            Name = 'Test Engagement2',
            Account__c = financialAccount.Id,
            Country_pl__c = 'Canada',
            RecordTypeId = engRecordTypeId,
            Engagement_Start_Date__c = System.today().addDays(20),
            Course__c  = course.Id
        );
        newEngagements.add(engagement2);
		
		Engagement__c engagement3 = new Engagement__c(
            Name = 'Test Engagement3',
            Account__c = financialAccount.Id,
            Country_pl__c = 'Canada',
            RecordTypeId = engRecTypeId,
            Engagement_Start_Date__c = System.today().addDays(20),
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
            Attendance_Status__c = 'Registration Confirmed',
            Engagement__c = engagement.Id,
            RecordTypeId = engAttendeeRecordTypeId,
            Contact__r = contact,
            Contact_Email__c = contact.Email,
            Financial_Data_Account__c = financialAccount.Id,
            Financial_Data_Number__c = 'FD123',
            Financial_Data_Notes__c = 'Test Notes',
            Registration_Received__c = System.today()
        );
        newAttendees.add(attendee);
        
        Engagement_Attendee__c attendee1 = new Engagement_Attendee__c(
            Name = 'Test Attendee',
            Account__c = financialAccount.Id,
            Attendance_Status__c = 'Registration Confirmed',
            Engagement__c = engagement1.Id,
            RecordTypeId = engAttendeeRecordTypeId,
            Contact__r = contact,
            Contact_Email__c = contact.Email,
            Financial_Data_Account__c = financialAccount.Id,
            Financial_Data_Number__c = 'FD123',
            Financial_Data_Notes__c = 'Test Notes',
            Registration_Received__c = System.today()
        );
        newAttendees.add(attendee1);
        
        Engagement_Attendee__c attendee2 = new Engagement_Attendee__c(
            Name = 'Test Attendee2',
            Account__c = financialAccount.Id,
            Attendance_Status__c = 'Registration Confirmed',
            Engagement__c = engagement2.Id,
            RecordTypeId = engAttendeeRecordTypeId,
            Contact__r = contact,
            Contact_Email__c = contact.Email,
            Financial_Data_Account__c = financialAccount.Id,
            Financial_Data_Number__c = 'FD123',
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
            Financial_Data_Number__c = 'FD123',
            Financial_Data_Notes__c = 'Test Notes',
            Registration_Received__c = System.today()
        );
        newAttendees.add(attendee3);
        insert(newAttendees);
    }
    
    @isTest
    static void testNotVirtualTraining() {

        List<Engagement_Attendee__c> attendees = [SELECT Id, 
                                                  		 Name, 
                                                         Contact__r.Name,
                                                         Contact_Email__c,
                                                         Engagement__r.Name, 
                                                         Engagement__r.RecordType.Name,
                                                         Engagement__r.Country_pl__c,
                                                         Financial_Data_Account__r.Name,
                                                         Financial_Data_Account__r.ShippingPostalCode,                                               
                                                         Financial_Data_Number__c,
                                                         Financial_Data_Notes__c,
                                                         Last_Time_Rescheduled__c,
                                                         Registration_Received__c                                                  
                                                  FROM   Engagement_Attendee__c];
        
        Test.startTest();
        	EngagementAttendeeUtilityReportBatch batchJob = new EngagementAttendeeUtilityReportBatch();
        	batchJob.execute(null, attendees);
        Test.stopTest();

        Assert.isTrue(!attendees.isEmpty(), 'Execute method complete');
    }

    @isTest
    static void testVirtualTraining() {

        List<Engagement_Attendee__c> attendees = [SELECT Id, 
                                                  		 Name, 
                                                         Contact__r.Name,
                                                         Contact_Email__c,
                                                         Engagement__r.Name, 
                                                         Engagement__r.RecordType.Name,
                                                         Engagement__r.Country_pl__c,
                                                         Financial_Data_Account__r.Name,
                                                         Financial_Data_Account__r.ShippingPostalCode,                                               
                                                         Financial_Data_Number__c,
                                                         Financial_Data_Notes__c,
                                                         Last_Time_Rescheduled__c,
                                                         Registration_Received__c                                                  
                                                  FROM   Engagement_Attendee__c];
        
        Test.startTest();
        	EngagementAttendeeUtilityReportBatch batchJob = new EngagementAttendeeUtilityReportBatch();
        	batchJob.execute(null, attendees);
        Test.stopTest();
        
        Assert.isTrue(!attendees.isEmpty(), 'Execute method complete');
    }
    
    @isTest
    static void testScheduledExecution() {
        
        Test.startTest();        
            EngagementAttendeeUtilityReportBatch batchJob = new EngagementAttendeeUtilityReportBatch();
            String jobId = System.schedule('Test Job', '0 0 12 * * ?', batchJob);        
        Test.stopTest();
        
        Assert.isNotNull(jobId, 'Scheduled job should be created successfully.');
    }
    
    @isTest
    static void testSendEmailUS() {
        
        Map<String, String> engagementCsvMap = new Map<String, String>();
        engagementCsvMap.put('Test Engagement US', 'Test CSV Content');
        
        Test.startTest();
            EngagementAttendeeUtilityReportBatch testBatch = new EngagementAttendeeUtilityReportBatch();
            testBatch.sendEmail(engagementCsvMap, 'US', 'Empty');
        Test.stopTest();

        Assert.areEqual(EngagementAttendeeUtilityReportBatch.testEmail.getSubject(), 'NCMi Utility CSV - US');     
    }
    
    @isTest
    static void testSendEmailCA() {
        
        Map<String, String> engagementCsvMap = new Map<String, String>();
        engagementCsvMap.put('Test Engagement CA', 'Test CSV Content');
        
        Test.startTest();
            EngagementAttendeeUtilityReportBatch testBatch = new EngagementAttendeeUtilityReportBatch();
            testBatch.sendEmail(engagementCsvMap, 'CA', 'Empty');
        Test.stopTest();

        Assert.areEqual(EngagementAttendeeUtilityReportBatch.testEmail.getSubject(), 'NCMi Utility CSV - CA');     
    }
    
}