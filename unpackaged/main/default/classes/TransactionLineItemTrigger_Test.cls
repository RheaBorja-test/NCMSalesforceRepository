@isTest//(seeAllData=true)
public class TransactionLineItemTrigger_Test {
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
    }

    @isTest
    public static void CheckPayment_Test() {
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());

        c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c(Name = 'Test Dim 1', 
            c2g__ReportingCode__c = 'TD1'
            );
        insert dim1;

        Id gla = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c LIMIT 1].Id;
        
        Product2 prod = new Product2(Name = 'Test Product', 
                                Product_Value__c = 10, 
                                Dimension_1__c = dim1.Id, 
                                c2g__CODASalesRevenueAccount__c = gla,
                                IsActive = true);
        insert prod;

        Account act = new Account(
            Name = 'Metroville Dodge', 
            BillingStreet = '111 Main St', 
            BillingCity = 'Metroville', 
            BillingStateCode = 'NC', 
            BillingPostalCode = '27554',
            c2g__codaAccountTradingCurrency__c = 'USD',
            c2g__CODAAccountsReceivableControl__c = gla);
        insert(act);

        String ffAccountRef;

        Id cur = [SELECT Id FROM c2g__codaAccountingCurrency__c WHERE Name = 'USD'].Id;

        c2g__codaInvoice__c inv =  new c2g__codaInvoice__c(
            c2g__Account__c = act.Id,
            Billing_Account__c = act.Primary_Billing_Account__c,
            c2g__InvoiceStatus__c = 'In Progress',
            CZ_Invoicing_Status__c = 'Invoiced',
            CZ_InvoiceId__c = 'INV-99999999999-ABCDEF',
            c2g__InvoiceDate__c = Date.today(),
            c2g__CustomerReference__c = ffAccountRef,
            RecordTypeId = Schema.SObjectType.c2g__codaInvoice__c.getRecordTypeInfosByName().get('Standard Invoice').getRecordTypeId(),
            c2g__InvoiceCurrency__c = cur
        );
        insert inv;
        String invName = [SELECT Name FROM c2g__codaInvoice__c WHERE Id = :inv.Id].Name;

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
       
        Id baId = [SELECT Id FROM c2g__codaBankAccount__c LIMIT 1].Id;

        c2g__codaCashEntry__c ce = new c2g__codaCashEntry__c(
            c2g__BankAccount__c = baId,
            c2g__PaymentMethod__c = 'Check',
            c2g__Reference__c = invName,
            c2g__Type__c = 'Receipt'
        );
        Test.startTest();
        insert ce;

        c2g__codaCashEntryLineItem__c celi = new c2g__codaCashEntryLineItem__c(
            c2g__CashEntry__c = ce.Id,
            c2g__Account__c = act.Id,
            c2g__LineDescription__c = inv.Name,
            c2g__AccountPaymentMethod__c = 'Check',
            c2g__CashEntryValue__c = 1295,
            c2g__AccountReference__c = invName
        );
        insert celi;

        List<c2g.codaapicommon.reference> cashEntryRefs = new List<c2g.codaapicommon.reference>();
        cashEntryRefs.add(c2g.CODAAPICommon.getRef(ce.Id, null));
        c2g.CODAAPICommon_7_0.Context cntx2 = new c2g.CODAAPICommon_7_0.Context();
        cntx2.CompanyName = 'NCM Associates, Inc.';
        c2g.CODAAPICashEntry_7_0.BulkPostCashEntry(cntx2, cashEntryRefs);

        //Test.startTest();
        System.enqueueJob(new CashMatching(new List<c2g__codaCashEntry__c>{ce}));
        Test.stopTest();

        c2g__codaInvoice__c matchedInv = [SELECT Id, c2g__PaymentStatus__c FROM c2g__codaInvoice__c WHERE Id = :inv.Id];
        System.debug('~~~matchedInv.c2g__PaymentStatus__c: ' + matchedInv.c2g__PaymentStatus__c);
        Assert.areEqual('Paid', matchedInv.c2g__PaymentStatus__c);
        c2g__codaTransaction__c tran = [SELECT Id, 
                                            (SELECT Id, CZ_OfflinePymtId__c     
                                            FROM c2g__TransactionLineItems__r 
                                            WHERE c2g__LineType__c = 'Account')
                                        FROM c2g__codaTransaction__c
                                        WHERE c2g__CashEntry__c = :ce.Id];
        System.debug('~~~tran line item CZ Offlineid: ' + tran.c2g__TransactionLineItems__r[0].CZ_OfflinePymtId__c);
        //Assert.areEqual('1234567896', tran.c2g__TransactionLineItems__r[0].CZ_OfflinePymtId__c);
    }

    @isTest
    public static void CreditNote_Test() {
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());
        
        c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c(Name = 'Test Dim 1', 
            c2g__ReportingCode__c = 'TD1'
            );
        insert dim1;

        Id gla = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c LIMIT 1].Id;
        
        Product2 prod = new Product2(Name = 'Test Product', 
                                Product_Value__c = 10, 
                                Dimension_1__c = dim1.Id, 
                                c2g__CODASalesRevenueAccount__c = gla,
                                IsActive = true);
        insert prod;

        Account act = new Account(
            Name = 'Metroville Dodge', 
            BillingStreet = '111 Main St', 
            BillingCity = 'Metroville', 
            BillingStateCode = 'NC', 
            BillingPostalCode = '27554',
            c2g__codaAccountTradingCurrency__c = 'USD',
            c2g__CODAAccountsReceivableControl__c = gla);
        insert(act);

        String ffAccountRef;

        Id cur = [SELECT Id FROM c2g__codaAccountingCurrency__c WHERE Name = 'USD'].Id;

        c2g__codaInvoice__c inv =  new c2g__codaInvoice__c(
            c2g__Account__c = act.Id,
            Billing_Account__c = act.Primary_Billing_Account__c,
            c2g__InvoiceStatus__c = 'In Progress',
            CZ_Invoicing_Status__c = 'Invoiced',
            CZ_InvoiceId__c = 'INV-99999999999-ABCDEF',
            c2g__InvoiceDate__c = Date.today(),
            c2g__CustomerReference__c = ffAccountRef,
            RecordTypeId = Schema.SObjectType.c2g__codaInvoice__c.getRecordTypeInfosByName().get('Standard Invoice').getRecordTypeId(),
            c2g__InvoiceCurrency__c = cur
        );
        insert inv;
        String invName = [SELECT Name FROM c2g__codaInvoice__c WHERE Id = :inv.Id].Name;

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
       
        Id baId = [SELECT Id FROM c2g__codaBankAccount__c LIMIT 1].Id;

        c2g__codaCreditNote__c cn = new c2g__codaCreditNote__c(
            c2g__Invoice__c = inv.Id,
            c2g__Account__c =  act.Id         
        );
        Test.startTest();
        insert cn;

        c2g__codaCreditNoteLineItem__c cnli = new c2g__codaCreditNoteLineItem__c(
            c2g__CreditNote__c = cn.Id,
            c2g__Product__c = prod.Id,
            c2g__Quantity__c = 1,
            c2g__UnitPrice__c = 1000
        );
        insert cnli;

        List<c2g.codaapicommon.reference> creditNoteRefs = new List<c2g.codaapicommon.reference>();
        creditNoteRefs.add(c2g.CODAAPICommon.getRef(cn.Id, null));
        c2g.CODAAPICommon_10_0.Context cntx2 = new c2g.CODAAPICommon_10_0.Context();
        cntx2.CompanyName = 'NCM Associates, Inc.';
        c2g.CODAAPISalesCreditNote_10_0.BulkPostCreditNote(cntx2, creditNoteRefs);

        //Test.startTest();
        creditMatching(cn);
        Test.stopTest();

        c2g__codaInvoice__c matchedInv = [SELECT Id, c2g__PaymentStatus__c FROM c2g__codaInvoice__c WHERE Id = :inv.Id];
        System.debug('~~~Invoice Payment Status: ' + matchedInv.c2g__PaymentStatus__c);
    }

    @isTest
    public static void CreditNotePaid_Test() {
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());
        
        c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c(Name = 'Test Dim 1', 
            c2g__ReportingCode__c = 'TD1'
            );
        insert dim1;

        Id gla = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c LIMIT 1].Id;
        
        Product2 prod = new Product2(Name = 'Test Product', 
                                Product_Value__c = 10, 
                                Dimension_1__c = dim1.Id, 
                                c2g__CODASalesRevenueAccount__c = gla,
                                IsActive = true);
        insert prod;

        Account act = new Account(
            Name = 'Metroville Dodge', 
            BillingStreet = '111 Main St', 
            BillingCity = 'Metroville', 
            BillingStateCode = 'NC', 
            BillingPostalCode = '27554',
            c2g__codaAccountTradingCurrency__c = 'USD',
            c2g__CODAAccountsReceivableControl__c = gla);
        insert(act);

        String ffAccountRef;

        Id cur = [SELECT Id FROM c2g__codaAccountingCurrency__c WHERE Name = 'USD'].Id;

        c2g__codaInvoice__c inv =  new c2g__codaInvoice__c(
            c2g__Account__c = act.Id,
            Billing_Account__c = act.Primary_Billing_Account__c,
            c2g__InvoiceStatus__c = 'In Progress',
            CZ_Invoicing_Status__c = 'Invoiced',
            CZ_InvoiceId__c = 'INV-99999999999-PAID',
            c2g__InvoiceDate__c = Date.today(),
            c2g__CustomerReference__c = ffAccountRef,
            RecordTypeId = Schema.SObjectType.c2g__codaInvoice__c.getRecordTypeInfosByName().get('Standard Invoice').getRecordTypeId(),
            c2g__InvoiceCurrency__c = cur
        );
        insert inv;
        String invName = [SELECT Name FROM c2g__codaInvoice__c WHERE Id = :inv.Id].Name;

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
       
        Id baId = [SELECT Id FROM c2g__codaBankAccount__c LIMIT 1].Id;

        c2g__codaCreditNote__c cn = new c2g__codaCreditNote__c(
            c2g__Invoice__c = inv.Id,
            c2g__Account__c =  act.Id         
        );
        Test.startTest();
        insert cn;

        c2g__codaCreditNoteLineItem__c cnli = new c2g__codaCreditNoteLineItem__c(
            c2g__CreditNote__c = cn.Id,
            c2g__Product__c = prod.Id,
            c2g__Quantity__c = 1,
            c2g__UnitPrice__c = 1000
        );
        insert cnli;

        List<c2g.codaapicommon.reference> creditNoteRefs = new List<c2g.codaapicommon.reference>();
        creditNoteRefs.add(c2g.CODAAPICommon.getRef(cn.Id, null));
        c2g.CODAAPICommon_10_0.Context cntx2 = new c2g.CODAAPICommon_10_0.Context();
        cntx2.CompanyName = 'NCM Associates, Inc.';
        c2g.CODAAPISalesCreditNote_10_0.BulkPostCreditNote(cntx2, creditNoteRefs);

        //Test.startTest();
        creditMatching(cn);
        Test.stopTest();

        c2g__codaInvoice__c matchedInv = [SELECT Id, c2g__PaymentStatus__c FROM c2g__codaInvoice__c WHERE Id = :inv.Id];
        System.debug('~~~Invoice Payment Status: ' + matchedInv.c2g__PaymentStatus__c);
    }

    private static void creditMatching(c2g__codaCreditNote__c cn) {
        Id acctId = cn.c2g__Account__c;
        Id periodId = [SELECT c2g__Period__c FROM c2g__codaCreditNote__c][0].c2g__Period__c;
        
        c2g__codaTransactionLineItem__c cnTrans =  [SELECT Id, SystemModstamp, c2g__DocumentValue__c, Period__c 
                                                    FROM c2g__codaTransactionLineItem__c
                                                    WHERE c2g__Transaction__r.c2g__SalesCreditNote__c = :cn.Id
                                                    AND c2g__MatchingStatus__c = 'Available' 
                                                    LIMIT 1];

        c2g__codaTransactionLineItem__c sinTrans = [SELECT Id, SystemModstamp 
                                                    FROM c2g__codaTransactionLineItem__c
                                                    WHERE c2g__Transaction__r.c2g__SalesInvoice__c = :cn.c2g__Invoice__c 
                                                    AND c2g__MatchingStatus__c = 'Available' 
                                                    LIMIT 1];

        
        c2g.CODAAPICashMatchingTypes_8_0.Configuration configuration = new c2g.CODAAPICashMatchingTypes_8_0.Configuration();
        configuration.Account = c2g.CODAAPICommon.getRef(acctId, null);
        //Choose Document or Account depending on the Currency Mode you would choose if you were doing this from the UI.
        configuration.MatchingCurrencyMode = c2g.CODAAPICashMatchingTypes_8_0.enumMatchingCurrencyMode.Document;
        configuration.MatchingDate = System.Today();
        configuration.DiscountDate = System.today();
        configuration.MatchingPeriod = c2g.CODAAPICommon.getRef(periodId, null);
        
        //Make thelist of cash entries to post
        List<c2g.CODAAPICashMatchingTypes_8_0.Item> items = new List<c2g.CODAAPICashMatchingTypes_8_0.Item>();
    
        c2g.CODAAPICashMatchingTypes_8_0.Item item1 = new c2g.CODAAPICashMatchingTypes_8_0.Item();
        items.add(item1);
        item1.TransactionLineItem = c2g.CODAAPICommon.getRef(sinTrans.Id, null);
        item1.TransactionLineItemSystemModStamp = sinTrans.SystemModstamp;
        item1.Paid = -cnTrans.c2g__DocumentValue__c;
        item1.Discount = 0;
        item1.WriteOff = 0;

        c2g.CODAAPICashMatchingTypes_8_0.Item item2 = new c2g.CODAAPICashMatchingTypes_8_0.Item();
        items.add(item2);
        item2.TransactionLineItem = c2g.CODAAPICommon.getRef(cnTrans.Id, null);
        item2.TransactionLineItemSystemModStamp = cnTrans.SystemModstamp;
        item2.Paid = cnTrans.c2g__DocumentValue__c;
        item2.Discount = 0;
        item2.WriteOff = 0;

        //create the context
        c2g.CODAAPICommon_8_0.Context cntx = new c2g.CODAAPICommon_8_0.Context();
        cntx.CompanyName = 'NCM Associates, Inc.';
        
        //create a null analysis object, since there are no discounts or write-offs
        c2g.CODAAPICashMatchingTypes_8_0.Analysis analysisInfoAPI = new c2g.CODAAPICashMatchingTypes_8_0.Analysis();
        
        // Finally, perform the match
        c2g.CODAAPICommon.Reference matchReference = c2g.CODAAPICashMatching_8_0.Match(cntx, configuration, items, analysisInfoAPI);
    }
}