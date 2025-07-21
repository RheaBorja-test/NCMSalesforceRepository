@ isTest(SeeAllData = true) public class batchPINexpLinesTest {
    public static testMethod void testStandardBridge() {
		Test.startTest();

		user u =
	    [   
			SELECT id
			FROM User
			WHERE IsActive = true and Id in
			(
				SELECT UserId
				FROM UserPackageLicense
				WHERE PackageLicense.NamespacePrefix = 'c2g'
			) and Id in
			(
				SELECT c2g__User__c
				FROM c2g__codaUserCompany__c
			) 
			ORDER BY LastName DESC
			LIMIT 1
        ];

        System.runas(u) {
            list<c2g__codaPurchaseInvoiceExpenseLineItem__c> lnItms = 
            [
                SELECT Id, Name
                FROM c2g__codaPurchaseInvoiceExpenseLineItem__c
                LIMIT 50
            ];

            batchPINexpLines btchLines = new batchPINexpLines(lnItms);
            id batchId = Database.executebatch(btchLines, lnItms.size());
        }

        test.stopTest();
    }
}