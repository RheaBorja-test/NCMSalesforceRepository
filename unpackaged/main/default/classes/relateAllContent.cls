public class relateAllContent {

	public class vars {
		@InvocableVariable(label = 'Main Record ID' Required = true) public Id mainRecId;
		@InvocableVariable(label = 'Record to Relate Id' Required = true) public id relRecId;
	}

	@InvocableMethod
	public static void relateContent(List<vars> vars) {
		list<ContentDocumentLink> nwConDocLnks = new list<ContentDocumentLink>();

		list<id> mainRecIds = new List<Id>();
		list<id> relRecIds = new List<Id>();
		for (vars var :vars) {
			mainRecIds.add(var.mainRecId);
			relRecIds.add(var.relRecId);
		}

		list<ContentDocumentLink> relConDocLnks = [select ContentDocumentId from ContentDocumentLink where LinkedEntityId in :relRecIds];
        list<id> relConDocLnkIds = new List<Id>();
        for (ContentDocumentLink conDocLnk :relConDocLnks) {
            relConDocLnkIds.add(conDocLnk.ContentDocumentId);
        }
		list<ContentDocumentLink> conDocLnks = [select ContentDocumentId, LinkedEntityId
											    from ContentDocumentLink
											    where LinkedEntityId IN :mainRecIds and ContentDocumentId NOT IN :relConDocLnkIds
											    order by LinkedEntityId
												LIMIT 100];

		id mainRecId = vars.get(0).mainRecId;
        
		for (ContentDocumentLink conDocLnk :conDocLnks) {

			for (vars var :vars) {
				if(var.mainRecId == conDocLnk.LinkedEntityId) {
					ContentDocumentLink nwConDocLnk = conDocLnk.clone(false, false, false, false);
					nwConDocLnk.LinkedEntityId = var.relRecId;
					nwConDocLnks.add(nwConDocLnk);
				}
			}
		}

		System.debug('There are ' + nwConDocLnks.size() + ' records to insert.');
		
		if(nwConDocLnks.size() > 0) {
			database.insert(nwConDocLnks, false);
		}
	}
}