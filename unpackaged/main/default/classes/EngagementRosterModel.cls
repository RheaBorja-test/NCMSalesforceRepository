global class EngagementRosterModel {
    

        global class EngagementRosterResponse{
            global String statusCode {get;set;}
            global String status {get;set;}
            global String message {get;set;}
            global String engagementID {get;set;}
            global EngagementRosterModel.Engagement engagement {get;set;}
        }
    
        public class Engagement {
        
            public String engagementId {get;set;}
            public String groupNumber {get;set;}
            public String meetingCycle {get;set;}
            public Date startDate {get;set;}
            public Date endDate {get;set;}
            public Date roomsFrom {get;set;}
            public Date roomsTo {get;set;}
            public Date roomBlockCutoff {get;set;}
            public String confirmedHotel {get;set;}
            public String groupName {get;set;}
            public String meetingSupportContactName {get;set;}
            public String meetingSupportContactEmail {get;set;}
            public List<EngagementRosterModel.EngagementAttendee> attendees {get;set;}
            public List<EngagementRosterModel.EngagementActivity> activities {get;set;}
            
        }
    
    
    	public class EngagementActivity{
            public String id {get;set;}
            public String name {get;set;}
            public Decimal headCount {get;set;}
            public DateTime startDate {get;set;}
            
        }
    
        public class EngagementAttendee{
            //Id, X20_Groups_Member__r.Group_Member_Number__c, Contact__r.Name, Attendee_Type__c, Attendance_Status__c, Arrival__c, Departure__c, Name
            public String attendeeId {get;set;}
            public String name {get;set;}
            public Decimal memberNumber {get;set;}
            public String attendeeType {get;set;}
            public String attendeeStatus {get;set;}
            public DateTime arrivalDate {get;set;}
            public DateTime departureDate {get;set;}
            public String groupMemberType {get;set;}
            public String collateralName {get;set;}
            public Boolean duplicateMember {get;set;}
            public String ageGroup {get;set;}
            public Boolean inMeetingRoom {get;set;}
            public Boolean hotelConfirmed {get;set;}
            public String hotelConfirmationNumber {get;set;}
            public String associatedAttendee {get;set;}
            //public Map<String, Integer> activities {get;set;}
            public List<AttendeeActivitySummary> activities {get;set;}
        }
    
        public class AttendeeActivitySummary{
            public String id{get;set;}
            public String name{get;set;}
            public Integer count{get;set;}
        }
}