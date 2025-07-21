@isTest (SeeAllData = true)
public class cseRelAxcTest {
    public static testMethod void TestcseRelAxc() {
        test.startTest();
        PageReference pageRef = Page.caseRelateAxcessa;
        Test.setCurrentPage(pageRef);
        
        Client_Support_Ticket__c cse = [select id from Client_Support_Ticket__c where axcessa_Store__r.Store_Status__c = 'Active' limit 1];
        ApexPages.currentPage().getParameters().put('id', cse.id);

        apexpages.standardcontroller stdController = new ApexPages.StandardController(cse);
        cseRelAxcEXT controller = new cseRelAxcEXT(stdController);
        
        controller.getcse();
        controller.getwRels();
        
        controller.unslctAll();
        controller.slctAll();
        
        controller.updRel();
        
        test.stopTest();
    }
}