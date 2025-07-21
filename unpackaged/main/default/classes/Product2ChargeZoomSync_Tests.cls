@IsTest
public class Product2ChargeZoomSync_Tests {
    @TestSetup
    static void makeData(){
        
        // Sample Dimensions and Products
        c2g__codaDimension1__c testDimension1 = new c2g__codaDimension1__c(
            Name = 'Test Dimension1',
            c2g__ReportingCode__c = '2000',
            Conductor_CC_Email__c = 'mdemeglio@ncmassociates.com'
        );
        insert(testDimension1);

        // 20G Quarterly Product and Shipping
        List<Product2> testProducts = new List<Product2>();
        Product2 test20GroupQuarterlyProduct = new Product2(
            IsActive = true,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('20 Groups').getRecordTypeId(),
            Name = '20 Group Quarterly Product',
            Dimension_1__c = testDimension1.Id,
            Product_Value__c = 500.00,
            Production_Run_Type__c = 'Not Applicable',
            Family = '20 Groups',
            Locked_Frequency__c = 'Quarterly',
            Shipped_Product__c = True, // Required for trigger entry criteria!
            CZ_ItemId__c = 'PRO-111'
        );
        insert(test20GroupQuarterlyProduct);

    }


    @isTest 
    private static void batchUpdatesCZTest(){
        // Identify the Mock class
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());
        Product2ChargeZoomSync syncJob = new Product2ChargeZoomSync();

        Test.startTest();
            Database.executeBatch( syncJob );
        Test.stopTest();

        List<Product2> updatedProductResults = [select id, name, Last_CZ_Sync__c from Product2 where Last_CZ_Sync__c = today];
        Assert.areEqual(1, updatedProductResults.size());
    }

}