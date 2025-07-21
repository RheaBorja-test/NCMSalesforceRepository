@isTest
private class InvoiceCancelllation_Test {
    @testSetup
    static void createData() {
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
        insert joe;

        Campaign cam = new Campaign(
            Name = 'test campaign',
            isActive = true,
            StartDate = Date.Today(),
            EndDate = Date.Today().addDays(365)
        );
        insert cam;

        RecordType oppRT = [SELECT Id FROM RecordType WHERE sObjectType='Opportunity' AND Name = 'NCM Institute' LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'test opp',
            AccountId = act.Id,
            StageName = 'Invoice Sent',
            RecordTypeId = oppRT.Id,
            NCMi_First_Contact__c = Date.today(),
            CloseDate = Date.today(),
            CampaignId = cam.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        Opportunity opp2 = new Opportunity(
            Name = 'test opp 2',
            AccountId = act.Id,
            StageName = 'Invoice Sent',
            RecordTypeId = oppRT.Id,
            NCMi_First_Contact__c = Date.today().addDays(-1),
            CloseDate = Date.today(),
            CampaignId = cam.Id
        );
        insert(new List<Opportunity>{opp, opp2});

        Id baId = [SELECT Primary_Billing_Account__c FROM Account LIMIT 1].Primary_Billing_Account__c;

        Billing_Account__c ba = new Billing_Account__c(
            Id = baId,
            Primary_Contact__c = joe.Id
        );
        update ba;

        c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c(Name = 'Test Dim 1', 
            c2g__ReportingCode__c = 'TD1'
            );
        insert dim1;
        
        Product2 prod = new Product2(Name = 'Test Product', 
                                Product_Value__c = 10, 
                                Dimension_1__c = dim1.Id, 
                                c2g__CODASalesRevenueAccount__c = gla,
                                IsActive = true);
        insert prod;

        Id cur = [SELECT Id FROM c2g__codaAccountingCurrency__c WHERE Name = 'USD'].Id;

        c2g__codaInvoice__c inv =  new c2g__codaInvoice__c(
            c2g__Account__c = act.Id,
            Billing_Account__c = act.Primary_Billing_Account__c,
            c2g__InvoiceStatus__c = 'In Progress',
            CZ_Invoicing_Status__c = 'Invoiced',
            CZ_InvoiceId__c = 'INV-good',
            c2g__InvoiceDate__c = Date.today(),
            RecordTypeId = Schema.SObjectType.c2g__codaInvoice__c.getRecordTypeInfosByName().get('Standard Invoice').getRecordTypeId(),
            c2g__InvoiceCurrency__c = cur,
            c2g__Opportunity__c = opp.Id
        );
        insert inv;

        insert(new c2g__codaInvoiceLineItem__c(
            c2g__Dimension1__c = dim1.Id,
            c2g__Invoice__c = inv.Id,
            c2g__Product__c = prod.Id,
            c2g__UnitPrice__c = 20
        ));

        insert(new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            IsActive = true,
            UnitPrice = 20
        ));
        
        insert(new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            Quantity = 1,
            UnitPrice = 20
        ));
    }

    @isTest
    static void inProgressInvTest() {
        Id oppId = [SELECT Id FROM Opportunity WHERE NCMi_First_Contact__c = TODAY LIMIT 1].Id;
        Id salespersonId = UserInfo.getUserId();
        String reason = 'Because';
        Invoice_Cancellation__e ice = new Invoice_Cancellation__e(
            OpportunityId__c = oppId,
            SalespersonId__c = salespersonId,
            Reason__c = reason
        );
        Test.startTest();
        EventBus.publish(ice);
        Test.stopTest();
    }

    @isTest
    static void notPaidInvTest() {
        c2g__codaInvoice__c inv =  [SELECT Id FROM c2g__codaInvoice__c LIMIT 1];
        inv.c2g__TriggerPosting__c = 'Synchronous';
        update(inv);

        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());
        Id oppId = [SELECT Id FROM Opportunity WHERE NCMi_First_Contact__c = TODAY LIMIT 1].Id;
        Id salespersonId = UserInfo.getUserId();
        String reason = 'Because';
        Invoice_Cancellation__e ice = new Invoice_Cancellation__e(
            OpportunityId__c = oppId,
            SalespersonId__c = salespersonId,
            Reason__c = reason
        );
        Test.startTest();
        EventBus.publish(ice);
        Test.stopTest();
    }

    @isTest
    static void noInvoiceTest() {
        Id oppId = [SELECT Id FROM Opportunity WHERE NCMi_First_Contact__c != TODAY LIMIT 1].Id;
        Id salespersonId = UserInfo.getUserId();
        String reason = 'Because';
        Invoice_Cancellation__e ice = new Invoice_Cancellation__e(
            OpportunityId__c = oppId,
            SalespersonId__c = salespersonId,
            Reason__c = reason
        );
        Test.startTest();
        EventBus.publish(ice);
        Test.stopTest();
    }
}