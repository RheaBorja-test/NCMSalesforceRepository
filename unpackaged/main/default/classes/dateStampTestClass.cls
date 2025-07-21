@isTest(SeeAllData = true)
public class dateStampTestClass
{
	public static testMethod void testDateStamp()
	{

		List<dateStampInvocable.var> vars = new List<dateStampInvocable.var>();
		Opportunity opp = [SELECT Id
		                   FROM Opportunity
		                   ORDER BY CreatedDate DESC
		                   LIMIT 1];

		dateStampInvocable.var var = new dateStampInvocable.var();
		var.recId = opp.Id;
		var.completedDate = Datetime.now();
		var.fldName = 'NCMi_First_Contact__c';
		var.formatType = 'Date';
		vars.add(var);

		var.fldName = 'DocuSign_Sent__c';
		var.formatType = 'DateTime';
		vars.add(var);

		try
		{
			dateStampInvocable.dateStampWhatRecord(vars);
		}
		catch ( Exception er )
		{
			System.debug(er);
		}
	}
}