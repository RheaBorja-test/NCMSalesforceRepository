public class AccountTypeUpdateQueueable implements Queueable {
    
    private Set<Id> parentAccountIds;

    public AccountTypeUpdateQueueable(Set<Id> parentAccountIds) {
        this.parentAccountIds = parentAccountIds;
    }
    
    public void execute(QueueableContext context) {
        
        System.debug('AccountTypeUpdateQueueable.Execute');
        
        Map<Id, String> parentAccountMap = new Map<Id, String>();    
        // Query the parent accounts and build the parentAccountMap
        List<Account> parentAccounts = [SELECT Name, Id, Type
                                        FROM Account 
                                        WHERE Id IN :parentAccountIds];

        // Get all parent account ids to use in the child query. 
        Set<Id> allParentIds = new Set<Id>();
        for(Account acct :parentAccounts) {
            parentAccountMap.put(acct.Id, acct.Type);
        }
        System.debug('AccountTypeUpdateQueueable: parentAccountMap contains ' + parentAccountMap.size() + ' elements.');
        
        List<Account> childAccounts = [SELECT Name, Id, Type, Ultimate_Parent_Account_Id__c
                                       FROM Account 
                                       WHERE Ultimate_Parent_Account_Id__c IN :parentAccountIds
                                      	AND Id NOT IN :parentAccountIds
                                      ];
        
        System.debug('AccountTypeUpdateQueueable: childAccounts.size(): ' + childAccounts.size());
        
        // Loop through child accounts and update their type with the parent account type.
        List<Account> descendantAccounts = new List<Account>();
        for(Account childAcct :childAccounts) {
            String parentType = parentAccountMap.get(childAcct.Ultimate_Parent_Account_Id__c);
            System.debug('AccountTypeUpdateQueueable: Child account: ' + childAcct.Name);
            //if(parentType != null && parentType != childAcct.Type) {
                System.debug('AccountTypeUpdateQueueable: updating account (' + childAcct.Name + ') to type [' + parentType + '].');
                childAcct.Type = parentType;
                descendantAccounts.add(childAcct);
           	//} else {
             	//System.debug('AccountTypeUpdateQueueable: parentType [' + parentType + '] is equal to childAcct.Type [' + childAcct.Type + '].');
            //}
        }
        System.debug('AccountTypeUpdateQueueable: descendantAccounts.size(): ' + descendantAccounts.size());
        
        try {
            List<Database.SaveResult> saveResults = Database.update(descendantAccounts, false);
            for(Database.SaveResult result : saveResults) {
                //if(!result.isSuccess()) {
                if(result.isSuccess()) {
                    System.debug('Successfully updated descendant accounts! ' + result.getId());
                } else {
                    for(Database.Error err :result.getErrors()) {
                        System.debug('The following error has occurred - ' + err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                        Logger.logErrorEvent('AccountTypeUpdateQueueable', null, UserInfo.getName(), 'Queueable', err.getMessage(), err.getMessage(), parentAccounts[0].Id);
                    }
                }                        
            }      
        } catch(Exception ex) {
            System.debug('AccountTypeUpdateQueueable: EXCEPTION: ' + ex.getMessage());
            Logger.logErrorEvent('AccountTypeUpdateQueueable', null, UserInfo.getName(), ex.getTypeName(), ex.getMessage(), ex.getStackTraceString());  
        }
    } 
} // End of class