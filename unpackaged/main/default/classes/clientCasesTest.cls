@isTest (SeeAllData=true)
public class clientCasesTest {
    static testMethod void TestclientCases(){
        test.startTest();
        
        id recId = [select axcessa_Store__c from Client_Case_Relation__c where axcessa_Store__c != null limit 1].axcessa_Store__c;
        list<Client_Support_Ticket__c> cases = clientCasesController.getClientCases(recId);
        
        test.stopTest();
    }
}