@isTest
private class BillingProductsForTermedTST_Test {

    @testSetup
    static void generateData() {
        Account act = new Account(Name = 'Test Account');
        insert act;
        Billing_Account__c ba = [SELECT Id FROM Billing_Account__c WHERE Account__c = :act.Id LIMIT 1];
        Contact con = new Contact(FirstName = 'John', LastName = 'Tester', AccountId = act.Id);
        insert con;
        Training_Subscription__c ts = new Training_Subscription__c();
        insert ts;
        Training_Subscription_Term__c tst = new Training_Subscription_Term__c(
            Name = 'Test Term',
            Training_Subscription__c = ts.Id,
            Account__c = act.Id,
            Contact__c = con.Id,
            Transitioned_to_Monthly__c = false,
            Termination_Date__c = Date.today().addDays(-1)
        );
        insert tst;
        Training_Subscription_Account__c tsa = new Training_Subscription_Account__c(Name = 'Test tsa', Training_Subscription__c = tst.Id);
        insert tsa;
        Billing_Product__c bp = new Billing_Product__c(
            Billing_Frequency__c = 'Annually',
            Next_Billing_Date__c = Date.today().addDays(30),
            Billing_Account__c = ba.Id,
            Training_Subscription_Account__c = tsa.Id,
            Billing_Product_Status__c = 'Active',
            Recurring_Billing_day__c = Date.today().day() > 28 ? 28 : Date.today().day()
        );
        insert bp;
    }

    @isTest
    public static void test1() {
        Training_Subscription_Term__c tst = [SELECT Id, Term__c FROM Training_Subscription_Term__c LIMIT 1];
        Test.startTest();
            Database.executeBatch(new BillingProductsForTermedTST());
        Test.stopTest();
        Billing_Product__c bp = [SELECT Id, Billing_Product_Status__c FROM Billing_Product__c LIMIT 1];
        Assert.areEqual('Inactive', bp.Billing_Product_Status__c);
    }
}