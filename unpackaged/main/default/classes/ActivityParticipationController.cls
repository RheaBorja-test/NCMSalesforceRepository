public class ActivityParticipationController {
    
    //create a class for an object to return a list of to LWC
    public class Act {
        @AuraEnabled public String Id;
        @AuraEnabled public String attId;
        @AuraEnabled public String Name;
        @AuraEnabled public Boolean Bool;
    }
    
    //this method is wired to the lwc
    @AuraEnabled(cacheable=true)
    public static List<Act> getActivities(String engAttendeeId){
        System.debug('~~~starting getActivities with: ' + engAttendeeId);
        try { 
            List<Act> actList = new List<Act>();
            Map<Id, Activity_Participation__c> apMap = new Map<Id, Activity_Participation__c>();

            //Query to get the list of Activity Participations for this Engagement Attendee
            Engagement_Attendee__c att = [SELECT Id, Engagement__c,
                                                (SELECT Id, 
                                                        Engagement_Activity__c, 
                                                        Total_Number_of_Participants__c 
                                                FROM Activity_Participation__r)
                                            FROM Engagement_Attendee__c
                                            WHERE Id = :engAttendeeId];
            System.debug('~~~att: ' + att);
            System.debug('~~~att.participations: ' + att.Activity_Participation__r);
            //Loop through the list and make a map with key of Id and value of the 
            //Activity Participation. Filter out Activity Participations with 0
            //Total Number of Participants.
            for(Activity_Participation__c ap : att.Activity_Participation__r) {
                if(ap.Total_Number_of_Participants__c > 0) {
                    apMap.put(ap.Engagement_Activity__c,ap);
                }
            }
                        
            //Loop through all activities for the engagement, check if this attendee is participating, 
            //and then create an Act and add it to the list to return.
            for(Engagement_Activity__c a : [SELECT Id, Name
                                                FROM Engagement_Activity__c
                                                WHERE Engagement__c = :att.Engagement__c]) {
                System.debug('~~~current activity: ' + a);
                Act currAct = new Act();
                currAct.attId = engAttendeeId;
                currAct.Id = a.Id;
                currAct.Name = a.Name;
                currAct.Bool = false;
                if(apMap.containsKey(a.Id) && apMap.get(a.Id).Total_Number_of_Participants__c > 0) {
                    currAct.Bool = true;
                }
                actList.add(currAct);
            }
            System.debug('~~~actList: ' + actList);
            return actList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //this method is called by the lwc when the box is checked
    @AuraEnabled
    public static void makeActivityParticipation(String att, String act){
        try {
            insert new Activity_Participation__c(Engagement_Attendee__c = att, Engagement_Activity__c = act);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //this method is called by the lwc when the box is unchecked. It intentionally deletes all activity participations
    //for this activity and this attendee, in case there is bad data.
    @AuraEnabled
    public static void deleteActivityParticipation(String att, String act){
        try {
            delete [SELECT Id FROM Activity_Participation__c WHERE Engagement_Attendee__c = :att AND Engagement_Activity__c = :act];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}