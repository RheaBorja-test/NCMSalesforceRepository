@isTest
public class FoundationDirectAPI_Tests {
    
    @TestSetup
    static void makeData(){
        SampleDataFactory.create20GroupAccountData();
    }

    @isTest
    static void validAccountUpdatedWithFDID(){
        Account testAccount = [select id from Account limit 1];
        String sampleFDid = 'fd-1234';
        FoundationDirectModel.FoundationDirectResponse resp;

        Test.startTest();
            resp = FoundationDirectAPI.updateAccountWithFDId(testAccount.Id, sampleFDid);
        Test.stopTest();

        // Did the service return a success response?
        Assert.areEqual('200', resp.status);

        // Did the account update correctly?
        Account acctResult = [select id, Foundation_Direct_Id__c from Account where ID = :testAccount.Id];
        Assert.areEqual(sampleFDid, acctResult.Foundation_Direct_Id__c);

    }

    @isTest
    static void invalidAccountIdReturnsErrorCode(){
        
        String invalidAcctId = 'abc123'; // Simulate when FD sends an invalid Account ID to us.
        String sampleFDid = 'fd-1234';
        FoundationDirectModel.FoundationDirectResponse resp;

        Test.startTest();
            resp = FoundationDirectAPI.updateAccountWithFDId(invalidAcctId, sampleFDid);
        Test.stopTest();

        // Did the service return a failure response?
        Assert.areEqual('500', resp.status);
        

    }


    @isTest
    static void invalidFoundationDirectIdReturnsErrorCode(){
        
        String invalidAcctId = 'abc123'; 
        String sampleFDid = ''; // Simulate a missing fd id.
        FoundationDirectModel.FoundationDirectResponse resp;

        Test.startTest();
            resp = FoundationDirectAPI.updateAccountWithFDId(invalidAcctId, sampleFDid);
        Test.stopTest();

        // Did the service return a failure response?
        Assert.areEqual('500', resp.status);
        

    }
}