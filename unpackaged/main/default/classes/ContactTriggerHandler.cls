public class ContactTriggerHandler extends TriggerHandler{
    public override void beforeUpdate(){
        ContactService.preventMktoUpdates( (List<Contact>)Trigger.new, (Map<Id,Contact>)Trigger.oldMap);
    }
}