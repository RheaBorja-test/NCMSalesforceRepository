public class accountingBridgeControllers
{
	//  this class is filled with the universal utilities for the Accounting Bridge
	//  it contains methods to be invoked by the batches or other classes
	//  still in the process of moving all utils here
	public boolean debug = false;
	public Id ffCompanyId;

	public Id companyCurrencyId;

	public Id defaultProcessorId;

	public id pmtPeriodId;

	// -------- Create Invoice Methods --------
	// this method converts a billing account record into a sales invoice record with a custom invoice date / period
	public c2g__codaInvoice__c createInvoice(Billing_Account__c bAcc, date invDate, id dim1, id dim2)
	{
		getCompanyInfo(  );
		c2g__codaInvoice__c salesInvoice = populateInv(bAcc, null);
		salesInvoice.c2g__Period__c = getPeriod(invDate);
		salesInvoice.c2g__InvoiceDate__c = invDate;
		salesInvoice.c2g__Dimension1__c = dim1;
		salesInvoice.c2g__Dimension2__c = dim2;

		return salesInvoice;
	}

	// this method converts a billing account record into a sales invoice record with a custom invoice date / period
	public c2g__codaInvoice__c createInvoice(Billing_Account__c bAcc, date invDate, id dim1, id dim2, string billingNotes)
	{
		getCompanyInfo(  );
		c2g__codaInvoice__c salesInvoice = populateInv(getBacc(bAcc.Id), billingNotes);
		salesInvoice.c2g__Period__c = getPeriod(invDate);
		salesInvoice.c2g__InvoiceDate__c = invDate;
		salesInvoice.c2g__Dimension1__c = dim1;
		salesInvoice.c2g__Dimension2__c = dim2;

		return salesInvoice;
	}

	// this method converts a billing account id into a sales invoice record with a custom invoice date / period
	public c2g__codaInvoice__c createInvoice(id bAccId, date invDate, id dim1, id dim2)
	{
		return createInvoice(getBacc(bAccId), invDate, dim1, dim2);
	}

	//  this method takes a billing account and loads a sales invoice record
	private c2g__codaInvoice__c populateInv(Billing_Account__c bAcc, string billingNotes)
	{
		Id taxCode;
		String ffAccountRef;
		c2g__codaInvoice__c salesInvoice = new c2g__codaInvoice__c(  );

		salesInvoice.c2g__Account__c = bAcc.Account__c;
		salesInvoice.Billing_Account__c = bAcc.Id;
		salesInvoice.c2g__InvoiceStatus__c = 'In Progress';
		salesInvoice.c2g__TaxCode1__c = taxCode;
		salesInvoice.c2g__OwnerCompany__c = ffCompanyId;
		salesInvoice.c2g__InvoiceCurrency__c = companyCurrencyId;
		salesInvoice.c2g__CopyAccountValues__c = false;  // disable copy of tax code details from account record
		salesInvoice.c2g__CustomerReference__c = ffAccountRef;

		salesInvoice.Billing_Street__c = bAcc ?.Billing_Street__c;
		salesInvoice.Billing_City__c = bAcc ?.Billing_City__c;
		salesInvoice.Billing_State__c = bAcc ?.Billing_State_Province__c;
		salesInvoice.Billing_Zip_Code__c = bAcc ?.Billing_Zip_Postal_Code__c;
		salesInvoice.Billing_Country__c = bAcc ?.Billing_Country__c;

		return salesInvoice;
	}

	//  this method is called if only the bAccId was provided. Should include all fields that will be needed in the populateInv method
	public Billing_Account__c getBacc(id bAccId)
	{
		Billing_Account__c bAcc = [SELECT id, Account__c, Primary_Contact__c, Billing_Street__c, Billing_City__c, Billing_State_Province__c, Billing_Zip_Postal_Code__c, Billing_Country__c
		                           FROM Billing_Account__c
		                           WHERE id = :bAccId];
		return bAcc;
	}

	//  -------- Create Line Item Methods --------
	//  this method converts a list of Bill Prods into Line Items, but without the Invoice linked
	public list<c2g__codaInvoiceLineItem__c> createLineItem(list<Billing_Product__c> bProds)
	{
		list<c2g__codaInvoiceLineItem__c> lnItms = new list<c2g__codaInvoiceLineItem__c>();

		for ( Billing_Product__c bProd : bProds )
		{
			lnitms.add(convertBillProd(bProd));
		}

		return lnItms;
	}

	//  this method converts a list of line items into line Items, including the connection to the Invoice
	public list<c2g__codaInvoiceLineItem__c> createLineItem(list<Billing_Product__c> bProds, id invId)
	{
		list<c2g__codaInvoiceLineItem__c> lnItms = new list<c2g__codaInvoiceLineItem__c>();

		for ( Billing_Product__c bProd : bProds )
		{
			c2g__codaInvoiceLineItem__c lnItm = convertBillProd(bProd);
			lnItm.c2g__Invoice__c = invId;
			lnitms.add(lnItm);
		}

		return lnItms;
	}

	//  this method converts a billing product into a line item, but without the connection to the invoice
	public c2g__codaInvoiceLineItem__c createLineItem(Billing_Product__c bProd)
	{
		return convertBillProd(bProd);
	}

	//  this method converts a billing product into a line item, including the connection to the Invoice
	public c2g__codaInvoiceLineItem__c createLineItem(Billing_Product__c bProd, id invId)
	{
		c2g__codaInvoiceLineItem__c lnItm = convertBillProd(bProd);
		lnItm.c2g__Invoice__c = invId;

		return lnItm;
	}

	//  this method takes a billing product and returns a Line Item
	//  NOTE: This does not populate the Sales Invoice Id field. That will need to be handled by the method that calls this one
	private c2g__codaInvoiceLineItem__c convertBillProd(Billing_Product__c bProd)
	{
		c2g__codaInvoiceLineItem__c lnItm = new c2g__codaInvoiceLineItem__c(  );

		lnItm.c2g__Product__c = bProd.Product__c;
		lnItm.c2g__DeriveUnitPriceFromProduct__c = false;
		lnItm.c2g__Quantity__c = bProd.Quantity__c;
		lnItm.c2g__LineDescription__c = bProd.Description__c;
		lnItm.c2g__UnitPrice__c = bProd.Value__c;

		lnItm.c2g__TaxValue1__c = 0;
		lnItm.c2g__DeriveTaxRate1FromCode__c = false;
		lnItm.c2g__CalculateTaxValue1FromRate__c = false;

		lnItm.Billing_Product__c = bProd.id;

		lnItm.c2g__Dimension1__c = bProd.Dimension_1__c;
		lnItm.c2g__Dimension2__c = bProd.Dimension_2__c;
		lnItm.c2g__Dimension3__c = bProd.Dimension_3__c;
		lnItm.c2g__Dimension4__c = bProd.Dimension_4__c;

		return lnItm;
	}

	//  -------- Check Next Billing Date Methods --------
	//  this method checks the next bill date based on today
	public Billing_Product__c chkNextBill(Billing_Product__c bProd)
	{
		return chkNextBill(bProd, date.today(  ));
	}

	public Billing_Product__c chkNextBill(Billing_Product__c bProd, date invDate)
	{
		bProd.Last_Billed_Date__c = date.today(  );

		//  checks frequency for whether or not it needs to be set to inactive
		if ( bProd.Billing_Frequency__c != 'One-Time' )
		{
			bProd.Next_Billing_Date__c = getDate(bProd.Billing_Frequency__c, invDate, bProd.Recurring_Billing_Day__c);
		}
		else
		{
			bProd.Billing_Product_Status__c = 'Inactive';
		}

		//  this is the final bill date logic. If the next bill date is greater than the final bill date then it will set the status to inactive
		//  this works in conjunction with the Process Builder that will inactivate the product if the date is set to today / earlier, or when the date elapses
		if ( bProd.Final_Bill_Date__c != null && bProd.Final_Bill_Date__c < bProd.Next_Billing_Date__c )
		{
			bProd.Billing_Product_Status__c = 'Inactive';
		}

		return bProd;
	}

	//  this method calculates the next bill date based on the invoice date and the recurrence
	private date getDate(string recurrence, date invDate, decimal DOM)
	{
		integer mnth;
		integer yr;

		if ( recurrence == 'Monthly' )
		{
			mnth = invDate.addMonths(1).month();
			yr = invDate.addMonths(1).year();
		}
		else if ( recurrence == 'Quarterly' )
		{
			mnth = invDate.month();
			if(mnth <=3){
				mnth = 4;
				yr = invDate.year();
			} else if( mnth <= 6){
				mnth = 7;
				yr = invDate.year();
			} else if(mnth <= 9){
				mnth = 10;
				yr = invDate.year();
			} else {
				mnth = 1;
				yr = invDate.addYears(1).year();
			}
		}
		else if ( recurrence == 'Annually' )
		{
			mnth = invDate.addYears(1).month();
			yr = invDate.addYears(1).year();
		}

		return date.newInstance(yr, mnth, integer.valueof(DOM));
	}

	//  -------- Financial Force Variable Loading Methods
	private id getPeriod(date invDate)
	{
		c2g__codaPeriod__c[] periods = [SELECT Id, c2g__StartDate__c, c2g__EndDate__c, c2g__PeriodNumber__c
		                                FROM c2g__codaPeriod__c
		                                WHERE c2g__OwnerCompany__c = :ffCompanyId AND c2g__StartDate__c <= :invDate AND c2g__EndDate__c >= :invDate
		                                ORDER BY c2g__EndDate__c Desc];
		pmtPeriodId = periods[0].Id;
		if ( debug )
			System.Debug('pmtPeriod : ' + periods[0]);
		return pmtPeriodId;
	}

	private void getCompanyInfo()
	{
		
		if ( ffCompanyId == null )
		{
			List<c2g__codaCompany__c> ffCompanyList = new List<c2g__codaCompany__c>();
			ffCompanyList = [SELECT Name, Id, CreatedDate
			                 FROM c2g__codaCompany__c
			                 ORDER BY CreatedDate ASC
			                 LIMIT 1];
			ffCompanyId = ffCompanyList[0].Id;
			if ( debug )
				System.Debug('ffCompanyId : ' + ffCompanyId);
		}

		if ( companyCurrencyId == null )
		{
			c2g__codaAccountingCurrency__c[] currencies = [SELECT c2g__OwnerCompany__c, Name
			                                               FROM c2g__codaAccountingCurrency__c
			                                               WHERE Name = 'USD'];
			companyCurrencyId = currencies[0].id;
			if ( debug )
				System.Debug('companyCurrencyId : ' + companyCurrencyId);
		}
	}
}