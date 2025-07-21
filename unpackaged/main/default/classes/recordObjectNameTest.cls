@isTest (SeeAllData=true)
public with sharing class recordObjectNameTest {
    static testMethod void testGetObjectName(){
        test.startTest();

        id accId = [select id from Account limit 1].id;
        list<id> recIds = new List<Id>();
        recIds.add(accId);
        recordObjectName.getObjectAPIName(recIds);

        test.stopTest();
    }
}