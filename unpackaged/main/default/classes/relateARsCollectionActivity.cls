public class relateARsCollectionActivity{
	public class vars{
		@InvocableVariable(label = 
		'Collection Activity ID'Required = true)
		public Id caId;
		@InvocableVariable(label = 
		'Account Id'Required = true)
		public id accId;
		@InvocableVariable(label = 
		'Days Outstanding'Required = true)
		public integer daysOutstanding;
	}

	@InvocableMethod
	public static void relateToAllARs(List<vars> vars){
		list<Finance_Accounts_Receivable__c> ARs = new list<Finance_Accounts_Receivable__c>();
		list<id> accIds = new List<Id>();
		integer daysOut = vars.get(0).daysOutstanding;
		for (vars var : vars){
			accIds.add(var.accId);
		}
		list<Finance_Accounts_Receivable__c> accARs = [SELECT id, Account__c
		                                               FROM Finance_Accounts_Receivable__c 
		                                               WHERE Collection_Activity__c = null and Invoice_Status__c<>'Discarded' and Payment_Status__c<>'Paid' and Payment_Status__c<>'Not Applicable' and Account__c in :accIds and Account__r.Do_not_Include_in_Collections__c = false and Days_Outstanding_Calc__c >= :daysOut
		                                               ORDER BY Account__c];
		for (Finance_Accounts_Receivable__c fAr : accARs){
			for (vars var : vars){
				if (fAr.Account__c == var.accId){
					fAr.Collection_Activity__c = var.caId;
					ARs.add(fAr);
					break;
				}
			}
		}
		if (ARs.size() > 0){
			database.update(ARs, false);
		}
	}
}