public with sharing class MarkAsAttendedEngagementController
{
    public ApexPages.StandardSetController ssc {get; private set;}
    public List<Engagement_Attendee__c> Attendees;
    public string previouspage;
    
    public MarkAsAttendedEngagementController(ApexPages.StandardSetController controller) {
        previouspage  = ApexPages.currentPage().getParameters().get('retURL');
        ssc = controller;
        System.Debug (controller.getSelected());
        System.Debug (controller.getSelected().size());
        if (ssc.getSelected().size() > 0)
        {
            Attendees = ssc.getSelected();
            for(Engagement_Attendee__c attendee : Attendees )
            {
                attendee.Attendance_Status__c = 'Attended';
            }
        }
    }
    
    public PageReference Save()
    {
        update Attendees;
        ApexPages.Action action = new ApexPages.Action('{!cancel}');
        return action.Invoke(); // Redirects to the previous page.
    }
}