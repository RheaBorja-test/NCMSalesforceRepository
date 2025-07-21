public class batchPINexpLines implements Database.Batchable<sObject> {
    public List<c2g__codaPurchaseInvoiceExpenseLineItem__c> expLns;

    public batchPINexpLines(List<c2g__codaPurchaseInvoiceExpenseLineItem__c> expLines){
        expLns = expLines;
    }

    public List<SObject> start(Database.BatchableContext bc){
        return expLns;
    }

    public void execute(Database.BatchableContext bc, list<sObject> scope){
        upsert scope;
    }

    public void finish(Database.BatchableContext bc){

    }
}