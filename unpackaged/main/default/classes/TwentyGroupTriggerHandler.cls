public class TwentyGroupTriggerHandler extends TriggerHandler {

    public override void afterUpdate() {
        TwentyGroupController.handleGroupOwnerChange(Trigger.new, (Map<Id,Twenty_Groups__c>)Trigger.oldMap);
    }


}