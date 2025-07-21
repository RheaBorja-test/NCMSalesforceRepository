@isTest(SeeAllData = true)
public class batchBillingProductConversionTest
{
	public static testMethod void TestbatchBillingProductConversion()
	{
		Test.startTest();

		user u = [SELECT id
		          FROM User
		          WHERE id in (SELECT UserId
		                       FROM UserPackageLicense
		                       WHERE PackageLicense.NamespacePrefix = 'c2g')
				  AND Profile.Name = 'NCM Accounting'
		          LIMIT 1];

		System.runas(u)
		{

			Billing_Product__c bProd;
			try
			{
				bProd = [SELECT Id, Dimension_1__c, Billing_Account__c
				         FROM Billing_Product__c
				         WHERE Next_Billing_Date__c <= TODAY and Billing_Product_Status__c = 'Active' and Dimension_1__c<>null and Billing_Account__c<>null
				         LIMIT 1];
			}
			catch ( Exception er )
			{
				system.debug(er);
				bProd = [SELECT Id, Dimension_1__c, Billing_Account__c
				         FROM Billing_Product__c
				         WHERE Billing_Product_Status__c = 'Active' and Dimension_1__c<>null and Billing_Account__c<>null
				         LIMIT 1];
				bProd.Next_Billing_Date__c = Date.today(  ).addDays(-1);
				Database.update( bProd );
			}

			list<Billing_Product__c> bProds = [SELECT Id
			                                   FROM Billing_Product__c
			                                   WHERE Next_Billing_Date__c <= TODAY and Billing_Product_Status__c = 'Active' and Billing_Account__c = :bProd.Billing_Account__c and id<> :bProd.Id];

			for ( Billing_Product__c bPrd : bProds )
			{
				bPrd.Billing_Product_Status__c = 'Inactive';
			}
			update bProds;

			DescribeSObjectResult describeResult = Billing_Product__c.getSObjectType().getDescribe();
			List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
			string qry = 
				' SELECT ' + String.join(fieldNames, ', ')+' FROM ' + describeResult.getName()+' WHERE Next_Billing_Date__c <= :tDay and Billing_Product_Status__c = \'Active\' and' + 
				' Billing_Account__c = \'' + bProd.Billing_Account__c + '\' and' + 
				' Dimension_1__c = \'' + bProd.Dimension_1__c + '\'';

			accountingBridgeControllers accBrdCon = new accountingBridgeControllers(  );
			c2g__codaInvoice__c inv = accBrdCon.createInvoice(bProd.Billing_Account__c, Date.Today(  ), null, null);
			insert inv;

			batchBillingProductConversion batchBprod = new batchBillingProductConversion( qry, true, inv.id );
			database.executebatch(batchBprod, 50);
		}
		test.stopTest();
	}
}