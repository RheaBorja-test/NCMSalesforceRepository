@isTest(SeeAllData = true)
public class courseControllerTest
{
	@isTest
	static void testCourseController()
	{
		test.startTest();
		id crseId = [SELECT 
		                   Id
		             FROM Course__c 
		             LIMIT 1].Id;
		try
		{
			courseController.getSessions(crseId, false);
		}
		catch ( Exception er )
		{
			System.debug(er);
		}
		test.stopTest();
	}
}