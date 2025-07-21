trigger TransactionLineItem on c2g__codaTransactionLineItem__c (after update) {
    new TransactionLineItemTriggerHandler().run();
}