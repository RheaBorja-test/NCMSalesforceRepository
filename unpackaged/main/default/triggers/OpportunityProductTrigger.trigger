trigger OpportunityProductTrigger on OpportunityLineItem (before update, before delete) {
    new OpportunityProductTriggerHandler().run();
}