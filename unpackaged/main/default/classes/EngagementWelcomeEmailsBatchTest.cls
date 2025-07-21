@isTest
private class EngagementWelcomeEmailsBatchTest {

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
        
        String offsiteRecordTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('NCM Institute Class - Offsite').getRecordTypeId();
        String onsiteRecordTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('NCM Institute Class - Onsite').getRecordTypeId();
        List<Engagement__c> newEngagements = new List<Engagement__c>();
                
        Engagement__c engagement = new Engagement__c(
            Name = 'Test Engagement',
            Account__c = financialAccount.Id,
            Country_pl__c = 'United States',
            State_pl__c = 'TX',
            RecordTypeId = offsiteRecordTypeId,
            Engagement_Start_Date__c = System.today().addDays(5),
            Engagement_Start__c = System.today().addDays(5),
            Engagement_End_Date__c = System.today().addDays(15),
            Engagement_End__c = System.today().addDays(15),
            Course__c  = course.Id, 
            Status__c = 'Firm',
            Campus_Room__c = 'Offsite',
            Location_Times__c = 'Location_Times__c',
            Class_Requirements__c = 'Class_Requirements__c',
            Travel_Lodging_Instructions__c = 'Travel_Lodging_Instructions__c'
        );
        newEngagements.add(engagement);
                       
        Engagement__c engagement1 = new Engagement__c(
            Name = 'Test Engagement1',
            Account__c = financialAccount.Id,
            Country_pl__c = 'United States',
            State_pl__c = 'TX',
            RecordTypeId = onsiteRecordTypeId,
            Engagement_Start_Date__c = System.today().addDays(5),
            Engagement_Start__c = System.today().addDays(5),
            Engagement_End_Date__c = System.today().addDays(15),
            Engagement_End__c = System.today().addDays(15),
            Course__c  = course.Id,
            Status__c = 'Firm',
            Campus_Room__c = '4th Floor - Central A',
            Location_Times__c = 'Location_Times__c',
            Class_Requirements__c = 'Class_Requirements__c',
            Travel_Lodging_Instructions__c = 'Travel_Lodging_Instructions__c',
            Homework__c = 'Homework__c'
        );
        newEngagements.add(engagement1);
        insert(newEngagements);
        
        // Need this RecordType to get access to the 'Registration Confirmed' Attendance Status value.
        String engAttendeeRecordTypeId = Schema.SObjectType.Engagement_Attendee__c.getRecordTypeInfosByName().get('Institute - Paid Seat').getRecordTypeId();
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
        insert(newAttendees);
        
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
    }
    
    @isTest
    static void testWelcomeEmails() {   
                
        List<Engagement__c> engagements = [SELECT Id, Status__c, RecordType.DeveloperName, Engagement_Start__c, Engagement_End__c, Course__r.Name, Name, Welcome_Email_Sent__c, Homework__c,
                                                  Engagement_Start_Date__c, Engagement_End_Date__c,Location_Times__c, Campus_Room__c, Class_Requirements__c, Travel_Lodging_Instructions__c
                                           FROM Engagement__c];
        
        Test.startTest();
        	EngagementInstituteWelcomeEmailsBatch batchJob = new EngagementInstituteWelcomeEmailsBatch();
        	batchJob.execute(null, engagements);
        Test.stopTest();
        
        Assert.isTrue(!engagements.isEmpty(), 'Execute method complete');
        Engagement__c engagement = [select Id, Name, Welcome_Email_Sent__c From Engagement__c Where Id IN :engagements LIMIT 1 ];        
        System.debug('EngagementWelcomeEmailsBatchTest.testWelcomeEmails:: Welcome_Email_Sent__c: ' + engagement.Welcome_Email_Sent__c);
        // Assert the Welcome Email Sent field is NOT null. 
        System.Assert(engagement.Welcome_Email_Sent__c != null, 'Welcome Email Sent should be populated after batch is processed.');
    }
    
    @isTest
    static void testScheduledExecution() {        
        Test.startTest();        
            EngagementInstituteWelcomeEmailsBatch batchJob = new EngagementInstituteWelcomeEmailsBatch();
            String jobId = System.schedule('Test Job', '0 0 12 * * ?', batchJob);        
        Test.stopTest();     
        
        Assert.isNotNull(jobId, 'Scheduled job should be created successfully.');
    }
    
}