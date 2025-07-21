global class batchSINarReconcile implements Database.Batchable<SObject>,Database.Stateful, Database.AllowsCallouts {
    global string query;

    global database.Querylocator start(Database.BatchableContext BC){
        this.query = 'select id, Sales_Invoice__c from Finance_Accounts_Receivable__c ' +
                     'where Outstanding_Out_of_Sync__c = true ';
        
        if(test.isRunningTest()){
            this.query = this.query + 'limit 1';
        } else{
            this.query = this.query + 'limit 1000';
        }

        Database.QueryLocator result = Database.getQueryLocator(this.query);
        return result;
    }

    global void execute(Database.BatchableContext BC,List<sObject> scope){
        list<c2g__codaInvoice__c> slsInvs = new list<c2g__codaInvoice__c>();
        for(Sobject obj: scope){
            Finance_Accounts_Receivable__c AR = (Finance_Accounts_Receivable__c)obj;

            c2g__codaInvoice__c SIN = new c2g__codaInvoice__c();
            SIN.id = ar.Sales_Invoice__c;
            slsInvs.add(SIN);
        }
        Database.SaveResult[] resultInv = Database.update(slsInvs);
    }

    global void finish(Database.BatchableContext BC) {

    }
}