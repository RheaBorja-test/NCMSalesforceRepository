public with sharing class billingConfigurationController
{
	//  returns an Aggregate list of billing accounts to the lightning component. Currently aggregates the count of billing products and the sum of the total value
	//  these are iterated over in the list on the left for the billing accounts to help identify irregularities
	@AuraEnabled
	public static List<AggregateResult> getBillAccs(string billProdWhere)
	{
		string query = 'SELECT SUM(Total_Value__c)total, COUNT(Id)recs, Billing_Account__c, Billing_Account__r.Name ';
		query = query + 'FROM Billing_Product__c ';
		query = query + billProdWhere;
		query = query + 'GROUP BY Billing_Account__c , Billing_Account__r.Name ';
		query = query + 'ORDER BY Billing_Account__r.Name ';
		System.debug('BILLING CONFIGURATOR QUERY: ' + query);
		
		List<AggregateResult> bAccs = Database.query(query);
		if ( bAccs.size() > 0 )
		{
			return bAccs;
		}
		else
		{
			return null;
		}
	}

	//  when the user clicks the select button on a bAcc Card, it will pass the bAccId to the parent component.
	//  It returns the Billing Account with all the appropriate billing products to be displayed
	@AuraEnabled
	public static Billing_Account__c getSelectedBillAcc(id bAccId, string billProdWhere)
	{
		string query = 'SELECT Name, Id, Primary_Contact__c, Primary_Contact__r.Name, Billing_Street__c, Billing_City__c, Billing_State_Province__c, Billing_Country__c, Billing_Zip_Postal_Code__c, ';
		query = query + '(SELECT Name, Id, Billing_Frequency__c, CEM_Id__c, CEM_Name__c, Description__c, Quantity__c, Total_Value__c, Value__c, Billing_Product_URL__c, Product_Name__c, Dimension_1_Name__c, Dimension_2_Name__c, Dimension_3_Name__c, Dimension_4_Name__c ';
		query = query + 'FROM Billing_Products__r ';
		query = query + billProdWhere + ') ';
		query = query + 'FROM Billing_Account__c ';
		query = query + 'WHERE Id = \'' + bAccId + '\'';
		Billing_Account__c bAcc = Database.query(query);
		return bAcc;
	}

	//  this method will run the accounting bridge batch manually
	//  taking the values provided it will create the temporary billing configuration record and the temporary billing configuration detail records
	//  this will return the batch Id of the scheduled batch
	@AuraEnabled
	public static string runManualBatch(string billProdWhere, Boolean splitDim2, Boolean splitCEM, Date invDate, string invDesc)
	{

		List<Billing_Configuration__c> delBConfigs = new List<Billing_Configuration__c>();
		delBConfigs = [SELECT Id
		               FROM Billing_Configuration__c];
		if ( delBConfigs.size() > 0 )
		{
			Database.delete( delBConfigs, FALSE );
		}

		Billing_Configuration__c billingConfig = new Billing_Configuration__c(  );
		billingConfig.One_Time_Run__c = true;
		billingConfig.Recurring_Day__c = Date.today(  ).day();
		billingConfig.Billing_Product_WHERE__c = billProdWhere;
		billingConfig.Split_on_Dim_2__c = splitDim2;
		billingConfig.Split_on_CEM__c = splitDim2;
		billingConfig.Invoice_Description__c = invDesc;
		if ( invDate != Date.today(  ) && invDate != null )
		{
			billingConfig.Custom_Invoice_Date__c = invDate;
		}
		insert billingConfig;
		List<Billing_Configuration__c> bConfigs = new List<Billing_Configuration__c>();
		bConfigs.add(billingConfig);
		list<Billing_Configuration_Detail__c> bConfigDets = billingProductDaily.createBillConfigDets(bConfigs);
		Id batchId;
		if ( bConfigDets.size() > 0 && !test.isRunningTest() )
		{
			insert bConfigDets;
			batchAccountingBridge batchBrd = new batchAccountingBridge(  );
			batchId = Database.executebatch(batchBrd, 1);
		}
		return batchId;
	}

	//  this method returns the status and numbers of the batch. it is called continuously when it is showing the monitor screen after running the manual batch
	@AuraEnabled
	public static AsyncApexJob getBatchStatus(Id batchId)
	{
		AsyncApexJob aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, ExtendedStatus, MethodName, CreatedBy.Name, CreatedDate
		                    FROM AsyncApexJob
		                    WHERE ID = :batchId];
		return aaj;
	}
}