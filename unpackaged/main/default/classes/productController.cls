public without sharing class productController
{
	@AuraEnabled(cacheable=true)
	public static list<verticalNavigationSection> getProductSections(string sectionsWhereClause){
		try {
			string query = 'SELECT Id, Product2.RecordType.Name, Product2.Level_1_Name__c ';
			query = query + 'FROM PricebookEntry ';
			query = query + 'WHERE ' + sectionsWhereClause + ' AND Product2.Level_1_Name__c <> NULL ';
			query = query + 'ORDER BY Product2.RecordType.Name,Product2.Level_1_Name__c ';
			list<PricebookEntry> PBEs = Database.query(query);
			if (PBEs.size() >0) {
				
				list<verticalNavigationSection> navSecs = new list<verticalNavigationSection>();
				string recTypeName = PBEs.get(0).Product2.RecordType.Name;
				string lev1;
				list<verticalNavigationSection.sectionItem> sectionItems = new list<verticalNavigationSection.sectionItem>();

				for (PricebookEntry pbe : PBEs) {
					if (recTypeName <> pbe.Product2.RecordType.Name ) {
						
						verticalNavigationSection navSec = new verticalNavigationSection(recTypeName, sectionItems);
						navSecs.add(navSec);
						
						recTypeName = pbe.Product2.RecordType.Name;
						lev1 = pbe.Product2.Level_1_Name__c;

						string itemValue = recTypeName + ';' + lev1;
						verticalNavigationSection.sectionItem secItm = new verticalNavigationSection.sectionItem(lev1, itemValue);

						sectionItems = new list<verticalNavigationSection.sectionItem>();
						sectionItems.add(secItm);

					} else if(lev1 <> pbe.Product2.Level_1_Name__c){
						
						lev1 = pbe.Product2.Level_1_Name__c;
						string itemValue = recTypeName + ';' + lev1;

						verticalNavigationSection.sectionItem secItm = new verticalNavigationSection.sectionItem(lev1, itemValue);
						sectionItems.add(secItm);

					}
				}

				verticalNavigationSection navSec = new verticalNavigationSection(recTypeName, sectionItems);
				navSecs.add(navSec);

				return navSecs;
			} else{
				list<verticalNavigationSection> navSecs = new list<verticalNavigationSection>();
				return navSecs;
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled(cacheable=true)
	public static list<productGroup> getProducts(string productsWhereClause){
		try {
			List<productGroup> prodGroup = new List<productGroup>();

			string query = 'SELECT Id, UnitPrice, Product2.Name, Product2.Level_1_Name__c, Product2.Level_2_Name__c, Product2.ProductCode, Product2.DisplayUrl, ';
			query = query + 'Product2.Description, Product2.Locked_Frequency__c, Product2.Core_Product__c, Pricebook2Id ';
			query = query + 'FROM PricebookEntry ';
			query = query + 'WHERE ' + productsWhereClause + ' ';
			query = query + 'ORDER BY Product2.Level_2_Name__c, Product2.Name ';
			list<PricebookEntry> PBEs = Database.query(query);

			if ( PBEs.size() > 0 )
			{
				String lev2 = PBEs.get(0).Product2.Level_2_Name__c;
				List<PricebookEntry> pbeList = new List<PricebookEntry>();
				for ( PricebookEntry pbe : PBEs )
				{
					if ( pbe.Product2.Level_2_Name__c == lev2 )
					{
						pbeList.add(pbe);
					}
					else
					{
						productGroup prodGrp = new productGroup( lev2, pbeList );
						prodGroup.add(prodGrp);

						pbeList = new List<PricebookEntry>();
						pbelist.add(pbe);
						lev2 = pbe.Product2.Level_2_Name__c;
					}
				}

				productGroup prodGrp = new productGroup( lev2, pbeList );
				prodGroup.add(prodGrp);
				return prodGroup;

			} else {
				return new List<productGroup>();
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled(cacheable=true)
	public static list<billingTemplate> convertPBEtoBillingTemplate(List<PricebookEntry> pbes)
	{
		List<billingTemplate> billTemps = new List<billingTemplate>();
		for ( PricebookEntry pbe : pbes )
		{
			billTemps.add(new billingTemplate( pbe ));
		}
		return billTemps;
	}

	@AuraEnabled(cacheable=true)
	public static list<billingTemplate> convertPBEtoBillingTemplate(List<String> pbeIds)
	{		
		List<PricebookEntry> pbes = [
			SELECT
				Id, 
				UnitPrice, 
				Product2.Name, 
				Product2.Level_1_Name__c, 
				Product2.Level_2_Name__c, 
				Product2.ProductCode, 
				Product2.DisplayUrl, 
				Product2.Description, 
				Product2.Locked_Frequency__c, 
				Product2.Core_Product__c, 
				Pricebook2Id,
				Product2.Meetings_Included__c,
				Product2.Shipped_Product__c
			FROM PricebookEntry
			WHERE Id IN :pbeIds
		];
		List<billingTemplate> billTemps = new List<billingTemplate>();
		for ( PricebookEntry pbe : pbes )
		{
			billTemps.add(new billingTemplate( pbe ));
		}
		return billTemps;
	}
}