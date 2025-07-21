public inherited sharing class axcessaMetricsController
{
	@InvocableMethod
	public static List<List<aXcessa_Store_Metric__b>> getAxcessaStoreMetrics(list<Id> storeIds)
	{
		List<List<aXcessa_Store_Metric__b>> returnList = new List<List<aXcessa_Store_Metric__b>>();

		for ( Id storeId : storeIds )
		{

			List<aXcessa_Store_Metric__b> storeMetrics;

			string query = 'SELECT aXcessa_Store__c, CIF__c, Data_Date__c, Group__c, Installed__c, Last_Login__c, NCM__c, Reports_Count__c, Store_Id__c, Store_Name__c, Users_Count__c ';
			query = query + 'FROM aXcessa_Store_Metric__b WHERE aXcessa_Store__c = \'' + storeId + '\' ORDER BY aXcessa_Store__c, Data_Date__c DESC LIMIT 20 ';
			try
			{
				if ( !Test.isRunningTest() )
				{
					storeMetrics = Database.query(query);
				}
				returnList.add(storeMetrics);
			}
			catch ( Exception er )
			{
				System.debug(er);
			}

		}
		return returnList;
	}
}