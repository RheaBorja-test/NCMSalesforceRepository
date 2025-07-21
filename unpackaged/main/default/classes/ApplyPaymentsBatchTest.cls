//This test provides coverage for ApplyPaymentsBatch.cls and CashMatching.cls
@IsTest
public with sharing class ApplyPaymentsBatchTest {
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
            CZ_Invoicing_Status__c = 'None',
            c2g__InvoiceDate__c = Date.today(),
            RecordTypeId = Schema.SObjectType.c2g__codaInvoice__c.getRecordTypeInfosByName().get('Standard Invoice').getRecordTypeId(),
            c2g__InvoiceCurrency__c = cur
        );
        insert inv;

        insert new c2g__codaInvoiceLineItem__c(c2g__Dimension1__c = dim1.Id,
                                            c2g__Invoice__c = inv.Id,
                                            c2g__Product__c = prod.Id,
                                            c2g__UnitPrice__c = 20);

        insert new Payment_Polling_Settings__c(Quantity__c = 100, Days_back__c = 0);

    }
    
    @IsTest
    static void testApplyPaymentsBatch(){
        Test.startTest();
        Account act = [SELECT Id, Name, Primary_Billing_Account__c, c2g__codaAccountTradingCurrency__c FROM Account WHERE Primary_Billing_Account__c != null LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Id compId = [SELECT Id FROM c2g__codaCompany__c LIMIT 1].Id;
        String ffAccountRef;

        c2g__codaInvoice__c inv =  new c2g__codaInvoice__c(
            c2g__Account__c = act.Id,
            Billing_Account__c = act.Primary_Billing_Account__c,
            c2g__InvoiceStatus__c = 'In Progress',
            CZ_Invoicing_Status__c = 'Invoiced',
            CZ_InvoiceId__c = 'INV-99999999999-ABCDEF',
            c2g__InvoiceDate__c = Date.today(),
            c2g__CustomerReference__c = ffAccountRef,
            RecordTypeId = Schema.SObjectType.c2g__codaInvoice__c.getRecordTypeInfosByName().get('Standard Invoice').getRecordTypeId(),
            c2g__OwnerCompany__c = compId
        );
        insert inv;

        c2g__codaInvoiceLineItem__c li = new c2g__codaInvoiceLineItem__c(
            c2g__Invoice__c = inv.Id,
            c2g__Product__c = prod.Id,
            c2g__UnitPrice__c = 1295,
            c2g__Quantity__c = 1
        );
        insert li;
       
        List<c2g.codaapicommon.reference> invoiceRefs = new List<c2g.codaapicommon.reference>();
        invoiceRefs.add(c2g.CODAAPICommon.getRef(inv.Id, null));
        c2g.CODAAPICommon_10_0.Context cntx = new c2g.CODAAPICommon_10_0.Context();
        cntx.CompanyName = 'NCM Associates, Inc.';
        c2g.CODAAPISalesInvoice_10_0.BulkPostInvoice(cntx, invoiceRefs);

        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());

        //Test.startTest();
        //instantiate the batch and run it
        ApplyPaymentsBatch apb = new ApplyPaymentsBatch();
        database.executebatch(apb);
        Test.stopTest();
        c2g__codaTransactionLineItem__c tLI = [SELECT Id, c2g__MatchingStatus__c, c2g__DocumentValue__c
                                            FROM c2g__codaTransactionLineItem__c 
                                            WHERE c2g__Transaction__r.c2g__CashEntry__r.CZ_TnxId__c = '123456789012'
                                            LIMIT 1];
        Assert.areEqual('Matched', tLI.c2g__MatchingStatus__c);
        Assert.areEqual(-1295, tLI.c2g__DocumentValue__c);
    }

    /*@IsTest
    static void schedulableTest(){
        String CRON_EXP = '0 6 * * * ?';
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());

        Test.startTest();
        String jobId = System.schedule('Update Contacts', CRON_EXP, new ApplyPaymentsBatchSchedulable());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
    }*/
}