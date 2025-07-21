@isTest
public with sharing class UpdateDim2Test {
    @TestSetup
    static void setup(){
        SampleDataFactory.createData();
    
    }

    @IsTest
    static void testInvocable(){
        Test.startTest();
            Id ownerId = [SELECT Id FROM Contact WHERE Email = 'barney.billingsly@ncmassociates.com' LIMIT 1].Id;
            Proprietary_Group__c pg = [SELECT Id, Name, Group_Owner__r.Name FROM Proprietary_Group__c LIMIT 1];
            pg.Group_Owner__c = ownerId;
            update pg;
            Twenty_Groups__c tg = [SELECT Id FROM Twenty_Groups__c LIMIT 1];
            tg.NCM_Proprietor__c = ownerId;
            update tg;
                        
        Test.stopTest();

        List<X20_Groups_Member__c> tgms = [SELECT Id, 
                                                (SELECT Id, Dimension_2_Name__c 
                                                FROM Billing_Products__r 
                                                WHERE Billing_Product_Status__c IN ('Active', 'Suspended')
                                                AND Product__r.Name LIKE 'SHIPPING%') 
                                            FROM X20_Groups_Member__c];

        Assert.areEqual('Barney Billingsly', tgms[1].Billing_Products__r[0].Dimension_2_Name__c);
    }
    
}