// This covers the AccountController, AccountTypeUpdateQueueable classes.
@isTest
public class AccountControllerTest {
    
    @TestSetup
    static void setupTestData() {
        
        Account parentAccount = new Account (Name = 'Test Parent Account', Type = 'Customer');
        insert parentAccount;
        
        Account parentAccount2 = new Account (Name = 'Test Parent Account 2', Type = 'Enterprise');
        insert parentAccount2;
        
        Account childAccount1 = new Account (Name = 'Test Child Account1', ParentId = parentAccount.Id, Type = 'Customer');
        insert childAccount1;
        
        Account childAccount2 = new Account (Name = 'Test Child Account2', ParentId = parentAccount.Id, Type = 'Customer');
        insert childAccount2;
        
        Account grandChildAccount = new Account (Name = 'Test Grandchild Account', ParentId = childAccount1.Id, Type = 'Customer');
        insert grandChildAccount;
        
    }
    
    // Check to see if all the child, grandchild, great-grandchildren Account Type field is updated with 
    // the parent Account Type value. (Enterprise) 
    @isTest
    static void updateAccountTypesTest() {
        
        Account parentAccount = [SELECT Name, Type FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];
        
        parentAccount.Type = 'Enterprise';
        update parentAccount;
        
        // Enqueue the queueable job to update descendant accounts.
        Test.startTest();
        	System.enqueueJob(new AccountTypeUpdateQueueable(new Set<Id> {parentAccount.Id}));
        Test.stopTest();
        
        List<Account> accountsUpdated = [SELECT Id, ParentId, Type FROM Account WHERE ParentId = :parentAccount.Id];
                                              
        for(Account acct :accountsUpdated) {
            System.assertEquals('Enterprise', acct.Type, 'Account Types should equal Enterprise');           
        }         
    }   
    
    // Check to see if all the child, grandchild, great-grandchildren Account Type field is updated with 
    // the parent Account Type value. (Customer)
    @isTest
    static void updateAccountTypesTest_2() {
        
        Account parentAccount = [SELECT Name, Type FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];
        
        parentAccount.Type = 'Customer';
        update parentAccount;
        
        // Enqueue the queueable job to update descendant accounts.
        Test.startTest();
        	System.enqueueJob(new AccountTypeUpdateQueueable(new Set<Id> {parentAccount.Id}));
        Test.stopTest();
        
        List<Account> accountsUpdated = [SELECT Id, ParentId, Type FROM Account WHERE ParentId = :parentAccount.Id];
                                              
        for(Account acct :accountsUpdated) {
            System.assertEquals('Customer', acct.Type, 'Account Types should equal Customer');           
        }         
    } 
  
} // End of test class