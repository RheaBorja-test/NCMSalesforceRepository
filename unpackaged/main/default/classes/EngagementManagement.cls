public without sharing class EngagementManagement {

    @AuraEnabled(Cacheable = true)
    public static List<Engagement_Attendee__c> getAttendees(String engagementId){

      System.debug('EngagementManagement.getAttendees:engagementId >> ' + engagementId);

      List<Engagement_Attendee__c> attendees = [
        SELECT
            Id,
            Name,
            Contact__r.Name,
            Contact__r.FirstName,
            Contact__r.LastName,
            RecordType.Name,
            Attendee_Type__c,
            Registration_Received__c, // Date (Hidden Field for all Profiles, default value = TODAY() )
            Cancellation_Date__c,
            Attendance_Status__c, // Added 'Removed' to the Status to soft delete Attendee. 
            Account__r.Name,
            Arrival__c, // Date/Time ( 2023-08-23T15:32:00.000+0000 )
            Departure__c, // Date/Time ( 2023-08-23T15:32:00.000+0000 )
            // Account_City_State__c, // Formula Field
            City__c, 
            State__c,
            Collateral_Name__c,
            Collateral_First_Name__c,
            Collateral_Last_Name__c,
            Member_Number__c,
            In_Meeting_Room__c,
            Title__c,
            Winmaster_Member_Name__c,
            Hotel_Confirmed__c,
            Hotel_Confirmation_Number__c,
            Primary_Attendee_Code__c, 
            X20_Groups_Member__c,
            X20_Groups_Member__r.WinMaster_Member_Name__c,
            Proprietary_Account__c,
            Proprietary_Account__r.Group_Number__c,
            Proprietary_Account__r.WinMaster_Member_Name__c,
            X20_Groups_Member__r.Group_ID__r.Name
        FROM
            Engagement_Attendee__c
        WHERE
            Engagement__c = :engagementId AND Attendance_Status__c != 'Removed'
            Order By Member_Number__c, Primary_Attendee_Code__c
        ]; 
        System.debug('EngagementManagement.getAttendees:count >> ' + attendees.size());
        
        return attendees;
    } 

    @AuraEnabled(Cacheable = true)
    public static List<Engagement_Attendee__c> getActivityAttendence(String activityId) {

      System.debug('EngagementManagement.getActivityAttendence:activityId >> ' + activityId);
      
      List<Engagement_Attendee__c> newAttendees = [
        SELECT
            Id,
            Name,
            Engagement__c
        FROM
            Engagement_Attendee__c
        WHERE
            Attendance_Status__c NOT IN ('Removed', 'Not Attending')
            AND Engagement__c IN 
                (SELECT Engagement__c FROM Engagement_Activity__c WHERE Id = :activityId)
            AND Id NOT IN
                (SELECT Engagement_Attendee__c FROM Activity_Participation__c WHERE Engagement_Activity__c = :activityId)
        ]; 
        
        System.debug('EngagementManagement.getActivityAttendence:count >> ' + newAttendees.size());

        return newAttendees;
    }
}