public class AccountController {
    
    @InvocableMethod(Label='Update Account Types' Description='Call AccountTypeUpdateQueueable class' Category = 'Account')
    public static void updateAccountTypes(List<Account> newAccounts) {
        Set<Id> parentAccountIds = (new Map<Id, Account>(newAccounts)).keySet();		
        if(!parentAccountIds.isEmpty()) { 
            Id jobId = System.enqueueJob(new AccountTypeUpdateQueueable(parentAccountIds)); 
        }
    }

} // End of AccountController