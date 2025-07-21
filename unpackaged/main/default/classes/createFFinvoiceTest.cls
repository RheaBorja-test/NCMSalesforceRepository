@isTest (SeeAllData = true)
public class createFFinvoiceTest {
	public static testMethod void testCreateFFinvoice() {
        test.startTest();
        PageReference pageRef = Page.createFFinvoice;
        Test.setCurrentPage(pageRef);
        
        OpportunityLineItem oppLnItm = [select id, OpportunityId 
                                        from OpportunityLineItem 
                                        where Invoiced__c = false and Ready_to_Invoice__c = true and Opportunity.OEM_Account_ID__c = null and Opportunity.Owner.IsActive = true
                                       	limit 1];
        opportunity opp = [select id from opportunity where id = :oppLnItm.OpportunityId];
        ApexPages.currentPage().getParameters().put('id', opp.id);

        apexpages.standardcontroller stdController = new ApexPages.StandardController(opp);
        createFFinvoiceEXT controller = new createFFinvoiceEXT(stdController);
        
        list<OpportunityLineItem> lnItms = controller.getoppLnItms();
        controller.createInvoice();
        delete lnItms;
        controller.createInvoice();
        test.stopTest();
    }
}