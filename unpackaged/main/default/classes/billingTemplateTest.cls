@isTest(SeeAllData = true)
public class billingTemplateTest
{
	@isTest
	static void testBillingTemplate()
	{
		test.startTest();
		PricebookEntry pbe = [SELECT 
		                            Product2Id, 
		                            Product2.Name, 
									Product2.displayURL, 
									Product2.Locked_Frequency__c, 
									Product2.Core_Product__c, 
									Product2.Meetings_Included__c,
									Product2.Shipped_Product__c,
									Product2.Level_1_Name__c,
									Pricebook2Id, 
		                            Id, 
		                            UnitPrice
		                      FROM PricebookEntry 
		                      WHERE IsActive = TRUE
		                      LIMIT 1];
		pbe.Product2.displayURL = 'http://www.ncm.com';
		pbe.Product2.Core_Product__c = true;
		pbe.Product2.Locked_Frequency__c = 'One Time';
		billingTemplate billTemp = new billingTemplate(  );
		billTemp = new billingTemplate( pbe );
		boolean isValid = billingTemplate.isValid(billTemp);
		test.stopTest();
	}
}