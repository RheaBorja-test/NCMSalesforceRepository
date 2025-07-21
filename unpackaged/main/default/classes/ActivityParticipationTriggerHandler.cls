public class ActivityParticipationTriggerHandler extends TriggerHandler {
    public override void afterInsert() {
        ActivityParticipationUtility.meetingRoom((List<Activity_Participation__c>)trigger.new);
    }

    public override void afterUpdate(){
        ActivityParticipationUtility.meetingRoom((List<Activity_Participation__c>)trigger.new);
    }

    public override void afterDelete(){
        ActivityParticipationUtility.meetingRoom( (List<Activity_Participation__c>)trigger.old);
    }
}