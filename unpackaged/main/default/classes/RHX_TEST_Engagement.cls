@isTest(SeeAllData=true)
public class RHX_TEST_Engagement {
       static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
                   FROM Engagement__c ORDER BY LastModifiedDate DESC LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Engagement__c()
            );
        }
            

       rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}