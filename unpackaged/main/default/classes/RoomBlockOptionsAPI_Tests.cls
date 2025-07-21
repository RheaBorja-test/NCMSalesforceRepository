@isTest
public class RoomBlockOptionsAPI_Tests {
    
    @TestSetup
    static void makeData(){
        SampleDataFactory.create20GroupAccountData();
        
    }

    @isTest
    public static void test20GroupEngagement() {
        
        Id twentyGrpId = [select id from Twenty_Groups__c LIMIT 1].Id;
        String ncmContactRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('NCM Associates').getRecordTypeId();
        String engRecTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('Retail Solutions').getRecordTypeId();
        Contact billingContact = [select id from contact where RecordTypeId = :ncmContactRecTypeId LIMIT 1];
        
        SampleDataFactory.createEngagement_20G(twentyGrpId,engRecTypeId,billingContact.Id);

        Engagement__c testEngagement = [select id from engagement__c limit 1];
        X20_Group_Member_Contact__c gmc = [SELECT Id FROM X20_Group_Member_Contact__c LIMIT 1];
        System.debug('~~~gmc: ' + gmc);
        
        String surveyId = gmc.Id + '-' + testEngagement.Id;

        insert(new Engagement_Room_Block__c(
            Engagement_Id__c = testEngagement.Id,
            Name = 'Test Hotel',
            Room_Rate__c = 10,
            Room_Type__c = 'Test Room'
        ));

        RoomBlockModel.RoomBlockOptionsResponse resp;
        
        Test.startTest();
            resp = RoomBlockOptionsAPI.getRoomBlockOptions(testEngagement.Id, surveyId);
        Test.stopTest();

        Assert.areEqual('200', resp.statusCode);
    }
}