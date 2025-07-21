@isTest(seeAllData = true)
public class productGroupTest
{
	@isTest
	static void testProductGroup()
	{
		test.startTest();
		productGroup prodGroup = new productGroup(  );
		list<PricebookEntry> pbes = [SELECT 
		                                   Id
		                             FROM PricebookEntry 
		                             LIMIT 5];
		prodGroup = new productGroup( 'TestGroup', pbes );
		test.stopTest();
	}
}