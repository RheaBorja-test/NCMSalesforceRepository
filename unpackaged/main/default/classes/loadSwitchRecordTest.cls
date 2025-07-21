@isTest(SeeAllData = true)
public class loadSwitchRecordTest
{
	@IsTest
	static void testLoadSwitchRecordTest()
	{
		Test.startTest();

		Id recId = [SELECT Id
		            FROM Account
		            LIMIT 1].Id;

		List<loadSwitchRecord.Var> vars = new List<loadSwitchRecord.Var>();
		loadSwitchRecord.Var var = new loadSwitchRecord.Var();
		var.recId = recId;
		var.fieldName = 'Load_Switch__c';
		vars.add(var);

		loadSwitchRecord.loadSwitchGivenRecord(vars);

		Test.stopTest();
	}
}