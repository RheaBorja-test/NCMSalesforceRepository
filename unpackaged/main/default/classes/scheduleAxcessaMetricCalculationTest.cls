@isTest(SeeAllData = true)
public class scheduleAxcessaMetricCalculationTest
{
	@IsTest
	static void methodName()
	{

		User contextuser = [SELECT Id
		                    FROM User
		                    WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE
		                    LIMIT 1];

		Test.startTest();
		System.runAs(contextuser)
		{
			SchedulableContext sc = null;
			scheduleAxcessaMetricCalculation testSche = new scheduleAxcessaMetricCalculation(  );
			testSche.execute(sc);
		}
		Test.stopTest();
	}
}