global class TrainingSubscriptionAccountMonitorBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
       
    private final String logTag = '[TrainingSubscriptionAccountMonitorBatch]';
    public String qry {get;set;}

    global TrainingSubscriptionAccountMonitorBatch() {
        // constructor logic
        this.qry = 'SELECT Id, Name, Account__c, Term_Termination_Date__c, Term_Start_Date__c ' + 
                'FROM Training_Subscription_Account__c ' + 
                'WHERE Term_Start_Date__c = TODAY OR Term_Termination_Date__c = TODAY';
    }

    global void execute(SchedulableContext SC) {
        TrainingSubscriptionAccountMonitorBatch batchJob = new TrainingSubscriptionAccountMonitorBatch();
        Database.executeBatch(batchJob,50);
    }

    global database.Querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(qry);
    }
    
    global void execute(Database.BatchableContext BC, List<Training_Subscription_Account__c> scope){
        System.debug(logTag + 'There are ' + scope.size() + ' records to process in this batch.');
        
        
        // Get a map of all the accounts we need to check.
        Set<Id> allAcctIdSet = new Set<Id>();
        Set<Id> tsaIdSet = new Set<Id>();

        for(Training_Subscription_Account__c tsa:scope){
            allAcctIdSet.add(tsa.Account__c);
            tsaIdSet.add(tsa.Id);
        }

        Map<Id,Account> acctMap = new Map<Id,Account>([select id, name, NCMI_Client_Code__c from account where id in :allAcctIdSet]);
        
        AggregateResult[] arResults = [SELECT Account__c, count(Id) 
                                        FROM Training_Subscription_Account__c 
                                        WHERE Account__c in :allAcctIdSet 
                                            AND Status_Formula__c = 'Active' 
                                            AND ID NOT IN :tsaIdSet
                                        GROUP BY Account__c];
        Map<Id,Integer> activeTSAMap = new Map<Id,Integer>();
        for(AggregateResult ar:arResults){
            Id acctId = (Id)ar.get('Account__c');
            activeTSAMap.put(acctId, Integer.valueOf(ar.get('expr0')) );
        }
        
        List<Account> acctsToUpdate = new List<Account>();

        for(Training_Subscription_Account__c tsa:scope){
            
            Account acct = acctMap.get(tsa.Account__c);
            
            if(tsa.Term_Start_Date__c == Date.Today()){
                System.debug('TSA starts today for ' + tsa.Name);
                // Check if the Account already has the NCMi checkbox checked.
                if(acct.NCMI_Client_Code__c == False){
                    System.debug(logTag + 'The account ' + acct.Name + ' will be updated to set NCMI Client Code to TRUE.');
                    acct.NCMI_Client_Code__c = True;
                    acctsToUpdate.add(acct);
                } else {
                    System.debug(logTag + 'The account ' + acct.Name + ' does not need to be updated, its NCMI Client Code is already checked.');
                }
            } else {
                System.debug('TSA ends today for ' + tsa.Name);
                // Check if the account has any other active TSAs.
                if(activeTSAMap.containsKey(acct.Id)){
                    System.debug(logTag + 'The account + ' + acct.Name + ' has other Active TSAs so its NCMI checkbox should remain checked (true).');
                } else {
                    if(acct.NCMI_Client_Code__c == True){
                        System.debug(logTag + 'The account ' + acct.Name + ' has no remaining Active TSAs. Its NCMI checkbox will be set to FALSE now.');
                        acct.NCMI_Client_Code__c = FALSE;
                        acctsToUpdate.add(acct);
                    } else {
                        System.debug(logTag + 'The account ' + acct.Name + ' has no remaining Active TSAs but its NCMI checkbox is already set to FALSE so there is no further action required.');
                    }
                }
            }
        }

        // Check if there are any Account records to update.
        if( !acctsToUpdate.isEmpty() ){
            System.debug(logTag + 'There are ' + acctsToUpdate.size() + ' account records to update.');
            Database.SaveResult[] saveResults = Database.update(acctsToUpdate, false);
            
            // Check for any DML errors.
            Integer i = 0;
            for(Database.SaveResult sr:saveResults){
                if( !sr.IsSuccess() ){
                    Account a = acctsToUpdate[i];
                    System.debug(logTag + 'There was a problem updating account [' + a.Name + ']. Error: ' + sr.getErrors()[0].getMessage());
                    Logger.logError(
                        logTag + 'Update Account NCMI Client Code field', 
                        'ERROR', 
                        logTag, 
                        'DML Error', 
                        sr.getErrors()[0].getMessage(), 
                        null
                    );
                }
                i++;
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug(logTag + 'Finished.');
    }
}