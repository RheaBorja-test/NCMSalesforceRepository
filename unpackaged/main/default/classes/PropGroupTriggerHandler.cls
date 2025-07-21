public class PropGroupTriggerHandler extends TriggerHandler {

    public override void afterUpdate() {
        PropGroupController.handleGroupOwnerChange(Trigger.new, (Map<Id, Proprietary_Group__c>)Trigger.oldMap);
    }

}