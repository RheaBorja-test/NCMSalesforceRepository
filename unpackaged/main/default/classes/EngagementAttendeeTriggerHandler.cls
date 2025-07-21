public class EngagementAttendeeTriggerHandler extends TriggerHandler {
    
    public override void beforeInsert(){
        EngagementAttendeeService.setAttendeeNumbering(Trigger.new, null);
    } 

    public override void beforeUpdate(){        
        // Check for Attendee name changes
        EngagementAttendeeService.checkAttendeeChanges(Trigger.new, (Map<Id,Engagement_Attendee__c>)trigger.oldMap);        
        // Update Attendee name when Attendee Name or Attendee Type is changed, and doesn't match correct format. 
        EngagementAttendeeService.updateAttendeeName(Trigger.new, (Map<Id,Engagement_Attendee__c>)trigger.oldMap);

    }
    
    public override void afterInsert() {        
        // This calls the EngagementAttendeeUtilityReportQueueable if Attendee Status meets criteria. 
        EngagementAttendeeService.checkAttendeeStatus(Trigger.new, null);  
        // This calls the EngagementInstituteWelcomeEmailsBatch if Attendee meets criteria.
        EngagementAttendeeService.sendWelcomeEmails(Trigger.new, null);  
    }

    public override void afterUpdate(){
        
        // Remove inactive attendees from Engagement Activities..
        EngagementAttendeeService.removeFromActivities(Trigger.new, (Map<Id,Engagement_Attendee__c>)trigger.oldMap);
        // This calls the EngagementAttendeeUtilityReportQueueable if Attendee Status meets criteria. 
        EngagementAttendeeService.checkAttendeeStatus(Trigger.new, (Map<Id,Engagement_Attendee__c>)trigger.oldMap);     
        // Remove duplicate attendees from Meeting Room.
        EngagementAttendeeService.uncheckMeetingroom(Trigger.new, (Map<Id,Engagement_Attendee__c>)trigger.oldMap);  
		// This calls the EngagementInstituteWelcomeEmailsBatch if Attendee meets criteria.
        EngagementAttendeeService.sendWelcomeEmails(Trigger.new, (Map<Id,Engagement_Attendee__c>)trigger.oldMap);  

    }    
}