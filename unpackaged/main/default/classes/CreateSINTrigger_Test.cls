/*
 * This class contains unit tests for validating the behavior of CreateSINTrigger.Trigger
 */
@isTest
private class CreateSINTrigger_Test {

    @TestSetup
    static void makeData(){
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        c2g__codaCompany__c co = SetCurrentCompany_TEST_DataFactory.createCurrentCompany(
            'NCM Associates, Inc.',
            u,
            null,
            true,
            '12345'
        );

        Id gla = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c LIMIT 1].Id;
        
        Account act = new Account(
            Name = 'Metroville Dodge', 
            BillingStreet = '111 Main St', 
            BillingCity = 'Metroville', 
            BillingStateCode = 'NC', 
            BillingPostalCode = '27554',
            c2g__codaAccountTradingCurrency__c = 'USD',
            c2g__CODAAccountsReceivableControl__c = gla
        );
        insert(act);

        Contact joe = new Contact(
            FirstName = 'Joe',
            LastName = 'Contact',
            AccountId = act.Id,
            Email = 'joe@example.com'
        );
        insert(joe);

        Id baId = [SELECT Primary_Billing_Account__c FROM Account LIMIT 1].Primary_Billing_Account__c;

        Billing_Account__c ba = new Billing_Account__c(
            Id = baId,
            Primary_Contact__c = joe.Id
        );
        update(ba);

        c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c(Name = 'Test Dim 1', 
            c2g__ReportingCode__c = '7000'
            );
        insert(dim1);

        c2g__codaDimension2__c dim2 = new c2g__codaDimension2__c(Name = 'Test Dim 2', 
            c2g__ReportingCode__c = System.Label.NCMiDim2Name
            );
        insert(dim2);
        
        Product2 prod = new Product2(Name = 'Test Product', 
                                Product_Value__c = 10, 
                                Dimension_1__c = dim1.Id, 
                                c2g__CODASalesRevenueAccount__c = gla,
                                IsActive = true,
                                NCM_Authorized_Products__c = 'NCMi Paid Seats',
                                Core_Product__c = true,
                                Record_Provisioning__c = 'NCMi Seat',
                                Type__c = 'Paid Seat');
        insert(prod);

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry pbe = new PricebookEntry(
            IsActive = true,
            UnitPrice = 99.99,
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id
        );
        insert(pbe);

        Id cur = [SELECT Id FROM c2g__codaAccountingCurrency__c WHERE Name = 'USD'].Id;

        Campaign camp = new Campaign(Name = 'Test Camp');
        insert(camp);

        Opportunity op = new Opportunity(Name = 'test opp',
                                        NCM_Product_Interest__c = 'NCM Institute',
                                        CloseDate = Date.today(),
                                        NCMi_First_Contact__c = Date.today(),
                                        StageName = 'Pending Sale',
                                        AccountId = act.Id,
                                        Billing_Account__c = ba.Id,
                                        LeadSource = 'Employee Refferal',
                                        CampaignId = camp.Id,
                                        Pricebook2Id = Test.getStandardPricebookId());
        insert(op);

        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = op.Id,
                                                            Product2Id = prod.Id,
                                                            Quantity = 1,
                                                            UnitPrice = 100.00,
                                                            Description = 'Joe - 1/15/24',
                                                            Pending_Price__c = true);
        insert(oli);

        insert(new Billing_Product__c(Product__c = prod.Id, 
                                        Opportunity__c = op.Id,
                                        Billing_Frequency__c = 'One-Time',
                                        Billing_Account__c = ba.Id,
                                        Billing_Product_Status__c = 'Active',
                                        Next_Billing_Date__c = Date.today()));

    }

    @isTest
    static void createSINTriggerTest() {
        Id x = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Id y = [SELECT Id FROM Billing_Account__c LIMIT 1].Id;
        Test.startTest();
        Id userId = UserInfo.getUserId();
        Database.SaveResult dsr = EventBus.publish(new Create_SIN__e(OpportunityId__c = x, SalespersonId__c = userId, BillingAccountId__c = y));
        Test.stopTest();
        Assert.isTrue(dsr.isSuccess());
        EventBusSubscriber ebs = [SELECT Name, Position, Retries, LastError FROM EventBusSubscriber WHERE Topic='Create_SIN__e' AND Type='ApexTrigger'];
        Assert.areEqual(1, ebs.Position);
        OpportunityLineItem oppLI = [SELECT Id, Invoiced__c FROM OpportunityLineItem LIMIT 1];
        Assert.isTrue(oppLI.Invoiced__c);
    }
}