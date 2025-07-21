public class TransactionLineItemTriggerHandler extends TriggerHandler  {
    public override void afterUpdate(){
        TransactionLineItemController.checkPayment((List<c2g__codaTransactionLineItem__c>)trigger.new, (Map<Id,c2g__codaTransactionLineItem__c>)trigger.oldMap);
        TransactionLineItemController.creditNote((List<c2g__codaTransactionLineItem__c>)trigger.new, (Map<Id,c2g__codaTransactionLineItem__c>)trigger.oldMap);
    }
}