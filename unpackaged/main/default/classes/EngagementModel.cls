global with sharing class EngagementModel {
    

    global class EngagementResponse{
        global String statusCode {get;set;}
        global String status {get;set;}
        global String message {get;set;}
        global String groupNumber {get;set;}
        public String moderatorName {get; set;}
        public String moderatorEmail {get;set;}
        public String clientSupportName {get;set;}       
        public String clientSupportEmail {get;set;}
        global String meetingSupportContactName {get;set;}
        global String meetingSupportContactEmail {get;set;}    
        // Next Meeting Info
        global Date nextMeetingDate {get; set;}
        global String nextMeetingLocation {get; set;}
        global Date nextHotelReservationDue {get; set;}
        global List<EngagementModel.Engagement> engagements {get;set;}
    }

    public class Engagement {
    
        public String engagementId {get;set;}
        public Date startDate {get;set;}
        public Date endDate {get;set;}
        public Date receptionDate {get;set;}
        public String confirmedHotel {get;set;}
        public String hotelStreet {get;set;}
        public String hotelCity {get;set;}
        public String hotelState {get;set;}
        public String hotelZipCode {get;set;}
        public String hotelCountry {get;set;}
        public String hotelEmail {get;set;}
        public String hotelFax {get;set;}
        public String hotelPhone {get;set;}
        public String hotelWebsite {get;set;}
        public String status {get;set;}
        public String shippingAddress {get;set;}
        public String checklistId {get;set;}
        public List<EngagementModel.EngagementAttendee> roster {get;set;}   
    }


    public class EngagementAttendee{
        //Id, X20_Groups_Member__r.Group_Member_Number__c, Contact__r.Name, Attendee_Type__c, Attendance_Status__c, Arrival__c, Departure__c, Name
        public String attendeeId {get;set;}
        public String name {get;set;}
        public String memberNumber {get;set;}
        public String type {get;set;}
        public String status {get;set;}
        public Date arrivalDate {get;set;}
        public Date departureDate {get;set;}
    }



}