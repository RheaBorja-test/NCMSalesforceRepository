public class BillingProductTriggerHandler extends TriggerHandler {
    
    //public override void beforeInsert(){}

    public override void afterInsert(){
        BillingProductController.addShippingProducts( (List<Billing_Product__c>)trigger.new, (Map<Id,Billing_Product__c>)trigger.oldMap );
        BillingProductController.updateAccount((List<Billing_Product__c>)trigger.new, new Map<Id,Billing_Product__c>());
    }
    
    //public override void beforeUpdate(){}
    
    public override void afterUpdate(){
        BillingProductController.addShippingProducts( (List<Billing_Product__c>)trigger.new, (Map<Id,Billing_Product__c>)trigger.oldMap );
        BillingProductController.updateAccount( (List<Billing_Product__c>)trigger.new, (Map<Id,Billing_Product__c>)trigger.oldMap );
    }

    public override void beforeDelete() {
        List<Id> idList = new List<Id>(trigger.oldMap.keyset());
        System.enqueueJob(new AccountClientStatusQueueable(idList));
    }

    public override void afterDelete(){
        BillingProductController.addShippingProducts( (List<Billing_Product__c>)trigger.old, (Map<Id,Billing_Product__c>)trigger.oldMap );
    }
}