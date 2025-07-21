@isTest
public with sharing class CZ_LoadProductsBatch_Test {
    @isTest
    public static void testLoadProducts() {
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());
        c2g__codaDimension1__c d1 = new c2g__codaDimension1__c(Name = 'Test Dim1', c2g__ReportingCode__c = 'TD1');
        insert d1;
        Product2 p = new Product2(Name = 'test product', Description = 'test description', Product_Value__c = -50, IsActive = true, Dimension_1__c = d1.Id);
        insert p;
        Test.startTest();
        Id pid;
        CZ_LoadProductsBatch lpb = new CZ_LoadProductsBatch(pid);
        database.executebatch(lpb);
        Test.stopTest();
        Product2 p2 = [SELECT Id, CZ_ItemId__c FROM Product2 LIMIT 1];
        Assert.areEqual('PRO-1234567899', p2.CZ_ItemId__c);
    }
}