public class createCollectionActivity implements Schedulable
{
	public void execute(SchedulableContext sc)
	{
		list<Account> accsNeedingCA = getAccsToCreate();
		List<Client_Support_Ticket__c> newClientCases = new List<Client_Support_Ticket__c>();

		for ( Account acc : accsNeedingCA )
		{
			Client_Support_Ticket__c clientCase = new Client_Support_Ticket__c(  );
			clientCase.Account__c = acc.Id;
			clientCase.Contact__c = acc.c2g__CODAFinanceContact__c;
			clientCase.Description__c = 'This Account is now in Collections. Please get all Invoices to a paid status';
			clientCase.RecordTypeId = '0124A000001NTPoQAO';
			clientCase.OwnerId = '0054A000009kI8vQAE';
			clientCase.Status__c = 'Open';
			clientCase.Name = 'CA - ' + acc.Name;

			newClientCases.add(clientCase);
		}

		if ( newClientCases.size() > 0 )
		{
			Database.insert( newClientCases, false );
		}
	}

	private static list<Account> getAccsToCreate()
	{

		List<AggregateResult> fArs = [SELECT COUNT( Id )recs, Account__c
		                              FROM Finance_Accounts_Receivable__c
		                              WHERE Days_Outstanding_Calc__c >= 35 and Invoice_Status__c<>'Discarded' and Payment_Status__c<>'Paid' and Payment_Status__c<>'Not Applicable' and Collection_Activity__c = null
		                              GROUP BY Account__c];

		set<Id> fArsAccIds = new set<Id>();
		for ( AggregateResult fAr : fArs )
		{
			fArsAccIds.add(( Id )fAr.get('Account__c'));
		}

		List<Client_Support_Ticket__c> clientCases = [SELECT Id, Account__c
		                                              FROM Client_Support_Ticket__c
		                                              WHERE recordType.Name = 'Collection Activity' and Status__c<>'Complete'];
		set<Id> ccAccIds = new set<Id>();
		for ( Client_Support_Ticket__c cc : clientCases )
		{
			ccAccIds.add(cc.Account__c);
		}

		list<Account> accs = [SELECT id, Name, c2g__CODAFinanceContact__c, Finance_Contact_ID__c
		                      FROM Account
		                      WHERE Do_not_Include_in_Collections__c = false and id in :fArsAccIds and id not in :ccAccIds
		                      ORDER BY Name
		                      LIMIT 500];
		if ( accs.size() > 0 )
		{
			return accs;
		}
		else
		{
			return null;
		}
	}
}