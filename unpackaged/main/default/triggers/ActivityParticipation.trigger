trigger ActivityParticipation on Activity_Participation__c (after insert, after update, after delete) {
    new ActivityParticipationTriggerHandler().run();
}