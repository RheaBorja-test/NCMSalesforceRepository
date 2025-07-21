@isTest 
public class EngagementDim4NameSyncBatch_Tests {
    
    @TestSetup
    static void makeData(){

        SampleDataFactory.create20GroupAccountData();

        String twentyGroupId = [SELECT Id FROM Twenty_Groups__c WHERE Status__c = 'Active' LIMIT 1].Id;
        String engagementRT = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('Retail Solutions').getRecordTypeId();
        String ncmBillingContactId = [SELECT Id FROM Contact WHERE RecordType.Name = 'NCM Associates' LIMIT 1].Id;

        SampleDataFactory.createEngagement_20G(twentyGroupId, engagementRT, ncmBillingContactId);

    }

    @isTest 
    public static void engagementNameChangedUpdatesDIM4Name(){

        // Get a sample engagement record to work with.
        Engagement__c testEng = [SELECT id, Engagement_Start__c, Dimension_4__c 
                                    FROM Engagement__c 
                                    WHERE Dimension_4__c != null 
                                    LIMIT 1];

        // Update the Engagement Start field to trigger the engagement Name to change.
        testEng.Engagement_Start__c = testEng.Engagement_Start__c.addDays(1); 
        update(testEng);

        // Verify that now the Engagement Name and its Dim4 Name are not the same..
        Engagement__c testEng2 = [SELECT Name, Dimension_4__r.Name 
                                    FROM Engagement__c 
                                    WHERE Id = :testEng.Id];

        Assert.areNotEqual(testEng2.Name, testEng2.Dimension_4__r.Name);


        User sfAdminUser = [select id from User where name = 'SF Admin' and IsActive = true];

        // Execute the batch to update the DIM4 record name
        Test.startTest();

            // We will simulate this batch running as the service account SF Admin which 
            // has the Financial Force license necessary to update the Dimension4 record.
            System.runAs(sfAdminUser){
                Database.executeBatch(new EngagementDim4NameSyncBatch(),1);
            }

        Test.stopTest();


        Engagement__c engResult = [SELECT id, Name, Dimension_4__c, Dimension_4__r.Name FROM Engagement__c WHERE Id = :testEng.Id];
        Assert.areEqual(engResult.Name,engResult.Dimension_4__r.Name);

    }
}