@isTest
private class OpportunityProductTrigger_Test {
    @TestSetup
    private static void makeData() {
        Account act = new Account(Name = 'Test Account');
        insert(act);

        Id pricebookId = Test.getStandardPricebookId();
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp', 
            AccountId = act.Id, 
            StageName = 'Pending Sale',
            CloseDate = Date.today(),
            Pricebook2Id = pricebookId
        );
        insert(opp);

        c2g__codaDimension1__c testDimension1 = new c2g__codaDimension1__c(
            Name = 'Test Dimension1',
            c2g__ReportingCode__c = '2000'//,
            //Conductor_CC_Email__c = 'mdemeglio@ncmassociates.com'
        );
        insert(testDimension1);
        
        Product2 prod = new Product2(
            IsActive = true,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('NCMi').getRecordTypeId(),
            Name = 'Test NCMi Seat Product',
            Dimension_1__c = testDimension1.Id,
            Product_Value__c = 500.00,
            Production_Run_Type__c = 'Not Applicable',
            Family = 'NCM Institute',
            Locked_Frequency__c = 'Quarterly',
            Shipped_Product__c = True, // Required for trigger entry criteria!
            CZ_ItemId__c = 'PRO-111',
            Core_Product__c = true,
            Record_Provisioning__c = 'NCMi Seat',
            NCM_Authorized_Products__c = 'NCMi Paid Seats'
        );
        insert(prod);

        PricebookEntry pbe = new PricebookEntry(
            IsActive = true,
            UnitPrice = 99.99,
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id
        );
        insert(pbe);

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00
        );
        insert(oli);
        OpportunityLineItem oliQueried = [SELECT Id, NCMi_Paid_Seat2__c FROM OpportunityLineItem LIMIT 1];
        System.debug('Line Item Paid Seat: ' +  oliQueried.NCMi_Paid_Seat2__c);
        Opportunity oppQueried = [SELECT Id, NCMi_Paid_Seat__c FROM Opportunity LIMIT 1];
        System.debug('Opportunity Paid Seat: ' +  oppQueried.NCMi_Paid_Seat__c);
    }


    @isTest
    static void deleteTest() {
        delete([SELECT Id FROM OpportunityLineItem LIMIT 1]);
        List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem];
        Assert.areEqual(0, olis.size());
    }

    @isTest
    static void deleteTest2() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Invoice Sent';
        update(opp);
        List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem];
        try {
            delete(olis[0]);
        } catch (Exception ex) {
            System.debug('ex.getTypeName: ' + ex.getTypeName());
            Assert.areEqual('System.DmlException', ex.getTypeName());
        }        
    }

    @isTest
    static void changeTest() {
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        oli.Quantity = 2;
        update(oli);
        OpportunityLineItem oli2 = [SELECT Id, Quantity FROM OpportunityLineItem LIMIT 1];
        Assert.areEqual(2, oli2.Quantity);
    }

    @isTest
    static void changeTest2() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Invoice Sent';
        update(opp);
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        try {
            oli.Quantity = 2;
            update(oli);
        } catch (Exception ex) {
            System.debug('ex.getTypeName: ' + ex.getTypeName());
            Assert.areEqual('System.DmlException', ex.getTypeName());
        }        
    }
}