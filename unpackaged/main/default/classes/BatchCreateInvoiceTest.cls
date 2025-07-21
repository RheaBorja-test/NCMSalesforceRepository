@isTest(seeAllData = true)
private class BatchCreateInvoiceTest
{
	@isTest(SeeAllData = true)
	static void batchCreateTester() {
		user u = [SELECT Id
		          FROM User
		          WHERE IsActive = true AND Id IN 
		                 (SELECT c2g__User__c
		                  FROM c2g__codaUserCompany__c)
		          ORDER BY LastName DESC
		          LIMIT 1];

		system.runas(u) {
			// Need a product configured to work with FF create Invoice action
			Product2[] sfproducts = [SELECT Id
			                         FROM Product2
			                         WHERE IsActive = true AND c2g__CODASalesRevenueAccount__c <> null
			                         LIMIT 1];
			Product2 validProduct;
			if(sfproducts <> null && sfproducts.size() > 0) {
				validProduct = sfproducts[0];
			}
			System.assert(validproduct <> null, 'A salesforce product with FF Sales Revenue Account is required to run this test');

			Recurring_Invoice_Settings__c ncm = Recurring_Invoice_Settings__c.getValues( 'NCM Settings' );
			ncm.debug__c = true;
			User user = [SELECT Id
			             FROM User
			             WHERE IsActive = true AND Id IN 
			                    (SELECT c2g__User__c
			                     FROM c2g__codaUserCompany__c)
			             ORDER BY LastName DESC
			             LIMIT 1];
			ncm.BatchMonitorUserId__c = user.Id;
			ncm.Chain_Batches__c = true;
			update ncm;

			/* Get the standard pricebook  */
			Pricebook2 standardPB = [SELECT Id, 
			                                IsStandard
			                         FROM Pricebook2
			                         WHERE IsStandard = true];

			/* Setup PriceBook Entry */
			PricebookEntry pbe;
			List<PricebookEntry> pbeList = [SELECT Pricebook2Id, 
			                                       Product2Id, 
			                                       UnitPrice, 
			                                       isActive
			                                FROM PricebookEntry
			                                WHERE Pricebook2Id = :standardPB.Id AND Product2Id = :sfproducts[0].id
			                                LIMIT 1];
			if(pbeList != null && !pbeList.isEmpty()) {
				pbe = pbeList[0];
			} else {
				pbe = new PricebookEntry(Pricebook2Id = standardPB.Id, Product2Id = sfproducts[0].id, UnitPrice = 500, isActive = true);
				insert pbe;
			}

			List<c2g__codaCompany__c> ffCompanyList = new List<c2g__codaCompany__c>();
			ffCompanyList = [SELECT Name, 
			                        Id, 
			                        CreatedDate
			                 FROM c2g__codaCompany__c
			                 ORDER BY CreatedDate ASC
			                 LIMIT 1];
			Id ffCompanyId = ffCompanyList[0].Id;
			System.Debug('ffCompanyId : ' + ffCompanyId);

			// Correctly configured Contact
			Id gla = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c LIMIT 1].Id;
       		Account account = new Account(name = 'uniqueVal',
                                        billingStreet = '120 Birmingham Drive, Suite ',
                                        billingCity = 'San Diego',
                                        billingState = 'California',
                                        billingPostalCode = '92007',
                                        billingCountry = 'United States',
                                        shippingStreet = '120 Birmingham Drive, Suite ',
                                        shippingCity = 'San Diego',
                                        shippingPostalCode = '92007',
                                        shippingState = 'California',
                                        shippingCountry = 'United States',
                                        c2g__CODAAccountsReceivableControl__c = gla
                                        );
			insert account;
			Contact contact = new Contact(firstname = 'uniqueVal',
                                        lastname = 'ApexTest',
                                        email = 'uniqueVal' + '@apextest.com',
                                        mailingStreet = '120 Birmingham Drive, Suite ',
                                        mailingCity = 'San Diego',
                                        mailingPostalCode = '92007',
                                        mailingState = 'California',
                                        mailingCountry = 'United States',
                                        otherStreet = '120 Birmingham Drive, Suite ',
                                        otherCity = 'San Diego',
                                        otherState = 'California',
                                        otherPostalCode = '92007',
                                        otherCountry = 'United States',
										accountId = account.Id);
			insert contact;
			account = [SELECT id, 
			                  Primary_Billing_Account__c
			           FROM Account
			           WHERE Id = :account.id];
			Billing_Account__c bAcc = new Billing_Account__c(Id = account.Primary_Billing_Account__c, Primary_Contact__c = contact.Id);
			update bAcc;
			Opportunity opportunity = new Opportunity(Name = 'BatchTestOpp', Type = 'BatchTestOpp', Description = 'BatchTestOpp', Recurring_Status__c = 'Active', Period__c = 'Month', Frequency__c = 1, Next_Invoice_Date__c = Date.Today(), AccountId = account.Id, StageName = 'Prospecting', CloseDate = Date.Today());
			insert opportunity;
			OpportunityLineItem lineItem = new OpportunityLineItem(PricebookEntryId = pbe.Id, Ready_To_Invoice__c = true, OpportunityId = opportunity.Id, Quantity = 1, TotalPrice = 100);
			insert lineItem;
			Opportunity.StageName = 'Closed Won';
			update Opportunity;
			System.Debug('opportunity : ' + opportunity);
			System.Debug([SELECT Id, 
			                     Name, 
			                     Description, 
			                     Ready_To_Invoice__c, 
			                     Recurring_Status__c, 
			                     AccountId, 
			                     Account.c2g__CODAFinanceContact__c, 
			                     Next_Invoice_Date__c, 
			                     Period__c, 
			                     Frequency__c, 
			                     (SELECT Id, 
			                             Product2Id, 
			                             Description, 
			                             Dimension_1__c, 
			                             Dimension_2__c, 
			                             Dimension_3__c, 
			                             Dimension_4__c, 
			                             Quantity, 
			                             UnitPrice, 
			                             Recurring_Payment__c, 
			                             Ready_To_Invoice__c, 
			                             Invoiced__c
			                      FROM OpportunityLineItems
			                      WHERE Ready_To_Invoice__c = True)
			              FROM Opportunity
			              WHERE Recurring_Status__c = 'Active' AND Next_Invoice_Date__c = TODAY AND Name = 'BatchTestOpp']);
			Test.startTest();
			//Check Results
			try
			{
				BatchCreateInvoice batch = new BatchCreateInvoice();
				Database.executeBatch(batch, 1);
			}
			catch ( Exception er )
			{

			}
			Test.stopTest();
		}
	}

}