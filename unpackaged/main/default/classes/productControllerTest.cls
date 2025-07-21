@isTest(SeeAllData = true)
public class productControllerTest
{
	@isTest
	static void testProductController()
	{
		test.startTest();
		id pbId = [SELECT 
		                 Id
		           FROM Pricebook2 
		           WHERE IsStandard = true].id;
		list<PricebookEntry> pbes = [SELECT 
		                                   Id, 
		                                   Product2Id
		                             FROM PricebookEntry 
		                             WHERE Product2.IsActive = true and IsActive = true and Pricebook2Id = :pbId
		                             LIMIT 200];
		Product2 prod = new Product2(  );
		List<Product2> prods = new list<Product2>();
		prod.Id = pbes.get(0).Product2Id;
		prod.Object_Structure__c = 'All';
		prod.Objects_Added_From__c = 'Opportunity';
		prod.Level_1_Name__c = 'Test';
		prod.Level_2_Name__c = 'Test';
		prods.add(prod);
		Id prodId = prod.Id;
		Product2 prod2 = new Product2(  );
		for ( PricebookEntry pbe : pbes )
		{
			if ( prodId != pbe.Product2Id )
			{
				prod2.id = pbe.Product2Id;
				prod2.Object_Structure__c = 'All';
				prod2.Objects_Added_From__c = 'Opportunity';
				prod2.Level_1_Name__c = 'Test';
				prod2.Level_2_Name__c = 'Test 2';
			}
		}
		prods.add(prod2);
		update prods;
		list<productGroup> prodGrps = productController.getProducts('Product2.Objects_Added_From__c = \'Opportunity\'');
		Try
		{
			List<billingTemplate> billTemps = productController.convertPBEtoBillingTemplate(pbes);
		}
		catch ( exception er )
		{
		}
		test.stopTest();
	}

	@isTest
	private static void testGetProductSections() {
		List<verticalNavigationSection> lst = productController.getProductSections('Id != null');
		Assert.isNotNull(lst, 'Should not return a null list');
	}

	@IsTest
	static void testConvertPBEtoBillingTemplate(){
		List<String> pbeIds = new List<String>();
		for (PricebookEntry pbe : [SELECT Id FROM PricebookEntry LIMIT 5]) {
			pbeIds.add(pbe.Id);
		}
		List<billingTemplate> lst = productController.convertPBEtoBillingTemplate(pbeIds);
		Assert.areEqual(pbeIds.size(), lst.size(), 'returned list should be same size as parameter list');
		
	}
}