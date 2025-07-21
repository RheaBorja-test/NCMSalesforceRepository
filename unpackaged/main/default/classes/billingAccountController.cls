public class billingAccountController {

	@AuraEnabled
	public static List<Billing_Account__c> getBillingAccounts(id accId) {
		List<Billing_Account__c> baccs = [select Id, Name, Account__c, Primary_Contact__c, 
                                            Billing_Street__c, Billing_City__c, Billing_State_Province__c, Billing_Country__c, Billing_Zip_Postal_Code__c
									      from Billing_Account__c
									      where Account__c = :accId and recordTypeId = '0124A000001BVDBQA4' and Status__c = 'Validated'
									      order by Name];
		if(baccs.size() > 0) {
			return baccs;
		} else {
			return null;
		}
	}

	@AuraEnabled
	public static Billing_Account__c getBillingAccount(string billAccId) {

        Billing_Account__c billAcc;

		DescribeSObjectResult describeResult = Billing_Account__c.getSObjectType().getDescribe();
		List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
		String query =
		' SELECT ' +
		String.join(fieldNames, ', ') +
		' FROM ' +
		describeResult.getName() +
		' WHERE id = \'' + billAccId + '\'';

		billAcc = Database.query(query);

		return billAcc;
	}

	@AuraEnabled
	public static Billing_Account__c createBillingAccount(Billing_Account__c bAcc) {
		try{
			upsert bAcc;
		} catch(Exception er) {
			throw new AuraHandledException('er');
		}

		return bAcc;
	}
}