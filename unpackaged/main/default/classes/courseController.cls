public with sharing class courseController
{
	@AuraEnabled
	public static List<Engagement__c> getSessions(id crseId, boolean includeNotAvailable)
	{
		List<Engagement__c> engs;
		string whereStatement = ' WHERE Course__c = \'' + crseId + '\'';
		whereStatement = whereStatement + ' AND Engagement_End__c >= TODAY';
		if ( !includeNotAvailable )
		{
			whereStatement = whereStatement + ' AND (Available_Seats__c > 0 OR Overbook_Remaining__c > 0) ';
		}
		DescribeSObjectResult describeResult = Engagement__c.getSObjectType(  ).getDescribe();
		List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
		String query = ' SELECT ' + String.join( fieldNames, ', ' ) + ' FROM ' + describeResult.getName() + whereStatement + ' ORDER BY Engagement_Start__c ASC, Available_Seats__c DESC, Waitlist__c ASC';
		engs = Database.query(query);
		return engs;
	}
}