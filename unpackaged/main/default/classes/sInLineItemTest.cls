@isTest(SeeAllData=true)
public class sInLineItemTest {
    static testMethod void sInPdTest(){
        user u = 
		[
			SELECT Id
			FROM User
			WHERE 
				IsActive = true AND 
				Id IN 
				(
					SELECT UserId
					FROM UserPackageLicense
					WHERE PackageLicense.NamespacePrefix = 'c2g'
				)
                AND Profile.Name = 'NCM Accounting'
			ORDER BY LastName DESC
			LIMIT 1
		];
        System.debug('~~~u: '  + u);

        test.startTest();
        system.runAs(u){
            /*OpportunityLineItem lineItem = 
            [
                SELECT 
                    Id, 
                    OpportunityId 
                FROM OpportunityLineItem 
                WHERE 
                    Ready_to_Invoice__c = true AND 
                    Invoiced__c = false AND 
                    Opportunity.Recurring_Status__c != 'Active'
                LIMIT 1
            ];
            Opportunity opp = 
            [
                SELECT 
                    Id, 
                    Billing_Street__c, 
                    Billing_State__c, 
                    AccountId, 
                    Billing_Zip_Code__c
                FROM Opportunity 
                WHERE 
                    Id = :lineItem.OpportunityId AND
                    Billing_Account__c = null
            ];*/

            //Start here
            c2g__codaDimension1__c testDimension1 = new c2g__codaDimension1__c(
                Name = 'Test Dimension1',
                c2g__ReportingCode__c = 'TEST',
                Conductor_CC_Email__c = 'test@no.no'
            );
            insert(testDimension1);

            Product2 testProduct = new Product2(
                IsActive = true,
                RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('20 Groups').getRecordTypeId(),
                Name = '20 Group Test Product',
                Dimension_1__c = testDimension1.Id,
                Product_Value__c = 500.00,
                Production_Run_Type__c = 'Not Applicable',
                Family = '20 Groups',
                Locked_Frequency__c = 'Quarterly',
                Shipped_Product__c = True // Required for trigger entry criteria!
            );
            insert testProduct;

            Id pricebookId = Test.getStandardPricebookId();

            PricebookEntry pbe = new PricebookEntry(
                IsActive = true,
                UnitPrice = 99.99,
                Pricebook2Id = pricebookId,
                Product2Id = testProduct.Id
            );
            insert pbe;

            List<c2g__codaYear__c> years = [SELECT Id FROM c2g__codaYear__c];
            if(years.size() == 0) {
                c2g__codaYear__c yr= new c2g__codaYear__c();
                yr.Name ='2015';
                yr.c2g__AutomaticPeriodList__c =  true;
                //yr.c2g__OwnerCompany__c = company.id;
                yr.c2g__ExternalId__c = 'yzsd1234';
                yr.c2g__NumberOfPeriods__c =11;
                yr.c2g__StartDate__c =  system.today() - 10;
                yr.c2g__Status__c = 'Open';
                yr.c2g__PeriodCalculationBasis__c = '445';
                yr.c2g__YearEndMode__c = 'Full Accounting Code' ; 
                yr.c2g__UnitOfWork__c = 12;
                //yr.ownerid = testGroupId;
                insert yr;

                c2g__codaPeriod__c prd = new c2g__codaPeriod__c();
                prd.Name ='Test2015';
                prd.c2g__ExternalId__c ='abdc12345';
                prd.c2g__StartDate__c = System.today()-10;
                prd.c2g__EndDate__c= System.today()+10;
                //prd.c2g__OwnerCompany__c = company.id;
                prd.c2g__PeriodNumber__c ='123';
                prd.c2g__Description__c ='test Desc';
                prd.c2g__PeriodGroup__c = 'Q1';
                prd.c2g__PeriodNumber__c = '1';
                prd.c2g__YearName__c = yr.id;
                insert prd;
            }
            
            Account acc= new Account();
            acc.Name='Test Account';
            insert acc;

            Opportunity opp = new Opportunity(
                Name = 'Test Opp',
                Billing_Street__c = '123 Sesame St.', 
                Billing_State__c = 'AK', 
                AccountId = acc.Id, 
                Billing_Zip_Code__c = '12345',
                Recurring_Status__c = 'Not Recurring',
                StageName = 'Closed Won',
                CloseDate = system.today(),
                Pricebook2Id = pricebookId);
            insert opp;
        
            OpportunityLineItem lineItem = new OpportunityLineItem(
                OpportunityId = opp.Id,
                Ready_to_Invoice__c = true,
                Invoiced__c = false,
                Product2Id = testProduct.Id);
            insert lineItem;
            //end here
            
            c2g__codaInvoice__c sIn = new c2g__codaInvoice__c();
            sIn.Billing_Street__c = opp.Billing_Street__c;
            sIn.Billing_State__c = opp.Billing_State__c;
            sIn.c2g__Opportunity__c = opp.Id;
            sIn.c2g__Account__c = opp.AccountId;
            sIn.Billing_Zip_Code__c = opp.Billing_Zip_Code__c;
            
            
            try {
                insert sIn;
            } Catch (DMLexception exp){
                system.debug(exp);
            }
            
            List<c2g__codaInvoiceLineItem__c> sinLineItems = 
            [
                SELECT Id
                FROM c2g__codaInvoiceLineItem__c
                WHERE c2g__Invoice__c = :sIn.Id
            ];

            system.assert(sinLineItems.size() > 0, 'No Line Items Found');
        }
        test.stopTest();
    }
}