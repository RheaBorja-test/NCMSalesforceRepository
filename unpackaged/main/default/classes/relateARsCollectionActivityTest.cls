@isTest(SeeAllData = true)
public class relateARsCollectionActivityTest{
	static testMethod void TestrelateARsCollectionActivity(){
		test.startTest();
		Client_Support_Ticket__c cse = [select id, Account__c
		                                from Client_Support_Ticket__c 
		                                where Status__c = 'In Progress'
		                                limit 1];
		list<Finance_Accounts_Receivable__c> ARs = [select id
		                                            from Finance_Accounts_Receivable__c 
		                                            where Collection_Activity__c = :cse.Id];
		for (Finance_Accounts_Receivable__c AR : ARs){
			ar.Collection_Activity__c = null;
		}
		update ARs;
		relateARsCollectionActivity.vars var = new relateARsCollectionActivity.vars();
		var.caId = cse.id;
		var.accId = cse.Account__c;
		var.daysOutstanding = 35;
		List<relateARsCollectionActivity.vars> vars = new List<relateARsCollectionActivity.vars>();
		vars.add(var);
		try{
			relateARsCollectionActivity.relateToAllARs(vars);
		} catch (exception er){
			system.debug(er);
		}
		test.stopTest();
	}
}