public class EngagementRosterPrintModel{

    
    public class Engagement {
    
        public String engagementId {get;set;}
        public String name {get;set;}
        public String groupName {get;set;}
        public String groupNumber {get;set;}
        public String confirmedHotel {get;set;}
        public String startDate {get;set;}
        public String endDate {get;set;}
        public String meetingCycle {get;set;}
        public String hotelName {get;set;}
        public String hotelStartDate {get;set;}
        public String hotelEndDate {get;set;}
        public String hotelDeadline {get;set;}
        public Integer totalAdults {get;set;}
        public Integer totalTeens {get;set;}
        public Integer totalChildren {get;set;}
        public Integer totalInMeetingRoom {get;set;}
        public Integer totalRooms {get;set;}

        public List<EngagementRosterPrintModel.EngagementAttendee> attendees {get;set;}
        public List<EngagementRosterPrintModel.EngagementActivity> activities {get;set;}

        // Constructor to initialize the counter proprerties.
        public Engagement(){
            totalAdults = 0;
            totalTeens = 0;
            totalChildren = 0;
            totalRooms = 0;
            totalInMeetingRoom = 0;
        }
        
    }

    public class EngagementActivity{
        public String name {get;set;}
        public Decimal headCount {get;set;}
        public DateTime startDate {get;set;}
        public String id {get;set;}
    }

    public class EngagementAttendee implements Comparable{

        public String attendeeId {get;set;}
        public String attendeeType {get;set;}
        public String memberNumber {get;set;}
        public Integer sortVal {
            get{
                if(this.memberNumber.equalsIgnoreCase('MD')){
                    // Moderator - set their sortVal high so they are last in the roster list.
                    return 500;
                } else if(this.memberNumber.equalsIgnoreCase('SP')) {
                    // Speakers
                    return 400;
                } else if(this.memberNumber.equalsIgnoreCase('VS')){
                    // Visitors
                    return 200;
                } else if (this.memberNumber.isNumeric()){
                    // Members - use their actual Integer member number so they sort numerically correctly.
                    return Integer.valueOf(this.memberNumber);
                } else {
                    return 300;
                }
            }
        }
        public String name {get;set;}
        public String attendeeStatus {get;set;}
        public Integer numAdults {get;set;}
        public Integer numTeens {get;set;}
        public Integer numChildren {get;set;}
        public String arrivalDate {get;set;}
        public String departureDate {get;set;}
        public String hotelConfirmationNumber {get;set;}
        public String arrivalDetail {get;set;}
        public String hotelConfirmed {get;set;}
        public Integer numInMeetingRoom {get;set;}
        public String peopleInMeeting {get;set;}
        public String otherPeople {get;set;}
        public Integer numRooms {get;set;}
        public String color {get; set;}
        public String color2 {get; set;}
        public List<ActivitySummary> activities {get;set;}

        // This method comes from the Comparable interface and allows us to sort by the memberNumber attribute when
        // we have a List of EngagementAttendee records can call .sort() on that list.
        public Integer compareTo(Object compareTo) {
            // Cast argument to EngagementAttendee type.
            EngagementRosterPrintModel.EngagementAttendee compareToAtt = (EngagementRosterPrintModel.EngagementAttendee)compareTo;

            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (this.sortVal > compareToAtt.sortVal) {
                // Set return value to a positive value.
                returnValue = 1;
            } else if (this.sortVal < compareToAtt.sortVal) {
                // Set return value to a negative value.
                returnValue = -1;
            }

            return returnValue;       
        }
    }

    public class ActivitySummary{
        public Id activityId {get;set;}
        public String activityName {get;set;}
        public Integer numParticipants {get;set;}
    }

}