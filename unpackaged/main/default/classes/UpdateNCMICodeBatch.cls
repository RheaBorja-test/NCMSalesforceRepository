public class UpdateNCMICodeBatch implements Database.Batchable<sObject>, Database.Stateful {

    private String query;
	private Set<Id> updatedAccountsWithNCMI;
    
    public UpdateNCMICodeBatch() {
        
        // Initialize the Set to keep track of Accounts updated with NCMI_Client_Code__c = True.
        updatedAccountsWithNCMI = new Set<Id>();
        
        // query to retrieve all Training Subscription Accounts
        query = 'SELECT Id, Name, Account__r.Name, Account__r.NCMI_Client_Code__c, Status_Formula__c, Term_Start_Date__c, Term_Termination_Date__c ' + 
				'FROM Training_Subscription_Account__c ' + 
				'WHERE (Term_Termination_Date__c <= TODAY AND Account__r.NCMI_Client_Code__c = True) ' + 
				'OR (Term_Start_Date__c <= TODAY AND Status_Formula__c = \'Active\' AND Account__r.NCMI_Client_Code__c = False)';

        System.debug('QUERY: ' + query);
    }

    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    
    public void execute(Database.BatchableContext bc, List<Training_Subscription_Account__c> scope) {
        
        System.debug('There are ' + scope.size() + ' records in the scope for this batch.');
        System.debug('There are ' + updatedAccountsWithNCMI.size() + ' accounts that have already been processed and NCMI_Client_Code__c set to True.');
        



        //Loop through each TSA and create a list of expiring accounts and starting accounts.
        Set<Id> expiredAccounts = new Set<Id>();
        Set<Id> startingAccounts = new Set<Id>();
        List<Account> accountUpdates = new List<Account>();


        for(Training_Subscription_Account__c tsa:scope){
            if(tsa.Term_Start_Date__c <= Date.today() && tsa.Term_Termination_Date__c > Date.today()){
                // Starting.
                startingAccounts.add(tsa.Account__c);
            } else {
                // Expiring.
                expiredAccounts.add(tsa.Account__c);
            }
        }
        System.debug('Starting Accounts: ' + startingAccounts.size() + ', Expiring: ' + expiredAccounts.size());


        // For the Expiring accounts, check if there are any other Active TSAs for that account, if so, the NCMi checkbox should remain checked, if not, it should be unchecked.
        AggregateResult[] activeTSAs = [select Count(Id), Account__c from Training_Subscription_Account__c WHERE Status_Formula__c = 'Active' GROUP BY Account__c];
        Map<Id,Integer> acctActiveTSAMap = new Map<Id,Integer>();
        for(AggregateResult ar : activeTSAs){
            Id acctId = (Id) ar.get('Account__c');
            Integer tsaCount = (Integer) ar.get('expr0');
            System.debug('Account [' + acctId + '] has [' + tsaCount + '] active TSA records.');
            acctActiveTSAMap.put( 
                acctId,
                tsaCount
            );
            System.debug('Active TSA count for ' + ar.get('Account__c') + ': ' + ar.get('expr0'));
        }
        
        // Check each account in the expiring list and check if at least one active TSA exists.
        for(Id acctId : expiredAccounts){
            Account acct = new Account(Id=acctId);
            if(acctActiveTSAMap.containsKey(acctId) && acctActiveTSAMap.get(acctId) > 0){
                // there is at least one active TSA for this account, leave the NCMi checkbox checked.
                System.debug('acctActiveTSMap contains a key for this account and its active TSA count is :' + acctActiveTSAMap.get(acctId) + ' setting to True.');
                acct.NCMI_Client_Code__c = True;
            } else {
                System.debug('No active TSA records for account ' + acctId + ', setting to FALSE.');
                acct.NCMI_Client_Code__c = False;
            }
            accountUpdates.add(acct);
        }


        //For the Starting accounts, simply make sure the NCMi checkbox is true.
        for(Id acctId:startingAccounts){
            Account acct = new Account(Id=acctId);
            acct.NCMI_Client_Code__c = True;
            accountUpdates.add(acct);
        }

        


        /*
        List<Account> accountsToUpdate = new List<Account>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        
        // Iterate through each Training Subscription Account
        for (Training_Subscription_Account__c subs : scope) {
            
            //Training_Subscription_Account__c subs = (Training_Subscription_Account__c)subscription;
            
            // Check if we have already processed the Account and it's NCMI_Client_Code__c was set to true, if it was, we won't add
            // the account anymore or change it to False.
            if(accountMap.containsKey(subs.Account__c) && accountMap.get(subs.Account__c).NCMI_Client_Code__c == True){
                System.debug('accountMap already contains account [' + subs.Account__c + ' and NCMI_Client_Code__c has been set to True, skipping.');
                continue; // Move to next TSA record in the loop.
            }
            
            Account account = new Account(Id = subs.Account__c);
            // Set the "NCMI (Client) Code" checkbox value based on the "Status Formula" field value
            if (subs.Status_Formula__c == 'Active') {
                account.NCMI_Client_Code__c = true;
            } else {
                account.NCMI_Client_Code__c = false;
            }
            
            // Add the Account to the map so that we can update it later on. This map allows us to make sure we only have one instance
            // of an Account in our collection of records to update - we can't have the same account in our update collection multiple times.
            //accountsToUpdate.add(account);
            accountMap.put(account.Id, account);
            
        }
        */

        // Update the Account records
        System.debug('Updating ' + accountUpdates.size() + ' accounts.');
        Database.SaveResult[] saveResults = Database.update(accountUpdates, false); // We pass the accountMap's values to the update() call since values is a list of Accounts. False indicates that if one record fails, the other records can still be saved ("AllOrNone" is the parameter name).
        
        // Inspect the Save Results so we can log any account update failures.
        Integer i = 0;
        for(Database.SaveResult sr : saveResults){
            Account savedAcct = accountUpdates[i];
            if( sr.isSuccess() ){
                // Successfully updated.
                System.debug('Updated account [' + savedAcct.Id + '] with NCMI_Client_Code__c: ' + savedAcct.NCMI_Client_Code__c);
                
                // If we set the NCMI_Client_Code__c to True, add the Account.Id to a global Set so that we know it has been set and can't be
                // un-set in a different batch.
                updatedAccountsWithNCMI.add(savedAcct.Id);
                
            } else {
                // Error updating.
                System.debug('Error updating account [' + savedAcct.Id + ']. Error: ' + sr.getErrors()[0].getMessage());
            }
            i++; // increment the counter 
        }
        
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('****DONE****');
    }
}