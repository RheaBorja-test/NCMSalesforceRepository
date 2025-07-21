@isTest
public class EngRostPortalServiceTests {
    
    @TestSetup
    static void makeData(){

        // Create Accounts and 20G Members
        SampleDataFactory.create20GroupAccountData();
        String twentyGroupId = [SELECT Id FROM Twenty_Groups__c LIMIT 1].Id;
        String ncmAssocRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('NCM Associates').getRecordTypeId();
        String ncmBillingContactId = [SELECT Id FROM Contact WHERE RecordTypeId = :ncmAssocRecTypeId LIMIT 1].Id;
        
        // Create Engagement data
        Engagement__c testEngagement = SampleDataFactory.createEngagement_20G(
            twentyGroupId,
            Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('Retail Solutions').getRecordTypeId(),
            ncmBillingContactId
        ); 


        // Create Engagement Activities
        Engagement_Activity__c testActivity = new Engagement_Activity__c(
            Engagement__c = testEngagement.Id,
            Name = 'Dinner Reception',
            RecordTypeId = Schema.SObjectType.Engagement_Activity__c.getRecordTypeInfosByName().get('Engagement Activity').getRecordTypeId()
        );
        insert(testActivity);


        // Create Activity Participation records
        List<Activity_Participation__c> apList = new List<Activity_Participation__c>();
        for(Engagement_Attendee__c att:[SELECT Id FROM Engagement_Attendee__c]){
            Activity_Participation__c ap = new Activity_Participation__c(
              Engagement__c = testEngagement.Id,
              Engagement_Attendee__c = att.Id,
              Engagement_Activity__c = testActivity.Id  
            );
            apList.add(ap);
        }
        insert(apList);
    }


    @isTest
    static void rosterTest(){
      
        String engagementId = [SELECT Id FROM Engagement__c LIMIT 1].Id;

        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.requestURI =  URL.getOrgDomainUrl() + '/services/apexrest/EngRostPortalAPI/' + engagementId;
        RestContext.request = req;

        EngagementRosterModel.EngagementRosterResponse apiResponse;
        

        Test.startTest();
            apiResponse = EngRostPortalService.getEngRostPortal();
        Test.stopTest();

        System.assertNotEquals('500', apiResponse.statusCode);
        System.assertNotEquals(null, apiResponse.engagement);
        System.assertNotEquals(null, apiResponse.engagement.attendees);


    }


    @isTest
    static void cancelledAttendeesAreExcludedTest(){
        
        String engagementId = [SELECT Id, Engagement__c FROM Engagement_Attendee__c LIMIT 1].Engagement__c;
        List<Engagement_Attendee__c> attendeeList = [select id, Attendance_Status__c from Engagement_Attendee__c where Engagement__c = :engagementId];
        System.assertNotEquals(0, attendeeList.size());

        Engagement_Attendee__c testAtt = attendeeList[0];
        testAtt.Attendance_Status__c = 'Cancelled';
        update(testAtt);

        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.requestURI =  URL.getOrgDomainUrl() + '/services/apexrest/EngRostPortalAPI/' + engagementId;
        RestContext.request = req;

        EngagementRosterModel.EngagementRosterResponse apiResponse;
        

        Test.startTest();
            apiResponse = EngRostPortalService.getEngRostPortal();
        Test.stopTest();

        System.assertNotEquals('500', apiResponse.statusCode);
        System.assertNotEquals(null, apiResponse.engagement);
        System.assertNotEquals(null, apiResponse.engagement.attendees);
        // Important test for this check
        System.assertEquals(attendeeList.size() - 1, apiResponse.engagement.attendees.size()); // The results should not include the cancelled attendee.

    }

    @isTest
    static void rosterWithNoResultTest(){
      
        String engagementId = 'abc123'; // This is not a valid Engagement ID so we should get a 500 response.

        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.requestURI =  URL.getOrgDomainUrl() + '/services/apexrest/EngRostPortalAPI/' + engagementId;
        RestContext.request = req;

        EngagementRosterModel.EngagementRosterResponse apiResponse;
        

        Test.startTest();
            apiResponse = EngRostPortalService.getEngRostPortal();
        Test.stopTest();

        System.assertEquals('500', apiResponse.statusCode);
        System.assertEquals(null, apiResponse.engagement);

    }


}