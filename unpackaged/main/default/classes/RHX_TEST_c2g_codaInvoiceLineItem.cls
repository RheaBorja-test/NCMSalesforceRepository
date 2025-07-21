@isTest(SeeAllData=true)
public class RHX_TEST_c2g_codaInvoiceLineItem {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM c2g__codaInvoiceLineItem__c LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new c2g__codaInvoiceLineItem__c()
            );
        }
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}