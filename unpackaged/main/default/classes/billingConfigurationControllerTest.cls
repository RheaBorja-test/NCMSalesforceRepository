@isTest(SeeAllData = true)
public class billingConfigurationControllerTest
{
	@IsTest
	static void testBillAccMethods()
	{
		User u = getUser();
		Test.startTest();
		System.runas(u)
		{
			List<Billing_Product__c> bProds = [SELECT Id
			                                   FROM Billing_Product__c
			                                   WHERE Billing_Product_Status__c = 'Active'
			                                   LIMIT 100];
			for ( Billing_Product__c bProd : bProds )
			{
				bProd.Next_Billing_Date__c = Date.today(  ).addDays(-1);
			}
			Database.update( bProds, false );
			Id dim1Id = [SELECT Id
			             FROM c2g__codaDimension1__c
			             WHERE c2g__ReportingCode__c = '8000'].Id;
			string billProdWhere = 'WHERE DIMENSION_1__c = \'' + dim1Id + '\'';
			List<AggregateResult> billAccs = billingConfigurationController.getBillAccs(billProdWhere);
			if(billAccs != null && !billAccs.isEmpty()){
				AggregateResult billAcc = billAccs.get(0);
				Id bAccId = ( Id )billAcc.get('Billing_Account__c');
				Billing_Account__c bAcc = billingConfigurationController.getSelectedBillAcc(bAccId, billProdWhere);
			}
		}
		Test.stopTest();
	}

	@IsTest
	static void testBatchMethods()
	{
		User u = getUser();
		Test.startTest();
		System.runAs(u)
		{
			Id dim1Id = [SELECT Id
			             FROM c2g__codaDimension1__c
			             WHERE c2g__ReportingCode__c = '8000'].Id;
			string billProdWhere = 'WHERE DIMENSION_1__c = \'' + dim1Id + '\'';
			date tDay = date.today(  );
			string descript = 'Test Description';
			billingConfigurationController.runManualBatch(billProdWhere, false, false, tDay, descript);
			List<AsyncApexJob> jobList = [SELECT Id
			              FROM AsyncApexJob
			              LIMIT 1];
            
            if(!jobList.isEmpty()){
	            Id batchId = jobList[0].Id;
				AsyncApexJob batchJob = billingConfigurationController.getBatchStatus(batchId);
			}
            
		}
		Test.stopTest();
	}

	private static User getUser()
	{
		user u = [SELECT id
		          FROM User
		          WHERE IsActive = true and Id in (SELECT UserId
		                                           FROM UserPackageLicense
		                                           WHERE PackageLicense.NamespacePrefix = 'c2g') and Id in (SELECT c2g__User__c
		                                                                                                    FROM c2g__codaUserCompany__c)
		          ORDER BY LastName DESC
		          LIMIT 1];
		return u;
	}
}