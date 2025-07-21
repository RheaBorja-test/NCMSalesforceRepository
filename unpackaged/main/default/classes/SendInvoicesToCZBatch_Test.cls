@isTest
public class SendInvoicesToCZBatch_Test {
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

    }
    
    @isTest 
    private static void SendInvoicesToCZBatch_Test() {
        c2g__codaInvoice__c inv = [SELECT Id FROM c2g__codaInvoice__c LIMIT 1];
       
        List<c2g.codaapicommon.reference> invoiceRefs = new List<c2g.codaapicommon.reference>();
        invoiceRefs.add(c2g.CODAAPICommon.getRef(inv.Id, null));
        c2g.CODAAPICommon_10_0.Context cntx = new c2g.CODAAPICommon_10_0.Context();
        cntx.CompanyName = 'NCM Associates, Inc.';
        c2g.CODAAPISalesInvoice_10_0.BulkPostInvoice(cntx, invoiceRefs);
        
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());


        Test.startTest();
        //instanatiate the batch with a quantity of 1 
        SendInvoicesToCZBatch batchSend = new SendInvoicesToCZBatch(new List<Id>());
        id batchId = Database.executebatch(batchSend, 1);
        Test.stopTest();
        c2g__codaInvoice__c finalInv = [SELECT Id, CZ_Invoicing_Status__c FROM c2g__codaInvoice__c WHERE Id = :inv.Id];
        //If everything is successful, then the CZ Invoicing Status will be invoiced
        Assert.areEqual('Invoiced', finalInv.CZ_Invoicing_Status__c);
    }

    @isTest 
    private static void manualInvoiceRequiredTest() {
        Contact joe = [SELECT Id FROM Contact LIMIT 1];
        joe.Email = null;
        update joe;

        c2g__codaInvoice__c inv = [SELECT Id FROM c2g__codaInvoice__c LIMIT 1];
       
        List<c2g.codaapicommon.reference> invoiceRefs = new List<c2g.codaapicommon.reference>();
        invoiceRefs.add(c2g.CODAAPICommon.getRef(inv.Id, null));
        c2g.CODAAPICommon_10_0.Context cntx = new c2g.CODAAPICommon_10_0.Context();
        cntx.CompanyName = 'NCM Associates, Inc.';
        c2g.CODAAPISalesInvoice_10_0.BulkPostInvoice(cntx, invoiceRefs);
        
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());


        Test.startTest();
        //instanatiate the batch with billing contact that does not have an email address
        SendInvoicesToCZBatch batchSend = new SendInvoicesToCZBatch(new List<Id>{inv.Id});
        List<String> lst = new List<String>{'one', 'two'};
        batchSend.failedInvoices = lst;
        id batchId = Database.executebatch(batchSend, 1);
        Test.stopTest();
        c2g__codaInvoice__c finalInv = [SELECT Id, CZ_Invoicing_Status__c FROM c2g__codaInvoice__c WHERE Id = :inv.Id];
        //If everything is successful, then the CZ Invoicing Status will be invoiced
        Assert.areEqual('Manual Invoicing Required', finalInv.CZ_Invoicing_Status__c);
    }
}