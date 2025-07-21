@isTest
public class billingAccountControllerTest{
    
    @testSetup
    static void setupData(){
        SampleDataFactory.createData();
    }
    
	@isTest
	static void testBillingAccountController()
	{
		test.startTest();
		Billing_Account__c billAccount = [SELECT 
		                  Id, Account__c, NCM_Authorized_Products__c
		            FROM Billing_Account__c 
		            WHERE Account__r.Out_of_Business__c = false
		            LIMIT 1];
		list<Billing_Account__c> bAccs = billingAccountController.getBillingAccounts(billAccount.Account__c);
		Billing_Account__c bAcc = billingAccountController.getBillingAccount(bAccs.get(0).Id);
		try
		{
			billingAccountController.createBillingAccount(bAcc);
		}
		catch ( exception er )
		{
		}
		test.stopTest();
	}
}