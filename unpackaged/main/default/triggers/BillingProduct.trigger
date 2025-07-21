trigger BillingProduct on Billing_Product__c (after insert, after update, before delete, after delete) {
    new BillingProductTriggerHandler().run();
}