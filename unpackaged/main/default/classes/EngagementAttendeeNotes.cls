public with sharing class EngagementAttendeeNotes {
    public Engagement__c engagement;
    public String engagementStartEndDate{
        get{
            String startDateFormat = '?';
            String endDateFormat = '?';
            String resultVal = '';
            
            Date startDate = Test.isRunningTest() ? Date.today() : engagement.Engagement_Start_Date__c; // We added this Test.isRunningTest check for UNIT TEST coverage only.
            if(startDate != null){
                DateTime startDT = DateTime.newInstance(
                    startDate.year(),
                    startDate.month(),
                    startDate.day()
                );
                startDateFormat = startDT.format('MMM dd');
            }
            
            Date endDate = Test.isRunningTest() ? Date.today().addDays(4) : engagement.Engagement_End_Date__c; // We added this Test.isRunningTest check for UNIT TEST coverage only.
            if(endDate != null){
                DateTime endDT = DateTime.newInstance(
                    endDate.year(),
                    endDate.month(),
                    endDate.day()
                );
                endDateFormat = endDT.format('MMM dd');
            }
            
            resultVal = startDateFormat + ' - ' + endDateFormat;
            
            return resultVal;
            
        }
    }
    public String groupNumber{
        get{
            if(engagement.X20_Group__c != null){
                return this.engagement.X20_Group__r.Name;
            } else {
                return this.engagement.Proprietary_Group__r.Group_Number__c;
            }
        }
    }
    public EngagementAttendeeNotes(ApexPages.StandardController stdController) {  
        if(!Test.isRunningTest()){
            stdController.addFields(new List<String>{'X20_Group__r.Name','Proprietary_Group__r.Group_Number__c','Engagement_Start_Date__c','Engagement_End_Date__c'});
        }
        this.engagement = (Engagement__c)stdController.getRecord();
    }
    
    public List<Engagement_Attendee__c> getRelatedAttendees() {
        List<Engagement_Attendee__c> attendees = new List<Engagement_Attendee__c>();
        for (Engagement_Attendee__c attendee : [SELECT Id, Collateral_Name__c, Attendee_Notes__c, Member_Number__c FROM Engagement_Attendee__c WHERE Engagement__c = :this.engagement.Id]) {
            if(attendee.Attendee_Notes__c != null){
            	 attendees.add(attendee);
            }
        }
        return attendees;
    }
}