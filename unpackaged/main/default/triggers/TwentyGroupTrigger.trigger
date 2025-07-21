trigger TwentyGroupTrigger on Twenty_Groups__c (after update) {
    new TwentyGroupTriggerHandler().run();
}