trigger PropGroupTrigger on Proprietary_Group__c (after update) {
    new PropGroupTriggerHandler().run();
}