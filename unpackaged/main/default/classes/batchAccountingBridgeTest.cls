@isTest(SeeAllData = true)
public class batchAccountingBridgeTest
{
	public static testMethod void testStandardBridge()
	{
		Test.startTest();

		user u = getUser();
		System.runas(u)
		{
			Billing_Product__c bProd = setupEnv('8000');
			Billing_Configuration__c bConfig = new Billing_Configuration__c();

			bConfig.Dimension_1__c = bProd.Dimension_1__c;
			bConfig.One_Time_Run__c = true;
			bConfig.Split_on_Dim_2__c = true;
			bConfig.Recurring_Day__c = date.today().day();
			bConfig.Billing_Product_WHERE__c = 
				'WHERE Next_Billing_Date__c <= TODAY AND Dimension_1__c = \'' + 
				bProd.Dimension_1__c + 
				'\' AND Billing_Product_Status__c = \'Active\' ' + 
				' AND Billing_Account__r.Status__c = \'Validated\'' + 
				' AND Billing_Frequency__c <> \'One-Time\'';
			insert bConfig;

			Billing_Configuration_Detail__c bConfigDet = new Billing_Configuration_Detail__c();
			bConfigDet.Dimension_1__c = bConfig.Dimension_1__c;
			bConfigDet.Billing_Configuration__c = bConfig.id;
			bConfigDet.Billing_Account__c = bProd.Billing_Account__c;
			insert bConfigDet;

			try
			{
				batchAccountingBridge batchBrd = new batchAccountingBridge();
				database.executebatch(batchBrd, 1);
			}
			catch ( exception er )
			{
				system.debug(er);
			}
		}
		Test.stopTest();
	}

	public static testMethod void testCustomInvoiceDate()
	{
		Test.startTest();

		user u = getUser();
		System.runas(u)
		{
			Billing_Product__c bProd = setupEnv('8000');
			Billing_Configuration__c bConfig = new Billing_Configuration__c();

			bConfig.Dimension_1__c = bProd.Dimension_1__c;
			bConfig.One_Time_Run__c = true;
			bConfig.Recurring_Day__c = date.today().day();
			bConfig.Billing_Product_WHERE__c = 
				'WHERE Next_Billing_Date__c <= TODAY AND Dimension_1__c = \'' + 
				bProd.Dimension_1__c + 
				'\' AND Billing_Product_Status__c = \'Active\' ' + 
				' AND Billing_Account__r.Status__c = \'Validated\' ' + 
				' AND Billing_Frequency__c <> \'One-Time\'';
			bConfig.Custom_Invoice_Date__c = Date.today().addDays(-7);
			bConfig.Invoice_Description__c = 'Test Description';
			insert bConfig;

			Billing_Configuration_Detail__c bConfigDet = new Billing_Configuration_Detail__c();
			bConfigDet.Dimension_1__c = bConfig.Dimension_1__c;
			bConfigDet.Billing_Configuration__c = bConfig.id;
			bConfigDet.Billing_Account__c = bProd.Billing_Account__c;
			insert bConfigDet;

			try
			{
				batchAccountingBridge batchBrd = new batchAccountingBridge();
				database.executebatch(batchBrd, 1);
			}
			catch ( exception er )
			{
				system.debug(er);
			}
		}
		Test.stopTest();
	}

	public static testMethod void testErrors()
	{
		Test.startTest();

		user u = getUser();
		System.runas(u)
		{
			Billing_Product__c bProd = setupEnv('8000');
			Billing_Configuration__c bConfig = new Billing_Configuration__c();

			bConfig.Dimension_1__c = bProd.Dimension_1__c;
			bConfig.One_Time_Run__c = true;
			bConfig.Recurring_Day__c = date.today().day();
			bConfig.Billing_Product_WHERE__c = 
				'WHERE Next_Billing_Date__c <= TODAY AND Dimension_1__c = \'' + 
				bProd.Dimension_1__c + 
				'\' AND Billing_Product_Status__c = \'Active\' ' + 
				' AND Billing_Account__r.Status__c = \'Validated\' ' + 
				' AND Billing_Frequency__c <> \'One-Time\'';
			bConfig.Custom_Invoice_Date__c = Date.today().addDays(-7);
			bConfig.Invoice_Description__c = 'Test Description';
			insert bConfig;

			Billing_Configuration_Detail__c bConfigDet = new Billing_Configuration_Detail__c();
			bConfigDet.Dimension_1__c = bConfig.Dimension_1__c;
			bConfigDet.Billing_Configuration__c = bConfig.id;
			bConfigDet.Billing_Account__c = bProd.Billing_Account__c;
			insert bConfigDet;

			try
			{
				batchAccountingBridge batchBrd = new batchAccountingBridge();
				batchBrd.failTest = true;
				database.executebatch(batchBrd, 1);
			}
			catch ( exception er )
			{
				system.debug(er);
			}
		}
		Test.stopTest();
	}

	public static testMethod void testErrorLogs()
	{

		Test.startTest();

		user u = getUser();
		System.runas(u)
		{
			batchAccountingBridge.errorLog errLog = new batchAccountingBridge.errorLog('Test');
			errLog = new batchAccountingBridge.errorLog('Test', 'Test');
		}
		Test.stopTest();
	}

	private static User getUser()
	{
		user u = 
		[
			SELECT 
				Id
			FROM User
			WHERE 
				IsActive = true AND 
				Id IN 
				(
					SELECT UserId
					FROM UserPackageLicense
					WHERE PackageLicense.NamespacePrefix = 'c2g'
				) AND 
				Id IN 
				(
					SELECT c2g__User__c
					FROM c2g__codaUserCompany__c
				)
			ORDER BY LastName DESC
			LIMIT 1
		];
		return u;
	}

	private static Billing_Product__c setupEnv(string dim1ReportingCode)
	{
		Billing_Product__c bProd = 
		[
			SELECT 
				Id, 
				Billing_Account__c, 
				Dimension_1__c
			FROM Billing_Product__c
			WHERE 
				Dimension_1__r.c2g__ReportingCode__c = :dim1ReportingCode AND 
				Dimension_2__c != null AND 
				Billing_Account__r.Status__c = 'Validated' AND
				Billing_Product_Status__c = 'Active' AND
				Billing_Frequency__c <> 'One-Time'
			LIMIT 1
		];
		bProd.Next_Billing_Date__c = Date.today().addDays(-1);
		update bProd;

		List<Billing_Product__c> bProds = 
		[
			SELECT 
				Id
			FROM Billing_Product__c
			WHERE 
				Next_Billing_Date__c <= TODAY AND 
				Id <> :bProd.Id AND 
				Billing_Account__c = :bProd.Billing_Account__c
		];
		for ( Billing_Product__c bPrd : bProds )
		{
			bPrd.Next_Billing_Date__c = Date.today().addDays(5);
		}
		Database.update( bProds );

		list<Billing_Configuration__c> bConfigs = 
		[
			SELECT 
				Id
			FROM Billing_Configuration__c
		];
		Database.delete( bConfigs );

		return bProd;
	}
}