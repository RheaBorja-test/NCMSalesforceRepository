/* SALES 1185 - Create Unit Test for EngagementManagement.cls
*  Derrick Chavez; 12.20.2023
*/
@isTest
public class EngagementManagementTest {
    
    @TestSetup
    static void makeData() {

        System.debug('Inside EngagementManagementTest.TestSetup');

        SampleDataFactory.create20GroupAccountData();
    
        // Query for the Twenty Group created by SampleDataFactory.
        Twenty_Groups__c test20Group = [SELECT Id, Name, NCM_Proprietor__c FROM Twenty_Groups__c LIMIT 1];
        Id twentyGroupId = test20Group.Id;

        // Query for the record that was created on  line 8 for the Billing NCM Billing Contact Id.
        Id ncmBillingContactId = test20Group.NCM_Proprietor__c;

        // Get the Engagement Record Type for Retail Solutions.
        Id engagementRecTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('Retail Solutions').getRecordTypeId();
        
        // Call the method from SampleDataFactory and pass in values created above. 
        SampleDataFactory.createEngagement_20G(twentyGroupId, engagementRecTypeId, ncmBillingContactId); 
              
    } 

    @isTest
    static void getateendeeTest() {

        System.debug('Inside EngagementManagementTest: getateendeeTest');

        // Get Engagment. Query from SampleDataFactory. 
        Engagement__c testEngagement = [SELECT Id, Name FROM Engagement__c LIMIT 1];
        Id engagementId = testEngagement.Id;
       
        // Call the getAttendees method from EngagementManagement class
        List<Engagement_Attendee__c> newAttendees = EngagementManagement.getAttendees(engagementId);
        // System.debug('Inside EngagementManagementTest: getateendeeTest: newAttendees.size(): ' + newAttendees.size()); 

        // Assert the number of Attendees related to the Engagement returns the correct results. 
        System.assertEquals(4, newAttendees.size(), 'List newAttendees size should be 4');
        
    } 

    @isTest
    static void getActivityAttendence() {

        System.debug('Inside EngagementManagementTest: getActivityAttendence()');

        // Get Engagment. Query from SampleDataFactory. 
        Engagement__c testEngagement = [SELECT Id, Name FROM Engagement__c LIMIT 1];
        Id engagementId = testEngagement.Id;

        // Call the getAttendees method from EngagementManagement class
        List<Engagement_Attendee__c> newAttendees = EngagementManagement.getAttendees(engagementId);

        Engagement_Activity__c ea = new Engagement_Activity__c(
            Name = 'Test Activity',
            Engagement__c = engagementId
        );
        insert ea;

        Activity_Participation__c ap = new Activity_Participation__c(
            Engagement_Activity__c = ea.Id, 
            Engagement_Attendee__c = newAttendees[0].Id,
            Engagement__c = engagementId
        );
        insert ap;

        // Call the getActivityAttendance method from the EngagementManagement class and pass in activityId.               
        List<Engagement_Attendee__c> activityAttendence = EngagementManagement.getActivityAttendence(ea.Id);
        // System.debug('Inside EngagementManagementTest: getActivityAttendence() size: ' + activityAttendence.size());
       
        // Assert the number of Attendees related to the Engagement returns the correct results. 
        System.assertEquals(3, activityAttendence.size(), 'List Activity Attendence size should be 3');
        
    }
    
} // End of Test Class