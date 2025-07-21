public with sharing class payableBridge
{
	@AuraEnabled
	public static List<AggregateResult> getPayAccs(date fromDate, date toDate, string pymtMethod)
	{
		string expWhere = formulateWhere(fromDate, toDate, pymtMethod);

		string qry = 'SELECT SUM(Amount__c) total, COUNT(Id) recs, Payable_Account__c, Payable_Account__r.Name';
		qry = qry + ' FROM Engagement_Expense__c';
		qry = qry + expWhere;
		qry = qry + ' GROUP BY Payable_Account__c, Payable_Account__r.Name';

		list<AggregateResult> aggResults = Database.query(qry);
		if ( aggResults.size() > 0 )
		{
			return aggResults;
		}
		else
		{
			return null;
		}
	}

	@AuraEnabled
	public static Billing_Account__c getPayAcc(string recId)
	{
		Billing_Account__c payAcc;
		try
		{
			payAcc = [select 
			                id, 
			                Name, Account__c, 
			                Primary_Contact__c, 
			                Primary_Contact__r.Name, Billing_Street__c, 
			                Billing_City__c, 
			                Billing_State_Province__c, 
			                Billing_Country__c, 
			                Billing_Zip_Postal_Code__c
			          from Billing_Account__c 
			          where id = :recId];
		}
		catch ( exception er )
		{
			system.debug(er);
		}

		if ( payAcc != null )
		{
			return payAcc;
		}
		else
		{
			return null;
		}
	}

	@AuraEnabled
	public static List<Engagement_Expense__c> getExpenses(string payAccId, date fromDate, date toDate, string pymtMethod)
	{
		string expWhere = formulateWhere(fromDate, toDate, pymtMethod);
		expWhere = expWhere + ' AND Payable_Account__c = :payAccId';

		string qry = 'select id, Name, Expense_URL__c, Expense_Description__c, Amount__c,';
		qry = qry + ' Transaction_Date__c, GL_Name__c, General_Ledger_Id__c, Engagement__c,';
		qry = qry + ' Dimension_1__c, Dimension_1_Name__c, Dimension_2__c, Dimension_2_Name__c,';
		qry = qry + ' Dimension_3__c, Dimension_3_Name__c, Dimension_4__c, Dimension_4_Name__c';
		qry = qry + ' from Engagement_Expense__c' + expWhere;

		List<Engagement_Expense__c> exps = Database.query(qry);

		if ( exps.size() > 0 )
		{
			return exps;
		}
		else
		{
			return null;
		}
	}

	@AuraEnabled
	public static c2g__codaPurchaseInvoice__c buildPIN(Billing_Account__c payAcc)
	{
		c2g__codaPurchaseInvoice__c PIN = new c2g__codaPurchaseInvoice__c(  );

		PIN.c2g__Account__c = payAcc.Account__c;
		PIN.Primary_Contact__c = payAcc.Primary_Contact__c;
		PIN.Payable_Account__c = payAcc.id;
		PIN.c2g__InvoiceDate__c = date.today(  );

		PIN.Street__c = payAcc.Billing_Street__c;
		PIN.City__c = payAcc.Billing_City__c;
		PIN.State__c = payAcc.Billing_State_Province__c;
		PIN.Country__c = payAcc.Billing_Country__c;
		PIN.Postal_Code__c = payAcc.Billing_Zip_Postal_Code__c;

		string tmeZne = UserInfo.getTimeZone().toString();
		string nme = Datetime.now().format('YYMM:HH', tmeZne)+' ' + payAcc.Name;

		PIN.c2g__AccountInvoiceNumber__c = nme.left(25);

		return PIN;
	}

	@AuraEnabled
	public static list<id> createPIN(c2g__codaPurchaseInvoice__c pin, List<Engagement_Expense__c> exps, boolean updatePayAcc)
	{
		integer batchLimit = 20;

		for ( Engagement_Expense__c exp : exps )
		{
			if ( exp.Dimension_1__c == null || exp.Dimension_2__c == null )
			{
				throw new AuraHandledException('Not all Expenses have Dimension 1 & 2. Please ensure they are all populated and try creating again.');
			}
		}

		if ( updatePayAcc == true )
		{
			updatePayAcc( pin, pin.Payable_Account__c );
		}

		try
		{
			insert pin;
		}
		catch ( DmlException er )
		{
			System.debug(er);
			throw new AuraHandledException(er.getMessage());
		}

		List<c2g__codaPurchaseInvoiceExpenseLineItem__c> lnItms = createLnItems(exps, pin.Id);

		list<id> retIds = new list<Id>();
		retIds.add(pin.Id);
		if ( lnItms.size() <= batchLimit )
		{
			try
			{
				insert lnItms;
			}
			catch ( DmlException er )
			{
				System.debug(er);
				throw new AuraHandledException(er.getMessage());
			}
		}
		else
		{
			batchPINexpLines btchLines = new batchPINexpLines( lnItms );
			id batchId = Database.executebatch(btchLines, batchLimit);
			retIds.add(batchId);
			system.debug(retIds);
		}

		return retIds;
	}

	@AuraEnabled
	public static AsyncApexJob getBatchStatus(Id batchId)
	{
		AsyncApexJob aaj = [SELECT 
		                          Id, 
		                          Status, 
		                          JobItemsProcessed, 
		                          TotalJobItems, 
		                          NumberOfErrors, 
		                          ExtendedStatus, 
		                          MethodName, 
		                          CreatedBy.Name, CreatedDate
		                    FROM AsyncApexJob 
		                    WHERE ID = :batchId];

		return aaj;
	}

	private static void updatePayAcc(c2g__codaPurchaseInvoice__c PIN, id payAccId)
	{
		Billing_Account__c payAcc = new Billing_Account__c(  );

		payAcc.id = payAccId;
		payAcc.Billing_Street__c = PIN.Street__c;
		payAcc.Billing_City__c = PIN.City__c;
		payAcc.Billing_State_Province__c = PIN.State__c;
		payAcc.Billing_Country__c = PIN.Country__c;
		payAcc.Billing_Zip_Postal_Code__c = PIN.Postal_Code__c;

		update payAcc;
	}

	private static List<c2g__codaPurchaseInvoiceExpenseLineItem__c> createLnItems(List<Engagement_Expense__c> exps, id pinId)
	{
		List<c2g__codaPurchaseInvoiceExpenseLineItem__c> lnItms = new List<c2g__codaPurchaseInvoiceExpenseLineItem__c>();

		for ( Engagement_Expense__c exp : exps )
		{
			c2g__codaPurchaseInvoiceExpenseLineItem__c lnItm = new c2g__codaPurchaseInvoiceExpenseLineItem__c(  );

			lnItm.c2g__PurchaseInvoice__c = pinId;
			lnItm.Engagement_Expense__c = exp.id;

			lnItm.c2g__GeneralLedgerAccount__c = exp.General_Ledger_Id__c;
			lnItm.Transaction_Date__c = exp.Transaction_Date__c;
			lnItm.c2g__NetValue__c = exp.Amount__c;
			lnItm.c2g__LineDescription__c = exp.Expense_Description__c;

			lnItm.c2g__Dimension1__c = exp.Dimension_1__c;
			lnItm.c2g__Dimension2__c = exp.Dimension_2__c;
			lnItm.c2g__Dimension3__c = exp.Dimension_3__c;
			lnItm.c2g__Dimension4__c = exp.Dimension_4__c;

			lnitms.add(lnItm);
		}

		return lnItms;
	}

	private static string formulateWhere(date fromDate, date toDate, string pymtMethod)
	{
		string expWhere = ' WHERE Payable_Invoice_Expense_Line_Item__c = NULL AND Discarded__c = FALSE ';
		expWhere = expWhere + ' AND Payable_Account__c != NULL and Payable_Account__r.Status__c = \'Validated\'';

		if ( fromDate != null )
		{
			expWhere = expWhere + ' AND Transaction_Date__c >= :fromDate';
		}
		if ( toDate != null )
		{
			expWhere = expWhere + ' AND Transaction_Date__c <= :toDate';
		}
		if ( pymtMethod != 'None' )
		{
			expWhere = expWhere + ' AND Payment_Type_Name__c = :pymtMethod';
		}

		return expWhere;
	}
}