@isTest
public class RoomBlockSurveyRequestTest {

    // X20_Group_Member_Contact__c
    @isTest
    static void sendTwentyGroupSurveyTest() {

        // Identify the mock class to use for the WorkatoAPI callout
        Test.setMock(HttpCalloutMock.class, new WorkatoMock());

        // Test setup data.
        SampleDataFactory.create20GroupAccountData();
        Id twentyGroupId = [SELECT Id, Name, NCM_Proprietor__c FROM Twenty_Groups__c LIMIT 1].Id;
        Id engagementRecTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('Retail Solutions').getRecordTypeId(); 
        Id ncmBillingContactId = [SELECT Id FROM Contact WHERE recordtype.name = 'NCM Associates' LIMIT 1].Id;  
        SampleDataFactory.createEngagement_20G(twentyGroupId, engagementRecTypeId, ncmBillingContactId); 
        List<Engagement__c> testEngagement_x20Group = [SELECT Id, Name FROM Engagement__c LIMIT 1];
        List<String> engagementIds = new List<String> {testEngagement_x20Group[0].Id};

        // Execute the sendRoomBlockSurvey() method.
        Test.startTest();
            RoomBlockSurveyRequest.sendRoomBlockSurvey(engagementIds); 
        Test.stopTest();

        // Verify RBS records are created for each contact sent an email.
        String contactRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId();
        List<Contact> testContacts = [SELECT id, name FROM Contact WHERE RecordTypeId = :contactRecTypeId]; // Use this list to verify the number of people added to the RBS list.
        List<Room_Block_Survey_Response__c> rbsResults = [select id, X20_Group_Member_Contact__c FROM Room_Block_Survey_Response__c WHERE Engagement__c = :testEngagement_x20Group[0].Id];
        Assert.areEqual(testContacts.size(), rbsResults.size());
                
    } 
    
    @isTest     
    static void getEngagegmentFor_propGoup() {

        // Identify the mock class to use for the WorkatoAPI callout
        Test.setMock(HttpCalloutMock.class, new WorkatoMock());

        // Test setup data.
        SampleDataFactory.createPropGroupData();
        Id propGroupId = [SELECT Id, Name FROM Proprietary_Group__c LIMIT 1].Id;
        Id engagementRecTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('Retail Solutions').getRecordTypeId(); 
        Id ncmBillingContactId = [SELECT Id FROM Contact WHERE recordtype.name = 'NCM Associates' LIMIT 1].Id;  
        SampleDataFactory.createEngagement_Prop(propGroupId, engagementRecTypeId, ncmBillingContactId); 
        List<Engagement__c> testEngagement_x20Group = [SELECT Id, Name FROM Engagement__c LIMIT 1];
        List<String> engagementIds = new List<String> {testEngagement_x20Group[0].Id};

        // Execute the sendRoomBlockSurvey() method.
        Test.startTest();
             RoomBlockSurveyRequest.sendRoomBlockSurvey(engagementIds);
        Test.stopTest();

        // Verify RBS records are created for each contact sent an email.
        String contactRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId();
        List<Contact> testContacts = [SELECT id, name FROM Contact WHERE RecordTypeId = :contactRecTypeId]; // Use this list to verify the number of people added to the RBS list.
        List<Room_Block_Survey_Response__c> rbsResults = [select id, Proprietary_Account_Contact__c FROM Room_Block_Survey_Response__c WHERE Engagement__c = :testEngagement_x20Group[0].Id];
        Assert.areEqual(testContacts.size(), rbsResults.size());

    } 

    // X20_Group_Member_Contact__c Emails
    @isTest
    static void x20GroupMemberContactEmail() {

        // Identify the mock class to use for the WorkatoAPI callout
        Test.setMock(HttpCalloutMock.class, new WorkatoMock());

        // Test setup data.
        SampleDataFactory.create20GroupAccountData();
        Id twentyGroupId = [SELECT Id, Name, NCM_Proprietor__c FROM Twenty_Groups__c LIMIT 1].Id; 
        Id engagementRecTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('Retail Solutions').getRecordTypeId(); 
        Id ncmBillingContactId = [SELECT Id FROM Contact WHERE recordtype.name = 'NCM Associates' LIMIT 1].Id;  
        SampleDataFactory.createEngagement_20G(twentyGroupId, engagementRecTypeId, ncmBillingContactId); 

        System.debug('Inside RoomBlockSurveyRequestTest: x20GroupMemberContactEmail');
        
        // Get Engagement. Query from SampleDataFactory. 
        List<Engagement__c> testEngagement_propGroup = [SELECT Id, Name FROM Engagement__c LIMIT 1];
        List<String> engagementIds = new List<String> {testEngagement_propGroup[0].Id};

        System.debug('Test getEngagegmentFor_propGoup EngagementIds: ' + engagementIds);
        //System.debug('Test Engagement Prop Group: ' + testEngagement_propGroup[0].Id);
        
        // Call the Invocable Method
        Test.startTest();
                RoomBlockSurveyRequest.sendRoomBlockSurvey(engagementIds);  
        Test.stopTest();
        
        // query for roomblockservice records
    } 
    
} // End of test class