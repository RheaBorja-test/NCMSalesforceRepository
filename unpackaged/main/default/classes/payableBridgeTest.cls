@IsTest
public with sharing class payableBridgeTest{
    
    @testSetup
    static void setupData(){
        SampleDataFactory.createData();
    }
    
	static testMethod void testPayableBridge(){

		Test.startTest();

		User usr = [select id
		            from User
		            where Profile.Name = 'System Administrator' AND isActive = True
		            limit 1];
		System.runAs(usr)
		{

			List<AggregateResult> aggResults = payableBridge.getPayAccs(null, null, 'None');
			string payAccId;
			if ( aggResults != null )
			{
				payAccId = ( string )aggResults.get(0).get('Payable_Account__c');
			}
			else
			{
				payAccId = [select 
				                  id
				            from Billing_Account__c
				            where recordType.Name = 'Payable Account'
				            limit 1].id;
			}

			id dim1Id = [SELECT 
			                   Id
			             FROM c2g__codaDimension1__c
			             LIMIT 1].Id;
			id dim2Id = [SELECT 
			                   Id
			             FROM c2g__codaDimension2__c
			             LIMIT 1].Id;

			Billing_Account__c payAcc = payableBridge.getPayAcc(payAccId);
			c2g__codaPurchaseInvoice__c pin = payableBridge.buildPIN(payAcc);
			List<Engagement_Expense__c> exps = payableBridge.getExpenses(payAccId, null, null, 'None');
			if ( exps == null || exps.size() > 0 )
			{
				exps = new List<Engagement_Expense__c>();
				Engagement_Expense__c exp = new Engagement_Expense__c(  );
				exp.Dimension_1__c = dim1Id;
				exp.Dimension_2__c = dim2Id;
				exps.add(exp);
			}


			try
			{
				payableBridge.createPIN(pin, exps, true);
			}
			catch ( Exception er )
			{
				system.debug(er);
			}

		}
		Test.stopTest();
	}
}