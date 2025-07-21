// SampleDataFactory.createData(); Derrick - DO NOT USE createData UNLESS ABSOLUTELY NECESSARY! 
// SampleDataFactory.create20GroupAccountData(); TRY USING THIS METHOD FIRST TO HELP SOQL 101 FAILURES - 5.13.24
// 1396 UAT Test Failures Derrick - 5.14.24
@isTest
public class EngagementAttendeeNotes_Tests {

    @testSetup
    private static void setupData() {
         
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
    static void engagementNotesTest_2(){

       Engagement__c testEngagement = [SELECT Id FROM Engagement__c LIMIT 1];
       ApexPages.StandardController stdController = new ApexPages.StandardController(testEngagement);
       EngagementAttendeeNotes vfCon = new EngagementAttendeeNotes(stdController);
       List<Engagement_Attendee__c> attendeeResults;
        
       Test.startTest();
       		attendeeResults = vfCon.getRelatedAttendees();
       Test.stopTest();
        
       System.debug('TEST ASSERT: ENGAGEMENT_ATTENDEE_NOTES: Engagement_Attendee_Size: ' + attendeeResults.size());
       Assert.areEqual(4, attendeeResults.size());
       
       String testDate = vfcon.engagementStartEndDate;   
    }
} // End of class