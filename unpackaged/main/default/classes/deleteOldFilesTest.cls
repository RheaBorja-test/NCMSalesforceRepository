@ isTest(SeeAllData = true)
public class deleteOldFilesTest {

	@ IsTest
	static void testDeleteFiles() {
		user contextUser = 
		[
			SELECT Id 
			FROM User 
			WHERE Profile.Name = 'System Administrator' AND IsActive = True
            LIMIT 1
		];
		Test.startTest();
		System.runAs(contextUser) {
			date oldestDate = date.today().addDays(-90);
			List<ContentDocumentLink> CDLs = [SELECT contentDocumentId
                                                FROM ContentDocumentLink
                                                WHERE linkedEntityId IN (SELECT Id FROM c2g__codaInvoice__c WHERE Paid_Date__c <> null AND Paid_Date__c < :oldestDate)
												LIMIT 200];
			if(CDLS.isEmpty()) {
				List<ContentDocumentLink> cdlList = [SELECT linkedEntityId
                                                     FROM ContentDocumentLink
                                                     WHERE linkedEntityId IN (SELECT Id FROM c2g__codaInvoice__c) 
                                                     LIMIT 1];
                
                if( !cdlList.isEmpty() ){
                    id slsInvId = cdlList[0].linkedEntityId;
                    c2g__codaInvoice__c inv = new c2g__codaInvoice__c();
                    inv.Id = slsInvId;
                    inv.Paid_Date__c = oldestDate.addDays(-10);
                    update inv;
			
                    deleteOldFiles.deleteOldFiles();
                }
            }
            
		}
		Test.stopTest();

	}
}