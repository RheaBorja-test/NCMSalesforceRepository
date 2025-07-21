@isTest
public with sharing class GroupAccountServiceTests {
    
    @TestSetup
    static void setup(){
        SampleDataFactory.createData();
    }

    @isTest
    static void twentyGroupMemberSearch(){
        
        X20_Groups_Member__c test20GroupMember = [SELECT Id, Account__r.Name, Group_Member_Number__c, Status__c FROM X20_Groups_Member__c LIMIT 1];
        System.debug('Test 20 Group Member: ' + test20GroupMember.Group_Member_Number__c);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/GroupAccount/' + test20GroupMember.Group_Member_Number__c;  //Request URL
        req.httpMethod = 'GET';//HTTP Request Type
        RestContext.request = req;
        RestContext.response= res;
        GroupAccountResponse result;
        
        Test.startTest();
            result = GroupAccountService.getAccountInfo();
        Test.stopTest();

        System.debug('Test Result: ' + result);
        Assert.isNotNull(result);
        Assert.areEqual('Success', result.status);
        Assert.areEqual('200', result.statusCode);
        Assert.areEqual('20 Group', result.groupType);
        Assert.areEqual(test20GroupMember.Account__r.Name, result.accountName);

    }

    @isTest
    static void benchmarkingGroupMemberSearch(){
        
        Proprietary_Account__c testGroupMember = [SELECT Id, Account__r.Name, Group_Member_Number__c, Status__c FROM Proprietary_Account__c LIMIT 1];
        System.debug('Test Benchmarking Group Member: ' + testGroupMember.Group_Member_Number__c);
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/GroupAccount/' + testGroupMember.Group_Member_Number__c;  //Request URL
        req.httpMethod = 'GET';//HTTP Request Type
        RestContext.request = req;
        RestContext.response= res;
        GroupAccountResponse result;
        
        Test.startTest();
            result = GroupAccountService.getAccountInfo();
        Test.stopTest();

        System.debug('Test Result: ' + result);
        Assert.isNotNull(result);
        Assert.areEqual('Success', result.status);
        Assert.areEqual('200', result.statusCode);
        Assert.areEqual('Benchmarking Group', result.groupType);
        Assert.areEqual(testGroupMember.Account__r.Name, result.accountName);

    }


    @isTest
    static void invalidMemberSearch(){

        // When a group member number is sent to the API, the service should return no results and a 500 status code.
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        String bogusNumber = '9999-00'; // A group member number that doesn't exist in the system.
        req.requestURI = '/services/apexrest/GroupAccount/'+bogusNumber;  //Request URL with BAD group member number.
        req.httpMethod = 'GET';//HTTP Request Type
        RestContext.request = req;
        RestContext.response= res;
        GroupAccountResponse result;
        
        Test.startTest();
            result = GroupAccountService.getAccountInfo();
        Test.stopTest();

        System.debug('Test Result: ' + result);
        Assert.isNotNull(result);
        Assert.areEqual('Error', result.status);
        Assert.areEqual('500', result.statusCode);
        Assert.areEqual('No results found for group account number ' + bogusNumber, result.message);
        
    }
}