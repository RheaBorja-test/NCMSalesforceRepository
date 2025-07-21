@isTest
public class CustomerEntitlementsService_Tests {
    
    @TestSetup
    static void makeData(){
        SampleDataFactory.createPropAnd20GroupData();
    }

    @isTest
    static void getChangedAccountsTest(){
        List<Account> testAccounts = [select id from Account ];
        System.debug('There are ' + testAccounts.size() + ' accounts to work with.');

        for(Account a:testAccounts){
            a.aXcessa_Client_Code__c = true;
        }
        update(testAccounts);


        CustomerSubscriptionModel.CustomerEntitlementsResponse resp;
        Test.startTest();
            resp = CustomerEntitlementsService.getCustomerEntitlements();
        Test.stopTest();

        Assert.areEqual('200', resp.status);
        System.debug('Response message: ' + resp.message);
        //Assert.areEqual(testAccounts.size(), resp.accounts.size());

    }
}