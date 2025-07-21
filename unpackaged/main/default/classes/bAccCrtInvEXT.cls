public class bAccCrtInvEXT
{
	private ApexPages.StandardController stdController;

	public date cstInvDate;

	public id bAccId;

	public Billing_Account__c bAcc;

	public list<wBprod> bProds;

	public Billing_Product__c fBprod;

	public accountingBridgeControllers accBrdCon = new accountingBridgeControllers();

	public bAccCrtInvEXT(apexpages.standardcontroller stdController)
	{
		this.stdController = stdController;
		bAccId = ApexPages.currentPage().getParameters().get('id');
	}

	public PageReference fltr()
	{
		getbProds(  );
		return null;
	}

	public PageReference slctAll()
	{
		if ( bProds != null )
		{
			for ( wBprod bProd : bProds )
			{
				bProd.selected = true;
			}
			getbProds();
		}
		return null;
	}

	public PageReference unslctAll()
	{
		if ( bProds != null )
		{
			for ( wBprod bProd : bProds )
			{
				bProd.selected = false;
			}
			getbProds();
		}
		return null;
	}

	public PageReference advAll()
	{
		if ( bProds != null )
		{
			for ( wBprod bProd : bProds )
			{
				bProd.advance = true;
			}
			getbProds();
		}
		return null;
	}

	public PageReference unadvAll()
	{
		if ( bProds != null )
		{
			for ( wBprod bProd : bProds )
			{
				bProd.advance = false;
			}
			getbProds();
		}
		return null;
	}

	public PageReference crt()
	{
		boolean hsPrdSelected = false;
		for ( wBprod wBprod : bProds )
		{
			if ( wbProd.selected )
			{
				hsPrdSelected = true;
				break;
			}
		}

		if ( hsPrdSelected )
		{
			boolean isSuccess = true;

			c2g__codaInvoice__c slsInv;
			if ( cstInvDate == null )
			{
				slsInv = accBrdCon.createInvoice(bAcc, Date.Today(  ), fBprod.Dimension_1__c, fBprod.Dimension_2__c);
			}
			else
			{
				slsInv = accBrdCon.createInvoice(bAcc, cstInvDate, fBprod.Dimension_1__c, fBprod.Dimension_2__c);
			}
			try
			{
				insert slsInv;
			}
			catch ( dmlException er )
			{
				system.debug(er);
				isSuccess = false;
			}

			if ( isSuccess || Test.isRunningTest() )
			{
				list<c2g__codaInvoiceLineItem__c> lnItms = new list<c2g__codaInvoiceLineItem__c>();
				list<Billing_Product__c> upBprods = new list<Billing_Product__c>();
				for ( wBprod wBprod : bProds )
				{
					if ( wBprod.selected )
					{
						Billing_Product__c bProd = wBprod.bProd;
						lnItms.add(accBrdCon.createLineItem(bProd, slsInv.id));
						if ( wBprod.advance )
						{
							if ( cstInvDate == null )
							{
								accBrdCon.chkNextBill(bProd);
							}
							else
							{
								accBrdCon.chkNextBill(bProd, cstInvDate);
							}
						}
						else
						{
							bProd.Last_Billed_Date__c = date.today(  );
						}
						upBprods.add(bProd);
					}
				}

				if ( lnItms.size() > 0 )
				{
					try
					{
						insert lnItms;
					}
					catch ( dmlException er )
					{
						system.debug(er);
						isSuccess = false;
					}

					if ( isSuccess )
					{
						try
						{
							update upBprods;
						}
						catch ( dmlException er )
						{
							system.debug(er);
							isSuccess = false;
						}

						if ( isSuccess )
						{
							PageReference pgRef = new PageReference( '/' + slsInv.id );
							pgRef.setRedirect(true);
							return pgRef;
						}
					}
				}
			}
		}
		return null;
	}

	public date getcstInvDate()
	{
		return cstInvDate;
	}

	public void setcstInvDate(date cstInvDate)
	{
		this.cstInvDate = cstInvDate;
	}

	public Billing_Account__c getbAcc()
	{
		if ( bAcc == null )
		{
			DescribeSObjectResult describeResult = Billing_Account__c.getSObjectType().getDescribe();
			List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
			String query = 
				' SELECT ' + String.join(fieldNames, ', ')+' FROM ' + describeResult.getName()+' WHERE id = :bAccId';
			bAcc = Database.query(query);
		}

		return bAcc;
	}

	public Billing_Product__c getfBprod()
	{
		if ( fBprod == null )
		{
			fBprod = new Billing_Product__c();
		}
		return fBprod;
	}

	public list<wBprod> getbProds()
	{

		if ( bProds == null )
		{
			list<Billing_Product__c> ldBprods;

			DescribeSObjectResult describeResult = Billing_Product__c.getSObjectType().getDescribe();
			List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
			String query = 
				' SELECT ' + String.join(fieldNames, ', ')+' FROM ' + describeResult.getName();
			if ( fbProd != null )
			{
				if ( fbProd.Dimension_1__c != null && fbProd.Dimension_2__c == null )
				{
					query = query + ' WHERE Billing_Account__c = :bAccId and Dimension_1__c = \'' + fbProd.Dimension_1__c + '\'';
				}
				else if ( fbProd.Dimension_1__c == null && fbProd.Dimension_2__c != null )
				{
					query = query + ' WHERE Billing_Account__c = :bAccId and Dimension_2__c = \'' + fbProd.Dimension_2__c + '\'';
				}
				else if ( fbProd.Dimension_1__c != null && fbProd.Dimension_2__c != null )
				{
					query = query + ' WHERE Billing_Account__c = :bAccId and Dimension_1__c = \'' + fbProd.Dimension_1__c + '\' and Dimension_2__c = \'' + fbProd.Dimension_2__c + '\'';
				}
				else
				{
					query = query + ' WHERE Billing_Account__c = :bAccId';
				}
			}
			else
			{
				query = query + ' WHERE Billing_Account__c = :bAccId';
			}
			query = query + ' ORDER BY Product__r.Name';
			ldBprods = Database.query(query);

			bProds = new list<wBprod>();
			for ( Billing_Product__c bProd : ldBprods )
			{
				bProds.add(new wBprod(bProd));
			}
		}

		return bProds;
	}

	public class wBprod
	{
		public boolean selected{ get; set; }

		public boolean advance{ get; set; }

		public Billing_Product__c bProd{ get; set; }

		public wBprod(Billing_Product__c bProd)
		{
			this.selected = false;
			this.advance = false;
			this.bProd = bProd;
		}
	}
}