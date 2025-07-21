@isTest
private class BillingAccountChargeZoomSync_Test {
    @TestSetup
    static void makeData(){
        Account act = new Account(
            Name = 'Metroville Dodge', 
            BillingStreet = '111 Main St', 
            BillingCity = 'Metroville', 
            BillingStateCode = 'NC', 
            BillingPostalCode = '27554',
            c2g__codaAccountTradingCurrency__c = 'USD'
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
            Primary_Contact__c = joe.Id,
            CZ_CustomerId__c = 'CUS-1234'
        );
        update ba;
    }

    @isTest
    static void batchTest() {
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());

        Test.startTest();
            BillingAccountChargeZoomSync b = new BillingAccountChargeZoomSync();
            b.overrideDate = Date.today();
            Database.executeBatch(b, 1);
        Test.stopTest();
        
        List<Error_Logger__c> errList = [SELECT Id FROM Error_Logger__c];
        Assert.areEqual(0, errList.size());
    }

    /*@IsTest
    static void schedulableTest(){
        String CRON_EXP = '0 6 * * * ?';
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());

        Test.startTest();
        String jobId = System.schedule('Update Contacts', CRON_EXP, new BillingAccountChargeZoomSync_Schedulable());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
    }*/
}