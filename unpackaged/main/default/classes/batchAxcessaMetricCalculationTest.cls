@isTest(SeeAllData = true)
public class batchAxcessaMetricCalculationTest
{
	@IsTest
	static void testBatchAxcessaMetricCalculation()
	{
		axcessa_Platform_Engagement__c pe = [SELECT Id FROM axcessa_Platform_Engagement__c LIMIT 1];
		pe.Need_to_Recalculate_Metrics__c = true;
		update pe;
		
		User contextuser = [SELECT Id
		                    FROM User
		                    WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE
		                    LIMIT 1];

		Test.startTest();
		System.runAs(contextuser)
		{
			batchAxcessaMetricCalculation batchable = new batchAxcessaMetricCalculation(  );
			Database.executeBatch(batchable, 1);
		}
		Test.stopTest();
	}
}