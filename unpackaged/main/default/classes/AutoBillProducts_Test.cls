@isTest 
public class AutoBillProducts_Test {
    @TestSetup
    static void makeData() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        c2g__codaCompany__c co = SetCurrentCompany_TEST_DataFactory.createCurrentCompany(
            'NCM Associates, Inc.',
            u,
            null,
            true,
            '12345');

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
                                IsActive = true,
                                Type__c = 'Candidate Composite');

        Product2 prodSF = new Product2(Name = 'Test Product SF', 
                                Product_Value__c = 10, 
                                Dimension_1__c = dim1.Id, 
                                c2g__CODASalesRevenueAccount__c = gla,
                                IsActive = true,
                                Type__c = 'Setup Fee');
        insert(new list<Product2>{prod, prodSF});
                          
        insert new Billing_Product__c(
            Billing_Product_Status__c = 'Active',
            Dimension_1__c = dim1.Id, 
            Product__c = prod.Id, 
            Description__c = 'Test Description', 
            Value__c = 100.00, 
            Next_Billing_Date__c = Date.Today(), 
            Quantity__c = 1, 
            Billing_Frequency__c = 'Monthly', 
            Recurring_Billing_Day__c = Date.Today().day() <= 28 ? Date.Today().day() : 28, 
            Billing_Account__c = ba.Id);

        insert new AutoBillProductsBatchSettings__c(Qty__c = 25, Delay__c = 10);
    }

    @isTest 
    private static void testBatch() {
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());
        
        Test.startTest();
        Database.executeBatch(new AutoBillProductsBatch(), 25);
        Test.stopTest();

        c2g__codaInvoice__c inv = [SELECT Id, c2g__InvoiceStatus__c, c2g__InvoiceTotal__c FROM c2g__codaInvoice__c LIMIT 1];
        Assert.areEqual('Complete', inv.c2g__InvoiceStatus__c);
        Assert.areEqual(100.00, inv.c2g__InvoiceTotal__c);
        
    }

    @isTest 
    private static void testBatchSF() {
        Product2 prodSF = [SELECT Id FROM Product2 WHERE Name = 'Test Product SF' LIMIT 1];
        Billing_Product__c bp = [SELECT Id FROM Billing_Product__c LIMIT 1];
        bp.Product__c = prodSF.Id;
        update(bp);

        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());
        
        Test.startTest();
        Database.executeBatch(new AutoBillProductsBatch(), 25);
        Test.stopTest();

        c2g__codaInvoice__c inv = [SELECT Id, c2g__InvoiceStatus__c, c2g__InvoiceTotal__c FROM c2g__codaInvoice__c LIMIT 1];
        Assert.areEqual('Complete', inv.c2g__InvoiceStatus__c);
        Assert.areEqual(100.00, inv.c2g__InvoiceTotal__c);

        Billing_Product__c bpResult = [SELECT Id, Billing_Product_Status__c FROM Billing_Product__c LIMIT 1];
        Assert.areEqual('Inactive', bpResult.Billing_Product_Status__c);
    }
}