public class batchAccountingBridge implements Database.Batchable<sObject>
{
	//  This class is the batched Accounting Bridge used for converting Billing Accounts & Products into Sales Invoices
	//  Due to the processing power of FinancialForce, this has been optimized to run for 1 Sales Invoice at a time
	//  In order to accommodate the limitation, Billing Configuration Details are the records that are iterated
	public string query;

	//  This set is built in the Execute, then deleted in the Finish method
	public set<Billing_Configuration__c> delBconfigs = new set<Billing_Configuration__c>();

	//  This list is built in the Execute, then deleted in the Finish method
	public list<Billing_Configuration_Detail__c> bConfigDets = new list<Billing_Configuration_Detail__c>();

	//  This list is used for collecting any errors, and are merged into the finish email sent out after the batch is complete
	public list<errorLog> errors = new list<errorLog>();

	//  This loads the Accounting Bridge Controllers which house all the conversion methods for bAccs & bProds
	public accountingBridgeControllers accBrdCon = new accountingBridgeControllers(  );
	// This variable is used for testing only. Since testing is done in a virtual environment, it can't utilize the External Id Value since the SINs aren't actually inserted
	public Id compId = [SELECT Id FROM c2g__codaCompany__c WHERE Name = 'NCM Associates, Inc.' LIMIT 1].Id;
	public c2g__codaInvoice__c genInv = 
	[
		SELECT Id
		FROM c2g__codaInvoice__c
		WHERE 
			c2g__InvoiceStatus__c<>'Completed' AND 
			c2g__OwnerCompany__c = :compId
		ORDER BY CreatedDate DESC
		LIMIT 1
	];
	public boolean failTest;

	//  The batch initiation that loads all the bConfigDets that will be in scope
	public database.Querylocator start(Database.BatchableContext bC)
	{
		query = 'SELECT id, Billing_Account__c, Billing_Configuration__c, Billing_Configuration__r.One_Time_Run__c, Don_t_Add_Processor_Information__c, Billing_Notes__c,' + 
				' Billing_Configuration__r.Custom_Invoice_Date__c, CEM_Id__c, Dimension_1__c, Dimension_2__c,Billing_Configuration__r.Invoice_Description__c,' + 
				' Billing_Configuration__r.Split_on_Dim_2__c, Billing_Configuration__r.Billing_Product_WHERE__c, Billing_Configuration__r.Split_on_CEM__c,' + 
				' Billing_Account__r.Primary_Contact__c, Billing_Account__r.Id, Billing_Account__r.Account__c ' + 
				' FROM Billing_Configuration_Detail__c';
		Database.QueryLocator result = Database.getQueryLocator(query);
		return result;
	}

	//  The Batch iteration method. This should be repeated 1-1 for bConfigDets (i.e. SINs). However, it has been optimized to have the batch size expanded in the future
	public void execute(Database.BatchableContext bC, List<sObject> scope)
	{

		//  List to hold Sales Invoices to be inserted at end of execute
		list<c2g__codaInvoice__c> slsInvs = new list<c2g__codaInvoice__c>();
		//  List to hold Line Item records with external Invoice to be inserted at end of execute
		list<c2g__codaInvoiceLineItem__c> inLnItms = new list<c2g__codaInvoiceLineItem__c>();
		//  List of Billing Products to be updated if the insertion of the Line Items is successful
		List<Billing_Product__c> bProds = new List<Billing_Product__c>();

		//  Iterate over Billing Configuraiton Detail
		for ( Sobject obj : scope )
		{
			Billing_Configuration_Detail__c bConfigDet = ( Billing_Configuration_Detail__c )obj;
			bConfigDets.add(bConfigDet);
			boolean splitOnDim2 = bConfigDet.Billing_Configuration__r.Split_on_Dim_2__c;
			boolean splitOnCEM = bConfigDet.Billing_Configuration__r.Split_on_CEM__c;

			system.debug(bConfigDet.Billing_Configuration__r.Billing_Product_WHERE__c);

			//  Get Billing Account with Products to translate
			string query = 'SELECT id, Name, Primary_Contact__c, Account__c, ( ';
			query = query + 'SELECT id, name, Dimension_1__c, Dimension_2__c, Dimension_3__c, Dimension_4__c, ';
			query = query + 'Product__c, Description__c, Value__c, CEM_Id__c, Next_Billing_Date__c, Billing_Product_Status__c, ';
			query = query + 'Last_Billed_Date__c, Quantity__c, Billing_Frequency__c, Recurring_Billing_Day__c, Final_Bill_Date__c ';
			query = query + 'FROM Billing_Account__c.Billing_Products__r ';
			query = query + bConfigDet.Billing_Configuration__r.Billing_Product_WHERE__c + ') ';
			query = query + 'FROM Billing_Account__c ';
			query = query + 'WHERE id = \'' + bConfigDet.Billing_Account__c + '\' ';

			Billing_Account__c bAcc = Database.query(query);
			id dim1Id = bConfigDet.Dimension_1__c;

			//  Convert Billing Account to Sales Invoice
			c2g__codaInvoice__c inv;
			//  If a custom Sales Invoice Date was provided, pass Date else Today will be used
			Billing_Account__c tempBAcc = accBrdCon.getBacc(bAcc.Id);
			if ( bConfigDet.Billing_Configuration__r.Custom_Invoice_Date__c == null )
			{
				inv = accBrdCon.createInvoice(tempBAcc, Date.Today(  ), dim1Id, bConfigDet.Dimension_2__c, bConfigDet.Billing_Notes__c);
			}
			else
			{
				inv = accBrdCon.createInvoice(tempBAcc, bConfigDet.Billing_Configuration__r.Custom_Invoice_Date__c, dim1Id, bConfigDet.Dimension_2__c, bConfigDet.Billing_Notes__c);
			}
			//  Set Bridge External Id field to the bConfigDet Id. This allows us to create the Line Items and utilize the External Id as the joining instead of the Sales Invoice Id
			inv.BridgeExtId__c = bConfigDet.id;
			inv.c2g__InvoiceDescription__c = bConfigDet.Billing_Configuration__r.Invoice_Description__c;
			slsInvs.add(inv);

			//  Create inner Loop list
			list<Billing_Product__c> addBprods = new list<Billing_Product__c>();
			//  Loop through Billing Products, adding the products that meet the criteria of the bConfigDet
			for ( Billing_Product__c bProd : bAcc.Billing_Products__r )
			{
				if ( !splitOnDim2 && !splitOnCEM )
				{
					addBprods.add(bProd);
				}
				else if ( !splitOnDim2 && splitOnCEM && bProd.CEM_Id__c == bConfigDet.CEM_Id__c )
				{
					addBprods.add(bProd);
				}
				else if ( splitOnDim2 && bProd.Dimension_2__c == bConfigDet.Dimension_2__c && !splitOnCEM )
				{
					addBprods.add(bProd);
				}
				else if ( splitOnDim2 && bProd.Dimension_2__c == bConfigDet.Dimension_2__c && splitOnCEM && bProd.CEM_Id__c == bConfigDet.CEM_Id__c )
				{
					addBprods.add(bProd);
				}
			}
			//  Add InnerLoop list to OuterLoop List
			bProds.addAll(addBprods);

			//  Create inner loop list
			list<c2g__codaInvoiceLineItem__c> addInLnItms = accBrdCon.createLineItem(addBprods);
			//  Populate related Invoice Id. Different depeneding on Test running

			//  Create a virtual record referencing the External Id only
			c2g__codaInvoice__c invRef = new c2g__codaInvoice__c(  );
			invRef.BridgeExtId__c = bConfigDet.id;
			if ( !Test.isRunningTest() )
			{
				//  Set all Invoice Line Items related Invoice to the virtual record
				for ( c2g__codaInvoiceLineItem__c lnItm : addInLnItms )
				{
					lnItm.c2g__Invoice__r = invRef;
				}
			}
			else
			{
				//  For testing purposes, relate the line items to the general Invoice
				If ( failTest == true )
				{
					for ( c2g__codaInvoiceLineItem__c lnItm : addInLnItms )
					{
						lnItm.c2g__Invoice__c = null;
					}

					errorLog errLg = new errorLog(  );
					errLg.errorMessage = 'Testing';
					errors.add(errLg);
				}
				else
				{
					for ( c2g__codaInvoiceLineItem__c lnItm : addInLnItms )
					{
						lnItm.c2g__Invoice__c = genInv.Id;
					}
				}
			}
			//  Add InnerLoop list to OuterLoop List
			inLnItms.addAll(addInLnItms);

			//  If this is a one-time run Billing Configuraiton, add to Delete List to be deleted in Finish method
			if ( bConfigDet.Billing_Configuration__r.One_Time_Run__c )
			{
				Billing_Configuration__c bConfig = new Billing_Configuration__c(  );
				bConfig.id = bConfigDet.Billing_Configuration__c;
				delBconfigs.add(bConfig);
			}
		}

		//  Create list of Line Item Ids, used to get proper list for checking next bill date
		list<id> lnItmIds = new list<id>();
		try
		{
			//  Insert Sales Invoices, then Line Items. Log Errors if any
			Database.insert( slsInvs, false );
			Database.SaveResult[] saveResults = Database.insert( inLnItms, true );

			for ( Database.SaveResult sr : saveResults )
			{
				if ( sr.isSuccess() )
				{
					lnItmIds.add(sr.getId());
				}
				else
				{
					// Operation failed, so get all errors
					for ( Database.Error err : sr.getErrors() )
					{
						//  Log Error Message & Type
						errorLog errLg = new errorLog(  );
						errLg.errorMessage = err.getMessage();

						errors.add(errLg);
						system.debug(err.getMessage());
					}
				}
			}
		}
		catch ( Exception er )
		{
			//  Log Error Message & Type
			errorLog errLg = new errorLog(  );
			errLg.errorType = ( String )er.getTypeName();
			errLg.errorMessage = ( String )er.getMessage();

			errors.add(errLg);
			system.debug(er.getMessage());
		}

		//  Create Update List
		list<Billing_Product__c> updateBillingProducts = new list<Billing_Product__c>();
		//  Get Invoice Line Items with Billing Product Id & Invoice Date for use in Check Next Bill Date
		inLnItms = [SELECT id, Billing_Product__c, c2g__Invoice__r.c2g__InvoiceDate__c
		            FROM c2g__codaInvoiceLineItem__c
		            WHERE id in :lnItmIds];
		//  Loop through Line Items and get updated Next Bill Date for Billing Products
		for ( c2g__codaInvoiceLineItem__c lnItm : inLnItms )
		{
			//  Loop through OuterLoop Billing Product List to find matching one
			for ( Billing_Product__c bProd : bProds )
			{
				if ( lnItm.Billing_Product__c == bProd.id )
				{
					updateBillingProducts.add(accBrdCon.chkNextBill(bProd, lnItm.c2g__Invoice__r.c2g__InvoiceDate__c));
					//  Break bProd Loop and process next Line Item
					break;
				}
			}

		}

		//  If there are Billing Products to update, do so
		if ( updateBillingProducts.size() > 0 )
		{
			Database.SaveResult[] saveResults = Database.update( updateBillingProducts, false );
			for ( Database.SaveResult sr : saveResults )
			{
				if ( !sr.isSuccess() )
				{
					// Operation failed, so get all errors
					for ( Database.Error err : sr.getErrors() )
					{
						//  Log Error Message, Type, & Id
						errorLog errLg = new errorLog(  );
						errLg.errorMessage = err.getMessage();

						errors.add(errLg);
						system.debug(err.getMessage());
					}
				}
			}
		}
	}

	public void finish(Database.BatchableContext BC)
	{

		//  Delete Billing Configuration Details
		try
		{
			delete bConfigDets;
		}
		catch ( exception er )
		{
			system.debug(er);
		}

		//  If there are Billing Configuraitons needing to be deleted, delete them
		list<Billing_Configuration__c> delBillConfigs = new List<Billing_Configuration__c>(delBconfigs);
		try
		{
			delete delBillConfigs;
		}
		catch ( exception er )
		{
			system.debug(er);
		}

		//  Generate Completion Email
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(  );
		list<string> emails = new list<string>();
		emails.add(userinfo.getUserEmail());
		emails.add('salesforceadmin@ncmassociates.com');

		mail.setToAddresses(emails);
		mail.setReplyTo('salesforceadmin@ncmassociates.com');
		mail.setSenderDisplayName('Batch Processing');
		mail.setSubject('Accounting Batch Process Completed');

		string body = 'The Accounting Batch Process has completed';
		//  If there are errors, print errors
		body = body + '. Errors: \n \n';
		for ( errorLog errLg : errors )
		{
			body = body + 'Type: ' + errlg.errorType + '\n';
			body = body + 'Message: ' + errLg.errorMessage + '\n \n';
		}
		mail.setPlainTextBody(body);

		//  If this is not a Sandbox, send the Email
		if ( ![SELECT IsSandbox
		       FROM Organization
		       LIMIT 1].IsSandbox )
		{
			Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
		}
	}

	public class errorLog
	{
		public string errorMessage{ get; set; }

		public string errorType{ get; set; }

		public errorLog(  )
		{
		}

		public errorLog( string message )
		{
			this.errorMessage = message;
		}

		public errorLog( string message, string type )
		{
			this.errorMessage = message;
			this.errorType = type;
		}
	}
}