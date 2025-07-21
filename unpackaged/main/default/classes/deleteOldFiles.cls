public class deleteOldFiles {

	@InvocableMethod
	public static void deleteOldFiles() {
		date oldestDate = date.today().addDays(-90);
		List<ContentDocumentLink> CDLs = 
		[
			SELECT ContentDocumentId
			FROM ContentDocumentLink
			WHERE linkedEntityId IN 
				(
					SELECT Id
					FROM c2g__codaInvoice__c
					WHERE 
						Paid_Date__c <> null AND 
						Paid_Date__c < :oldestDate
				)
			LIMIT 200
		];

		if(CDLs.size() > 0) {
			List<ContentDocument> conDocs = new List<ContentDocument>();
			for (ContentDocumentLink cdl :CDLs) {
				ContentDocument conDoc = new ContentDocument();
				conDoc.Id = cdl.ContentDocumentId;
				conDocs.add(conDoc);
			}

			Database.delete(conDocs, false);
		}
	}
}