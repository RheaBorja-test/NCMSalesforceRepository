@isTest
public class CustomerSearchServiceTests {
    
    @TestSetup
    static void makeData(){
        SampleDataFactory.create20GroupAccountData();
    }

    @isTest
    static void searchByCustNameTest(){

        // Get a known good 20G member Account that was created in TestSetup above.
        X20_Groups_Member__c test20GMemberAcct = [SELECT Account__c, Account__r.Name, Account__r.ShippingPostalCode 
                                                  FROM X20_Groups_Member__c LIMIT 1];
        CustomerSearchService.CustomerSearchContext searchContext = new CustomerSearchService.CustomerSearchContext();
        searchContext.customerName = test20GMemberAcct.Account__r.Name;
        searchContext.postalCode = test20GMemberAcct.Account__r.ShippingPostalCode;

        // Create a response variable to hold the results of our search method call.
        CustomerSearchService.CustomerSearchResponse resp = new CustomerSearchService.CustomerSearchResponse();

        Test.startTest();
            resp = CustomerSearchService.search(searchContext);
        Test.stopTest();

        // Did the search return the expected account as a customer result?
        Assert.areEqual('200', resp.statusCode, 'The response was not 200 (success).');
        Assert.areNotEqual(null, resp.results);
        Assert.areEqual(1, resp.results.size());

    }
    
    // Test: Pass in a customerName and only send in the first 5 characters.  
    @isTest
    static void searchByCustNameTest_2(){

        // Get a known good 20G member Account that was created in TestSetup above.
        X20_Groups_Member__c test20GMemberAcct = [SELECT Account__c, Account__r.Name, Account__r.ShippingPostalCode 
                                                  FROM X20_Groups_Member__c LIMIT 1];
        CustomerSearchService.CustomerSearchContext searchContext = new CustomerSearchService.CustomerSearchContext();
        searchContext.customerName = test20GMemberAcct.Account__r.Name;
        searchContext.postalCode = test20GMemberAcct.Account__r.ShippingPostalCode;
        searchContext.customerName = 'SOME OTHER NAME'; // This should get trimmed to 5 charaters. 
        // Create a response variable to hold the results of our search method call.
        CustomerSearchService.CustomerSearchResponse resp = new CustomerSearchService.CustomerSearchResponse();

        Test.startTest();
            resp = CustomerSearchService.search(searchContext);
        Test.stopTest();

        // Did the search return the expected account as a customer result?
        Assert.areEqual('500', resp.statusCode, 'The response should indicate an error.'); 
        Assert.areEqual(null, resp.results);

    }
                                              
    // TEST: if(customerName.length() < 5) 'Please provide at least 5 characters for the customer name.';
    @isTest
    static void searchByCustNameTest_3(){

        // Get a known good 20G member Account that was created in TestSetup above.
        X20_Groups_Member__c test20GMemberAcct = [SELECT Account__c, Account__r.Name, Account__r.ShippingPostalCode 
                                                  FROM X20_Groups_Member__c LIMIT 1];
        CustomerSearchService.CustomerSearchContext searchContext = new CustomerSearchService.CustomerSearchContext();
        searchContext.customerName = test20GMemberAcct.Account__r.Name;
        searchContext.postalCode = test20GMemberAcct.Account__r.ShippingPostalCode;
        searchContext.customerName = 'Bob'; // 
        // Create a response variable to hold the results of our search method call.
        CustomerSearchService.CustomerSearchResponse resp = new CustomerSearchService.CustomerSearchResponse();

        Test.startTest();
            resp = CustomerSearchService.search(searchContext);
        Test.stopTest();

        // Did the search return the expected account as a customer result?
        Assert.areEqual('500', resp.statusCode, 'The response should indicate an error.'); 
        Assert.areEqual(null, resp.results);

    }

    @isTest
    static void searchByMemberNumberTest(){

        // Get a known good Account that was created in TestSetup above.
        //Account testAccount = [SELECT Id, Name, ShippingPostalCode FROM Account LIMIT 1];
        X20_Groups_Member__c testMember = [SELECT Account__c,Group_Member_Number__c 
                                           FROM X20_Groups_Member__c 
                                           WHERE Group_Member_Number__c != null limit 1];
        
        CustomerSearchService.CustomerSearchContext searchContext = new CustomerSearchService.CustomerSearchContext();
        searchContext.customerName = null;
        searchContext.postalCode = null;
        searchContext.memberNumber = testMember.Group_Member_Number__c;

        // Create a response variable to hold the results of our search method call.
        CustomerSearchService.CustomerSearchResponse resp = new CustomerSearchService.CustomerSearchResponse();

        Test.startTest();
            resp = CustomerSearchService.search(searchContext);
        Test.stopTest();

        // Did the search return the expected account as a customer result?
        Assert.areEqual('200', resp.statusCode, 'The response was not 200 (success).');
        Assert.areNotEqual(null, resp.results);
        Assert.areEqual(1, resp.results.size());

    }
    
    // Test: 'Member Number invalid. Member number must be in the form ####-##';
    @isTest
    static void searchByMemberNumberTest_2(){

        // Get a known good Account that was created in TestSetup above.
        //Account testAccount = [SELECT Id, Name, ShippingPostalCode FROM Account LIMIT 1];
        X20_Groups_Member__c testMember = [SELECT Account__c,Group_Member_Number__c FROM X20_Groups_Member__c WHERE Group_Member_Number__c != null limit 1];
        
        CustomerSearchService.CustomerSearchContext searchContext = new CustomerSearchService.CustomerSearchContext();
        searchContext.customerName = null;
        searchContext.postalCode = null;
        //searchContext.memberNumber = testMember.Group_Member_Number__c;
        searchContext.memberNumber = '12345'; // Wrong format and length 

        // Create a response variable to hold the results of our search method call.
        CustomerSearchService.CustomerSearchResponse resp = new CustomerSearchService.CustomerSearchResponse();

        Test.startTest();
            resp = CustomerSearchService.search(searchContext);
        Test.stopTest();

        // Did the search return the expected account as a customer result?
        Assert.areEqual('500', resp.statusCode, 'The response should indicate an error.');
        Assert.areEqual(null, resp.results);

	}
    

    @isTest
    static void searchByCustomerIdTest(){

        // Get a known good Account that was created in TestSetup above.
        Account testAccount = [SELECT Id, Name, ShippingPostalCode FROM Account LIMIT 1];
        CustomerSearchService.CustomerSearchContext searchContext = new CustomerSearchService.CustomerSearchContext();
        searchContext.customerId = testAccount.Id;
           
        // Create a response variable to hold the results of our search method call.
        CustomerSearchService.CustomerSearchResponse resp = new CustomerSearchService.CustomerSearchResponse();

        Test.startTest();
            resp = CustomerSearchService.search(searchContext);
        Test.stopTest();

        // Did the search return the expected account as a customer result?
        Assert.areEqual('200', resp.statusCode, 'The response was not 200 (success).');
        Assert.areNotEqual(null, resp.results);
        Assert.areEqual(1, resp.results.size());

    }
    
    // TEST: if(customerId.length() < 15); 'Invalid record id length: '
    @isTest
    static void searchByCustomerIdTest_2(){

        // Get a known good Account that was created in TestSetup above.
        Account testAccount = [SELECT Id, Name, ShippingPostalCode FROM Account LIMIT 1];
        CustomerSearchService.CustomerSearchContext searchContext = new CustomerSearchService.CustomerSearchContext();
        // searchContext.customerId = testAccount.Id;
        searchContext.customerId = '123456789'; 
           
        // Create a response variable to hold the results of our search method call.
        CustomerSearchService.CustomerSearchResponse resp = new CustomerSearchService.CustomerSearchResponse();

        Test.startTest();
            resp = CustomerSearchService.search(searchContext);
        Test.stopTest();

        // Did the search return the expected account as a customer result?
        Assert.areEqual('500', resp.statusCode, 'The response should indicate an error.'); 
        Assert.areEqual(null, resp.results);

    }
    
    // TEST: if(postalCode.length() < 5); 'Postal code must be at 5 characters in length'
    @isTest
    static void searchByMemberNumberTest_3(){

        // Get a known good Account that was created in TestSetup above.
        //Account testAccount = [SELECT Id, Name, ShippingPostalCode FROM Account LIMIT 1];
        X20_Groups_Member__c testMember = [SELECT Account__c,Group_Member_Number__c FROM X20_Groups_Member__c WHERE Group_Member_Number__c != null limit 1];
        
        CustomerSearchService.CustomerSearchContext searchContext = new CustomerSearchService.CustomerSearchContext();
        searchContext.customerName = 'Lionel';
        searchContext.postalCode = '1234'; // Should trigger error message. postalCode is < 5.

        // Create a response variable to hold the results of our search method call.
        CustomerSearchService.CustomerSearchResponse resp = new CustomerSearchService.CustomerSearchResponse();

        Test.startTest();
            resp = CustomerSearchService.search(searchContext);
        Test.stopTest();

        // Did the search return the expected account as a customer result?
        Assert.areEqual('500', resp.statusCode, 'The response should indicate an error.');
        Assert.areEqual(null, resp.results);

	}  
    
    
   
    // TEST: BuildingNumber is provided?. 
    @isTest
    static void searchByMemberNumberTest_4(){

        // Get a known good Account that was created in TestSetup above.
        //Account testAccount = [SELECT Id, Name, ShippingPostalCode FROM Account LIMIT 1];
        X20_Groups_Member__c testMember = [SELECT Account__c,Group_Member_Number__c FROM X20_Groups_Member__c WHERE Group_Member_Number__c != null limit 1];
        
        CustomerSearchService.CustomerSearchContext searchContext = new CustomerSearchService.CustomerSearchContext();
        searchContext.customerName = 'Lionel';
        searchContext.postalCode = '12345'; 
        searchContext.buildingNumber = '12345';

        // Create a response variable to hold the results of our search method call.
        CustomerSearchService.CustomerSearchResponse resp = new CustomerSearchService.CustomerSearchResponse();

        Test.startTest();
            resp = CustomerSearchService.search(searchContext);
        Test.stopTest();
		
        
        System.debug('CUSTOMER SEARCH SERVICE TEST: RESPONSE STATUS CODE: ' + resp.statusCode);
        // Did the search return the expected account as a customer result?
        Assert.areEqual('500', resp.statusCode, 'The response should indicate an error.');
        Assert.areEqual(null, resp.results);

	}
    
      
    // TEST: BuildingNumber is NOT provided?. 
    @isTest
    static void searchByMemberNumberTest_5(){

        // Get a known good Account that was created in TestSetup above.
        //Account testAccount = [SELECT Id, Name, ShippingPostalCode FROM Account LIMIT 1];
        X20_Groups_Member__c testMember = [SELECT Account__c,Group_Member_Number__c FROM X20_Groups_Member__c WHERE Group_Member_Number__c != null limit 1];
        
        CustomerSearchService.CustomerSearchContext searchContext = new CustomerSearchService.CustomerSearchContext();
        searchContext.customerName = 'Lionel';
        searchContext.postalCode = '12345'; 
        //searchContext.buildingNumber = '12345';

        // Create a response variable to hold the results of our search method call.
        CustomerSearchService.CustomerSearchResponse resp = new CustomerSearchService.CustomerSearchResponse();

        Test.startTest();
            resp = CustomerSearchService.search(searchContext);
        Test.stopTest();
		
        
        System.debug('CUSTOMER SEARCH SERVICE TEST 5: RESPONSE STATUS CODE: ' + resp.statusCode);
        // Did the search return the expected account as a customer result?
        Assert.areEqual('500', resp.statusCode, 'The response should indicate an error.');
        Assert.areEqual(null, resp.results);

	}

    @isTest
    static void invalidSearchTest(){

        // Get a known good Account that was created in TestSetup above.
        Account testAccount = [SELECT Id, Name, ShippingPostalCode FROM Account LIMIT 1];
        CustomerSearchService.CustomerSearchContext searchContext = new CustomerSearchService.CustomerSearchContext();
        searchContext.customerName = testAccount.Name;
        searchContext.postalCode = null;//testAccount.ShippingPostalCode;

        // Create a response variable to hold the results of our search method call.
        CustomerSearchService.CustomerSearchResponse resp = new CustomerSearchService.CustomerSearchResponse();

        Test.startTest();
            resp = CustomerSearchService.search(searchContext);
        Test.stopTest();

        // Did the search return the expected account as a customer result?
        Assert.areEqual('500', resp.statusCode, 'The response should indicate an error.');
        Assert.areEqual(null, resp.results);

    }
    
    
    @isTest
    static void specialCompositeMemberIsReturnedTest(){

        // When a 20G Member of type "Special Composite" is searched for, the api will return a result.

        // Get a known good 20G member Account that was created in TestSetup above.
        X20_Groups_Member__c test20GMemberAcct = [SELECT Account__c, Account__r.Name, Account__r.ShippingPostalCode, Group_ID__c 
                                                  FROM X20_Groups_Member__c LIMIT 1];
        CustomerSearchService.CustomerSearchContext searchContext = new CustomerSearchService.CustomerSearchContext();
        searchContext.customerName = test20GMemberAcct.Account__r.Name;
        searchContext.postalCode = test20GMemberAcct.Account__r.ShippingPostalCode;
        
        // Create a 20 Group Member Account (the Related Full Membership account) to bypass VR: 'Type_Field_Cannot_Be_Updated'. 
        // The user is not able to update the Type field to ‘Additional Store’ or ‘Special Composite’ 
        // without populating the ‘Related Full Membership' lookup field.
        // The 'Related Full Membership' lookup has a filter where Status = 'Active', Type = 'Full Member', and Record Id's do not match.
        X20_Groups_Member__c test20GMemberAcct2 = new X20_Groups_Member__c(
            Group_ID__c = test20GMemberAcct.Group_ID__c,
            Account__c = test20GMemberAcct.Account__c,
            Member_Number__c = 1,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addYears(3),
            Type__c = 'Full Member',
            Status__c = 'Active'
        );
        insert(test20GMemberAcct2);

        // Change the test member type to "Special Composite", and populate the lookup to pass VR for this test.
        test20GMemberAcct.Type__c = 'Special_Composite';
        test20GMemberAcct.Related_Full_Membership__c = test20GMemberAcct2.Id;
        update(test20GMemberAcct);

        // Create a response variable to hold the results of our search method call.
        CustomerSearchService.CustomerSearchResponse resp = new CustomerSearchService.CustomerSearchResponse();

        Test.startTest();
            resp = CustomerSearchService.search(searchContext);
        Test.stopTest();

        // Did the search return the expected account as a customer result?
        Assert.areEqual('200', resp.statusCode, 'The response was not 200 (success).');
        Assert.areNotEqual(null, resp.results);
        Assert.areEqual(1, resp.results.size());

    }
    
    @isTest
    static void candidateMemberIsReturnedTest(){

        // When a 20G Member of type "Candidate" is searched for, the api will return a result.

        // Get a known good 20G member Account that was created in TestSetup above.
        X20_Groups_Member__c test20GMemberAcct = [SELECT Account__c, Account__r.Name, Account__r.ShippingPostalCode 
                                                  FROM X20_Groups_Member__c LIMIT 1];
        CustomerSearchService.CustomerSearchContext searchContext = new CustomerSearchService.CustomerSearchContext();
        searchContext.customerName = test20GMemberAcct.Account__r.Name;
        searchContext.postalCode = test20GMemberAcct.Account__r.ShippingPostalCode;

        // Change the test member type to "Candidate" for this test.
        test20GMemberAcct.Type__c = 'Candidate';
        update(test20GMemberAcct);


        // Create a response variable to hold the results of our search method call.
        CustomerSearchService.CustomerSearchResponse resp = new CustomerSearchService.CustomerSearchResponse();

        Test.startTest();
            resp = CustomerSearchService.search(searchContext);
        Test.stopTest();

        // Did the search return the expected account as a customer result?
        Assert.areEqual('200', resp.statusCode, 'The response was not 200 (success).');
        Assert.areNotEqual(null, resp.results);
        Assert.areEqual(1, resp.results.size());

    }
    
}