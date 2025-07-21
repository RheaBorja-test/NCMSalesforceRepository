@isTest
private class FFtoCZBalanceBatch_Test {

    @testSetup
    private static void makeData() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        c2g__codaCompany__c co = SetCurrentCompany_TEST_DataFactory.createCurrentCompany(
            'NCM Associates, Inc.',
            u,
            null,
            true,
            '12345');

        insert(new FFtoCZBalanceBatchSettings__c(Days__c = 1, Qty__c = 50));
        insert new Payment_Polling_Settings__c(Quantity__c = 100, Days_back__c = 0);

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
            CZ_InvoiceId__c = 'INV-99999999999-UNDER',
            c2g__InvoiceDate__c = Date.today(),
            RecordTypeId = Schema.SObjectType.c2g__codaInvoice__c.getRecordTypeInfosByName().get('Standard Invoice').getRecordTypeId(),
            c2g__InvoiceCurrency__c = cur
        );
        insert inv;

        insert new c2g__codaInvoiceLineItem__c(c2g__Dimension1__c = dim1.Id,
                                            c2g__Invoice__c = inv.Id,
                                            c2g__Product__c = prod.Id,
                                            c2g__Quantity__c = 1,
                                            c2g__UnitPrice__c = 20);

        c2g__codaInvoice__c inv2 =  new c2g__codaInvoice__c(
            c2g__Account__c = act.Id,
            Billing_Account__c = act.Primary_Billing_Account__c,
            c2g__InvoiceStatus__c = 'In Progress',
            CZ_Invoicing_Status__c = 'Invoiced',
            CZ_InvoiceId__c = 'INV-99999999999-OVER',
            c2g__InvoiceDate__c = Date.today(),
            RecordTypeId = Schema.SObjectType.c2g__codaInvoice__c.getRecordTypeInfosByName().get('Standard Invoice').getRecordTypeId(),
            c2g__InvoiceCurrency__c = cur
        );
        insert inv2;

        insert new c2g__codaInvoiceLineItem__c(c2g__Dimension1__c = dim1.Id,
                                            c2g__Invoice__c = inv2.Id,
                                            c2g__Product__c = prod.Id,
                                            c2g__Quantity__c = 1,
                                            c2g__UnitPrice__c = 20);
    }

    @isTest
    static void myUnitTest() {
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());
        Test.startTest();
        Database.executeBatch(new FFtoCZBalanceBatch(), 50);
        Test.stopTest();
        List<Error_Logger__c> elList = [SELECT Id FROM Error_Logger__c];
        Assert.areEqual(2, elList.size());
    }
}