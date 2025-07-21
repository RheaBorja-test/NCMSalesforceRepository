public class batchAxcessaMetricCalculation implements Database.Batchable<sObject>
{
	public Datetime firstOfYear;

	public Integer ytdDivisor;

	public Database.QueryLocator start(Database.BatchableContext BC)
	{
		firstOfYear = datetime.newInstance(Date.Today(  ).year(), 1, 1);
		if ( Date.today(  ).addMonths(-1).month() == 12 )
		{
			ytdDivisor = 1;
		}
		else
		{
			ytdDivisor = Date.today(  ).addMonths(-1).month();
		}

		String query = 'SELECT Id, Reynolds_Customer_ID_CIF__c, Reynolds_Store_ID__c, Reynolds_axcessa_Group_Id__c, Reynolds_Store_Name__c, Last_Login_Date__c ';
		query = query + 'FROM axcessa_Platform_Engagement__c ';
		query = query + 'WHERE Need_to_Recalculate_Metrics__c = TRUE ';

		if ( Test.isRunningTest() )
		{
			query = query + 'LIMIT 1';
		}

		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope)
	{
		List<axcessa_Platform_Engagement__c> aXcessaStores = new list<axcessa_Platform_Engagement__c>();

		for ( sobject s : scope )
		{
			axcessa_Platform_Engagement__c aXcessaStore = ( axcessa_Platform_Engagement__c )s;

			List<aXcessa_Store_Metric__b> storeMetrics = new List<aXcessa_Store_Metric__b>();
			if ( Test.isRunningTest() )
			{
				aXcessa_Store_Metric__b testMetric = new aXcessa_Store_Metric__b(  );
				testMetric.aXcessa_Store__c = aXcessaStore.Id;
				testMetric.CIF__c = '0000000';
				testMetric.Data_Date__c = Datetime.now().addMonths(-1);
				testMetric.Group__c = '1111111';
				testMetric.Installed__c = 1;
				testMetric.Last_Login__c = Datetime.now().addMonths(-1);
				testMetric.NCM__c = 1;
				testMetric.Reports_Count__c = 1500;
				testMetric.Store_Id__c = '2222222';
				testMetric.Store_Name__c = 'Test Store';
				testMetric.Users_Count__c = 2600;

				storeMetrics.add(testMetric);
				testMetric.Data_Date__c = testMetric.Data_Date__c.addMonths(-1);
				testMetric.Last_Login__c = testMetric.Last_Login__c.addMonths(-1);
				testMetric.Reports_Count__c = 1501;
				testMetric.Users_Count__c = 2601;
				storeMetrics.add(testMetric);

				aXcessaStore.Reynolds_Customer_ID_CIF__c = null;
				aXcessaStore.Reynolds_Store_ID__c = null;
				aXcessaStore.Reynolds_axcessa_Group_Id__c = null;
				aXcessaStore.Reynolds_Store_Name__c = null;
				aXcessaStore.Last_Login_Date__c = null;
			}
			else
			{
				storeMetrics = [SELECT aXcessa_Store__c, CIF__c, Data_Date__c, Group__c, Installed__c, Last_Login__c, NCM__c, Reports_Count__c, Store_Id__c, Store_Name__c, Users_Count__c
				                FROM aXcessa_Store_Metric__b
				                WHERE aXcessa_Store__c = :aXcessaStore.Id
				                ORDER BY aXcessa_Store__c, Data_Date__c DESC
				                LIMIT 12];
			}

			Integer monthCount = 1;
			Decimal ytdReports = 0;
			Decimal ytdUsers = 0;
			for ( aXcessa_Store_Metric__b strMetric : storeMetrics )
			{
				if ( aXcessaStore.Reynolds_Customer_ID_CIF__c == null )
				{
					aXcessaStore.Reynolds_Customer_ID_CIF__c = strMetric.CIF__c;
				}
				if ( aXcessaStore.Reynolds_Store_ID__c == null )
				{
					aXcessaStore.Reynolds_Store_ID__c = strMetric.Store_Id__c;
				}
				if ( aXcessaStore.Reynolds_axcessa_Group_Id__c == null )
				{
					aXcessaStore.Reynolds_axcessa_Group_Id__c = strMetric.Group__c;
				}
				if ( aXcessaStore.Reynolds_Store_Name__c == null )
				{
					aXcessaStore.Reynolds_Store_Name__c = strMetric.Store_Name__c;
				}
				if ( aXcessaStore.Last_Login_Date__c < strMetric.Last_Login__c )
				{
					aXcessaStore.Last_Login_Date__c = Date.valueOf(strMetric.Last_Login__c);
				}

				system.debug(firstOfYear);
				if ( strMetric.Data_Date__c >= firstOfYear )
				{
					ytdReports = ytdReports + strMetric.Reports_Count__c;
					ytdUsers = ytdUsers + strMetric.Users_Count__c;
				}

				if ( monthCount == 1 )
				{
					aXcessaStore.Last_Month_Report_Count__c = strMetric.Reports_Count__c;
					aXcessaStore.Last_Month_User_Count__c = strMetric.Users_Count__c;
				}
				else if ( monthCount == 2 )
				{
					aXcessaStore.Last_Month_Report_Count__c = strMetric.Reports_Count__c;
					aXcessaStore.Last_Month_User_Count__c = strMetric.Users_Count__c;
				}

				monthCount = monthCount + 1;
			}

			aXcessaStore.YTD_Report_Count__c = ytdReports;
			aXcessaStore.YTD_User_Count__c = ytdUsers;

			if ( ytdReports > 0 )
			{
				aXcessaStore.YTD_AVG_Report_Count__c = ytdReports / ytdDivisor;
			}
			else
			{
				aXcessaStore.YTD_AVG_Report_Count__c = 0;
			}
			if ( ytdUsers > 0 )
			{
				aXcessaStore.YTD_AVG_User_Count__c = ytdUsers / ytdDivisor;
			}
			else
			{
				aXcessaStore.YTD_AVG_User_Count__c = 0;
			}

			aXcessaStore.Need_to_Recalculate_Metrics__c = false;
			aXcessaStore.Data_Updated__c = Date.today(  );

			aXcessaStores.add(aXcessaStore);
		}

		System.debug(aXcessaStores);
		Database.SaveResult[] SRs = Database.update( aXcessaStores, false );
		for ( Database.SaveResult sr : SRs )
		{
			if ( sr.isSuccess() )
			{
				System.debug('Success on: ' + sr.getId());
			}
			else
			{
				System.debug(sr.getErrors());
			}
		}
	}

	public void finish(Database.BatchableContext BC)
	{
	}
}