@isTest(SeeAllData = true)
public class bAccCrtInvTest
{
	public static testMethod void testBilling()
	{
		Test.startTest();

		PageReference pageRef = Page.bAccCreateInvoice;
		Test.setCurrentPage(pageRef);

		Billing_Product__c bProd = [SELECT id, Billing_Account__c
		                            FROM Billing_Product__c
		                            WHERE Dimension_1__r.Name like '8000-axcessa'
		                            LIMIT 1];
		Billing_Account__c bAcc = [SELECT id
		                           FROM Billing_Account__c
		                           WHERE id = :bProd.Billing_Account__c];

		ApexPages.currentPage().getParameters().put('id', bAcc.id);
		apexpages.standardcontroller stdController = new ApexPages.StandardController( bAcc );

		bAccCrtInvEXT controller = new bAccCrtInvEXT( stdController );

		controller.getbAcc();
		controller.getfBprod();
		controller.fBprod.Dimension_1__c = [SELECT id
		                                    FROM c2g__codaDimension1__c
		                                    WHERE name like '8000-axcessa'
		                                    LIMIT 1].id;

		controller.fltr();
		controller.slctAll();
		controller.unslctAll();
		controller.advAll();
		controller.unadvAll();

		controller.getbProds();

		controller.bProds.get(0).selected = true;
		controller.bProds.get(0).advance = true;
		controller.crt();

		controller.setcstInvDate(Date.today(  ).addDays(-1));
		controller.getcstInvDate();

		test.stopTest();
	}
}