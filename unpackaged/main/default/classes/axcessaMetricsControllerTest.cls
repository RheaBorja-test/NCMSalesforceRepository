@isTest(SeeAllData = true)
public class axcessaMetricsControllerTest
{
	public static testMethod void testMetricsController()
	{
		User contextuser = [SELECT Id
		                    FROM User
		                    WHERE username LIKE 'autoproc%'
		                    LIMIT 1];

		Test.startTest();

		System.runAs(contextuser)
		{
			List<Id> storeIds = new List<Id>();
			Id storeId = [SELECT Id
			              FROM axcessa_Platform_Engagement__c
			              LIMIT 1].Id;
			storeIds.add(storeId);

			try
			{
				axcessaMetricsController.getAxcessaStoreMetrics(storeIds);
			}
			catch ( Exception er )
			{
				System.debug(er);
			}

		}

		Test.stopTest();
	}
}