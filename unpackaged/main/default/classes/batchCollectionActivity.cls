global class batchCollectionActivity implements Database.Batchable<sObject>, Database.Stateful {
    global string query;
    
    global database.Querylocator start(Database.BatchableContext BC){
        query = 'select id' + 
            ' from Finance_Accounts_Receivable__c' + 
            ' where Days_Outstanding_Calc__c > 34 and Collection_Activity__c = null and Invoice_Status__c <> \'Discarded\' and Payment_Status__c <> \'Paid\'' + 
            ' and Account__r.Do_not_Include_in_Collections__c = false' +
            ' order by Account__c';
        if(test.isRunningTest()){
            query = query + ' limit 1';
        }
        Database.QueryLocator result = Database.getQueryLocator(this.query);
        return result;
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        for(Sobject obj: scope){
            Finance_Accounts_Receivable__c AR = [select id, Name, Account__c, Account__r.Name, Collection_Activity__c, Billing_Contact__c
                                                 from Finance_Accounts_Receivable__c
                                                 where id = :obj.id ];
            
            if(AR.Collection_Activity__c == null){
                crtCse(AR.Account__r.Name, AR.Account__c, AR.Billing_Contact__c, AR.Name);
            }
        }
        
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
    
    private Client_Support_Ticket__c crtCse(string accNme, id accId, id conId, string arName){
        Client_Support_Ticket__c cse = new Client_Support_Ticket__c();
        
        cse.Account__c = accId;
        cse.Contact__c = conId;
        cse.Status__c = 'Open';
        cse.RecordTypeId = schema.SObjectType.Client_Support_Ticket__c.getRecordTypeInfosByName().get('Collection Activity').getRecordTypeId();
        cse.OwnerId = '0054A000009HatNQAS';
        
        if (accNme.length() > 75){
            accNme = accNme.left(75);
        }
        cse.Name = 'CA - ' + accNme;
        cse.Description__c = 'This Collection Activity was created by: ' + arName + 
            '. The case was created on: ' + string.valueOf(datetime.now());
        
        insert cse;
        
        return cse;
    }
}