public class OpportunityProductTriggerHandler extends TriggerHandler {
    public override void beforeUpdate() {
    	OpportunityProductController.onChange((List<OpportunityLineItem>) Trigger.new, (Map<Id,OpportunityLineItem>) Trigger.oldMap);
    } 

    public override void beforeDelete() {
        OpportunityProductController.customValidation((List<OpportunityLineItem>) Trigger.old);
    }
}