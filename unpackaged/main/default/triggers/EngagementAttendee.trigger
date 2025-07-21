trigger EngagementAttendee on Engagement_Attendee__c (before insert, before update, after insert, after update) {
    new EngagementAttendeeTriggerHandler().run();
}