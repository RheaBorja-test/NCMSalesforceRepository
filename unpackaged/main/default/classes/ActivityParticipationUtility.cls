public with sharing class ActivityParticipationUtility {
    public static void meetingRoom(List<Activity_Participation__c> aPs) {
        //Create a set of the Engagement Attendee Ids for the Activity Participations that were
        //created, edited or deleted. I don't believe Edited will ever happen, but included just 
        //in case something wierd ever happens.
        Set<Id> eaSet = new Set<Id>();
        for(Activity_Participation__c ap : aPs) {
            eaSet.add(ap.Engagement_Attendee__c);
        }

        //Query the Engagement Attendee records and loop through them to see if the In Meeting Room
        //checkbox should be changed.
        List<Engagement_Attendee__c> easToUpdate = new List<Engagement_Attendee__c>();
        if(eaSet.size() > 0) {
            for(Engagement_Attendee__c ea : [SELECT Id, In_Meeting_Room__c,
                                                (SELECT Id FROM Activity_Participation__r WHERE Engagement_Activity__r.RecordType.Name = 'Meeting')
                                            FROM Engagement_Attendee__c
                                            WHERE Id IN :eaSet]) {
                if(ea.Activity_Participation__r.size() > 0 && !ea.In_Meeting_Room__c) {
                    easToUpdate.add(new Engagement_Attendee__c(id = ea.Id, In_Meeting_Room__c = true));
                } else if(ea.Activity_Participation__r.size() == 0 && ea.In_Meeting_Room__c) {
                    easToUpdate.add(new Engagement_Attendee__c(id = ea.Id, In_Meeting_Room__c = false));
                }
            }
        }

        if(easToUpdate.size() > 0) {
            List<Database.SaveResult> dsrList = Database.update(easToUpdate, false);
            Logger.logErrorList('ActivityParticipationUtility::meetingRoom', dsrList, easToUpdate);
        }
    }
}