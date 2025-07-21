public class EngagementRosterPDFController {

    public EngagementRosterPrintModel engModel {get;set;}
    public EngagementRosterPrintModel.Engagement eng {get;set;}
    public List<EngagementRosterPrintModel.EngagementAttendee> attendees {get;set;}
    public Map<Id, Engagement_Activity__c> activityMap {get;set;}
    public Map<Id, Integer> activityHeadCountMap {get; set;}
    public String currDateTime {get;set;}
    public Integer numCols {get;set;}
    public Integer colWidth {get;set;}
    public Integer legendWidth {get;set;}
    public Integer fontSize {get;set;}

    private Engagement__c theEngagement;
    private String engagementId;
    

    public EngagementRosterPDFController(ApexPages.StandardController stdController) {
        theEngagement = (Engagement__c)stdController.getRecord();
        this.engagementId = theEngagement.Id;
        this.activityMap = new Map<Id, Engagement_Activity__c>();
        this.activityHeadCountMap = new Map<Id,Integer>();
        this.currDateTime = DateTime.now().format('M/dd/yyyy hh:mm a');
        loadData(engagementId);
    }

    public void loadData(String engId){
        Engagement__c engagementResult = EngRostPortalService.getEngagement(engId);
        //System.debug('Processing Engagement : ' + engagementResult.Name);
        buildModel(engagementResult);
    }

    public void buildModel(Engagement__c engResult){

        // Populate the Engagement engModel class.
        this.eng = new EngagementRosterPrintModel.Engagement();
        this.eng.name = engResult.Name;
        this.eng.groupName = engResult.X20_Group__c != null ? engResult.X20_Group__r.Group_Name__c : engResult.Proprietary_Group__r.Name;
        this.eng.groupNumber = engResult.X20_Group__c != null ? engResult.X20_Group__r.Name : engResult.Proprietary_Group__r.Group_Name__c;
        this.eng.confirmedHotel = engResult.Confirmed_Hotel__r.Name;
        this.eng.startDate = formatDate(engResult.Engagement_Start_Date__c, 'MM/dd/yyyy');//'MMM d');
        this.eng.endDate = formatDate(engResult.Engagement_End_Date__c, 'MM/dd/yyyy');//'MMM d');'MMM d');
        this.eng.hotelName = engResult.Confirmed_Hotel__r.Name;
        this.eng.hotelStartDate = formatDate(engResult.Rooms_From__c, 'MM/dd/yyyy');//'MMM d');'MMM d');
        this.eng.hotelEndDate = formatDate(engResult.Rooms_To__c,'MM/dd/yyyy');//'MMM d');'MMM d');
        this.eng.meetingCycle = engResult.Meeting_Cycle__c;
        this.eng.hotelDeadline = formatDate(engResult.Room_Block_Cut_off__c, 'MM/dd/yyyy');//'MMM d');'MMM d');
        this.eng.totalRooms = 0;


        // Aggregate each Member's guests
        List<Engagement_Attendee__c> guestList = [SELECT Id, Name, Attendee_Type__c, Age_Group__c, Associated_Attendee__c,
                                                        Number_of_Rooms__c, Hotel_Confirmation_Number__c
                                                  FROM Engagement_Attendee__c 
                                                  WHERE Engagement__c = :this.engagementId 
                                                    AND Attendee_Type__c = 'Guest'
                                                    AND Attendance_Status__c = 'Confirmed'
                                                    AND Associated_Attendee__r.Attendance_Status__c = 'Confirmed'];
        
        System.debug('~~~guestList: ' + guestList);                                            
        Map<Id, List<Engagement_Attendee__c>> guestMap = new Map<Id, List<Engagement_Attendee__c>>();
        for(Engagement_Attendee__c guest:guestList){
            List<Engagement_Attendee__c> tmpAttList = new List<Engagement_Attendee__c>();
            if(guestmap.containsKey(guest.Associated_Attendee__c)){
                tmpAttList = guestMap.get(guest.Associated_Attendee__c);
            }
            tmpAttList.add(guest);
            guestMap.put(guest.Associated_Attendee__c, tmpAttList);
        }
        
        
        // Calculate the number of Engagement Activities and how many people are going with each Member
        List<EngagementRosterPrintModel.EngagementActivity> activityList = new List<EngagementRosterPrintModel.EngagementActivity>();
        for(Engagement_Activity__c ea:engResult.Activities__r){
            EngagementRosterPrintModel.EngagementActivity activity = new EngagementRosterPrintModel.EngagementActivity();
            activity.id = ea.Id;
            activity.name = ea.Name;
            activity.startDate = ea.Start__c;
            activity.headCount = 0; //ea.Total_Number_of_All_Participants__c;
            activityList.add(activity);
            this.activityMap.put(ea.Id, ea);
        }
        this.eng.activities = activityList;

        //calculate number of columns, font size and column width in table
        numCols = 23 + activityList.size();
        switch on activityList.size() {
            when 0, 1, 2, 3, 4, 5 {
                fontSize = 12;
                legendWidth = 180;
            }
            when 6, 7 {
                fontSize = 11;
                legendWidth = 170;
            }
            when 8, 9 {
                fontSize = 10;
                legendWidth = 160;
            }
            when 10, 11 {
                fontSize = 9;
                legendWidth = 150;
            }
            when else {
                fontSize = 8;
                legendWidth = 140;
            }
        }

        
        colWidth = fontSize + 2;

        //calculate the column width and font size.



        // Determine how many members + guests are going to each Activity.
        // This Map stores data in this format: 
        //      [ MemberID => [ActivityId => Number of people attending] ]
        Map<Id, Map<Id, Integer>> memberActivityMap = new Map<Id, Map<Id, Integer>>();
        for(Activity_Participation__c ap : [SELECT Id, Engagement_Activity__c, Engagement_Attendee__c, Engagement_Attendee__r.Associated_Attendee__c, Engagement_Attendee__r.Associated_Attendee__r.Attendance_Status__c, Engagement_Attendee__r.Name, Primary_Attendee_Code__c  
                                            FROM Activity_Participation__c 
                                            WHERE Engagement_Activity__r.Engagement__c = :this.engagementId
                                            AND Engagement_Attendee__r.Attendance_Status__c = 'Confirmed']){
            if(ap.Engagement_Attendee__r.Associated_Attendee__c != null && !ap.Engagement_Attendee__r.Associated_Attendee__r.Attendance_Status__c.equalsIgnoreCase('Confirmed')) {
                continue;
            }                                    
            // If the "Associated_Attendee__c" field is not null, this is a guest and we need to store that Associated_Attendee__c value so we can keep track of how 
            // many guests each member is bringing to an activity.
            Id memberId = ap.Engagement_Attendee__r.Associated_Attendee__c != null ? ap.Engagement_Attendee__r.Associated_Attendee__c : ap.Engagement_Attendee__c;
            Id activityId = ap.Engagement_Activity__c;

            Map<Id,Integer> actAttendanceMap; // tracks how many people are going to a particular event.
            if(memberActivityMap.containsKey(memberId)){
                //System.debug('actAttendanceMap already exists for memberId: ' + memberId);
                actAttendanceMap = memberActivityMap.get(memberId); // keep using the existing map and add to it.
            } else {
                //System.debug('actAttendanceMap is being initialized for memberId: ' + memberId);
                actAttendanceMap = new Map<Id,Integer>();
            }

            if(actAttendanceMap.containsKey(activityId)){
                Integer currCount = actAttendanceMap.get(activityId); // just increment the number of attendees for this event.
                currCount++; // add one for this participant.
                actAttendanceMap.put(activityId, currCount);
            } else {
                actAttendanceMap.put(activityId, 1); // Create a new map entry for this activity and set its attendance count = 1.
            }
        
            memberActivityMap.put(memberId, actAttendanceMap);
        }

        //Loop through memberActivityMap and total confirmed participant in each activity.
        //this will populate the activityHeadCountMap
        for(Map<Id,Integer> actMap : memberActivityMap.values()) {
                        for(Id actId : actMap.keySet()) {
                //System.debug('~~~actId: ' + actId);
                //System.debug('~~~activityHeadCountMap: ' + this.activityHeadCountMap);
                Integer total = this.activityHeadCountMap.containsKey(actId) ? this.activityHeadCountMap.get(actId) : 0;
                total += actMap.get(actId);
                this.activityHeadCountMap.put(actId, total);
            } 
        }

        //Now loop through the activities and update the totals
        for(EngagementRosterPrintModel.EngagementActivity act : activityList ) {
            if(activityHeadCountMap.containsKey(act.id)) {
                act.headCount = activityHeadCountMap.get(act.id);
            }
        }


        // Loop through the Attendee results and build out the engModel
        List<EngagementRosterPrintModel.EngagementAttendee> attendeeList = new List<EngagementRosterPrintModel.EngagementAttendee>();
        Map<Id, EngagementRosterPrintModel.EngagementAttendee> attModelMap = new Map<Id, EngagementRosterPrintModel.EngagementAttendee>();
        Map<Id, List<Engagement_Attendee__c>> inMtgRoomMap = new Map<Id, List<Engagement_Attendee__c>>();
        Map<Id, List<Engagement_Attendee__c>> otherPeopleMap = new Map<Id, List<Engagement_Attendee__c>>();
        
        for(Engagement_Attendee__c att : engResult.Engagement_Attendees__r){

            if(att.Attendance_Status__c.equalsIgnoreCase('Removed') ||
                (att.Attendee_Type__c.equalsIgnoreCase('Guest') && 
                    (!att.Attendance_Status__c.equalsIgnoreCase('Confirmed') || !att.Associated_Attendee__r.Attendance_Status__c.equalsIgnoreCase('Confirmed')))) {
                continue;
            }
            
            EngagementRosterPrintModel.EngagementAttendee attendee = new EngagementRosterPrintModel.EngagementAttendee();
            
            if(att.Attendance_Status__c.equalsIgnoreCase('Duplicate')) {
                attendee.color2 = 'greyBG';
            }

            if(!att.Attendee_Type__c.equalsIgnoreCase('Guest')){
                attendee.name = att.Contact__c != null ? att.Contact__r.Name : att.Collateral_Name__c;
                attendee.attendeeId = att.Id;
                attendee.memberNumber = formatMemberNumber(att);//.Member_Number__c;
                attendee.attendeeStatus = convertStatustoSymbol(att.Attendance_Status__c);

                //if(att.Associated_Attendee__r.Attendance_Status__c.equalsIgnoreCase('Tentative')) {continue;}

                attendee.arrivalDate = att.Arrival__c != null ? att.Arrival__c.format('MMM d') : '';
                attendee.departureDate = att.Departure__c != null ? att.Departure__c.format('MMM d') : '';
                attendee.hotelConfirmationNumber = att.Hotel_Confirmation_Number__c;
                attendee.hotelConfirmed = att.Hotel_Confirmed__c ? 'X' : '';
                attendee.numRooms = att.Number_of_Rooms__c != null ? Integer.valueOf(att.Number_of_Rooms__c) : 0;
                
                if(!attendee.attendeeStatus.equals('A')) {
                    attendee.hotelConfirmed ='';
                    attendee.numRooms = null;
                } 
                this.eng.totalRooms = attendee.numRooms != null ? this.eng.totalRooms + attendee.numRooms : this.eng.totalRooms;

                if(att.Attendee_Type__c.equalsIgnoreCase('Candidate')) {
                    attendee.color = 'greenFont';
                }
                attModelMap.put(att.Id, attendee);
            }

            String hostAttendeeId = att.Associated_Attendee__c == null ? att.Id : att.Associated_Attendee__c;
            if(att.Attendance_Status__c.equalsIgnoreCase('Confirmed')) {
                if(att.In_Meeting_Room__c){
                    System.debug(att.Name + ' is in the meeting room.');
                    List<Engagement_Attendee__c> attList = new List<Engagement_Attendee__c>();
                    if(inMtgRoomMap.containsKey(hostAttendeeId)){
                        //System.debug('inMtgRoomMap has a key for hostAttendee ' + hostAttendeeId);
                        attList = inMtgRoomMap.get(hostAttendeeId); // we already have a list of in-meeting-room guests for this host attendee.
                    }
                    attList.add(att);
                    inMtgRoomMap.put(hostAttendeeId, attList);
                    eng.totalInMeetingRoom = eng.totalInMeetingRoom + 1;
                    System.debug('Total in Meeting Room: ' + eng.totalInMeetingRoom);
                    
                } else if(att.Associated_Attendee__c != null){
                    // I'm assuming that if the guest is not in a meeting room, they should be in the "Other People" list
                    List<Engagement_Attendee__c> otherPpl = new List<Engagement_Attendee__c>();
                    if( otherPeopleMap.containsKey(att.Associated_Attendee__c) ){
                        otherPpl = otherPeopleMap.get(att.Associated_Attendee__c);
                    }
                    otherPpl.add(att);
                    otherPeopleMap.put(hostAttendeeId, otherPpl);
                }
            }
            
                attendee.activities = new List<EngagementRosterPrintModel.ActivitySummary>();
                for(String activityId:activityMap.keySet()){
                    Engagement_Activity__c act = activityMap.get(activityId);
                    EngagementRosterPrintModel.ActivitySummary actSummary = new EngagementRosterPrintModel.ActivitySummary();
                    actSummary.activityName = act.Name;
                    if(memberActivityMap.containsKey(attendee.attendeeId)){
                        if(att.Attendance_Status__c.equalsIgnoreCase('Confirmed')) {
                            if(memberActivityMap.get(attendee.attendeeId).containsKey(activityId)){
                                actSummary.numParticipants = memberActivityMap.get(attendee.attendeeId).get(activityId);
                            } else {
                                actSummary.numParticipants = 0;
                            }
                        } 
                    }
                    //System.debug('actSummary: ' + actSummary.numParticipants + ' people are going to ' + actSummary.activityName + ' with member ' + attendee.attendeeId);
                    attendee.activities.add(actSummary);
                }
            
            
            //System.debug('Added ' + attendee.activities.size() + ' activitySummaries for attendee ' + attendee.name);
        }

        
        System.debug('attModelMap keys:');
        for(String memId:attModelMap.keySet()) System.debug('\tMemberId: ' + memId);

        //This is a test to see how this works. Making a list of the members that confirmed attending to iterate through in
        //for loop below. Instead of the guestMap keyset.
        List<Id> confirmedMembers = new List<Id>();
        for(Engagement_Attendee__c att : engResult.Engagement_Attendees__r){
            if(!att.Attendee_Type__c.equalsIgnoreCase('Guest') && att.Attendance_Status__c.equalsIgnoreCase('Confirmed')){
                confirmedMembers.add(att.Id);
                System.debug('~~~' + att.Name);
            }
        }


        // Loop through the guestMap and count the number of adults, teens, and children each member is bringing.
        for(Id memberId : /*guestMap.keySet()*/ confirmedMembers){
                
            Integer adultCount = 1;
            Integer teenCount = 0;
            Integer childCount = 0;
            

            if(guestMap.containsKey(memberId)) {
                for(Engagement_Attendee__c att : guestMap.get(memberId)){
                    if(att.Age_Group__c.equalsIgnoreCase('Adult')){
                        adultCount = adultCount + 1;
                        System.debug('adultCount for member [' + memberId + ']: ' + adultCount);
                        
                    } else if(att.Age_Group__c.equalsIgnoreCase('Teen')){
                        teenCount = teenCount + 1;
                        System.debug('teenCount for member [' + memberId + ']: ' + teenCount);
                        
                    } else if(att.Age_Group__c.equalsIgnoreCase('Child')){
                        childCount = childCount + 1;
                        System.debug('childCount for member [' + memberId + ']: ' + childCount);
                    }

                    if(!String.isBlank(att.Hotel_Confirmation_Number__c)) {
                        if(String.isBlank(attModelMap.get(memberId).hotelConfirmationNumber)) {
                            attModelMap.get(memberId).hotelConfirmationNumber = att.Hotel_Confirmation_Number__c;
                        } else {
                            attModelMap.get(memberId).hotelConfirmationNumber += ', ' + att.Hotel_Confirmation_Number__c;
                        }
                    } 

                    if(attModelMap.get(memberId).numRooms != null) {
                        if(att.Number_of_Rooms__c > 0) {
                            attModelMap.get(memberId).numRooms += Integer.valueOf(att.Number_of_Rooms__c);
                            this.eng.totalRooms += Integer.valueOf(att.Number_of_Rooms__c);
                        }
                    }
                }
            }

            if( memberId == null || !attModelMap.containsKey(memberId) ){
                continue;
            }



            attModelMap.get(memberId).numAdults = adultCount;
            attModelMap.get(memberId).numTeens = teenCount;
            attModelMap.get(memberId).numChildren = childCount;
            //System.debug('Member [' + memberId + '] is bringing ' + adultCount + ' adults, ' + teenCount + ' teens, ' + childCount + ' children.');

            eng.totalAdults = eng.totalAdults + adultCount;
            eng.totalTeens = eng.totalTeens + teenCount;
            eng.totalChildren = eng.totalChildren + childCount;

            System.debug('Adult Count: ' + eng.totalAdults);
            System.debug('Teen Count: ' + eng.totalTeens);
            System.debug('Child Count: ' + eng.totalChildren);
        }
        this.eng.attendees = attModelMap.values();
        this.eng.attendees.sort();

        // Update the "In Meeting Room" count for each host attendee (non-guests).
        for(String attId:inMtgRoomMap.keySet()){
            attModelMap.get(attId).numInMeetingRoom = inMtgRoomMap.get(attId).size();
            System.debug('Attendee [' + attId + '] will have ' + inMtgRoomMap.get(attId).size() + ' guests in the meeting room.');
            for(Engagement_Attendee__c mtgRmAtt : inMtgRoomMap.get(attId)){
                String tmpVal = attModelMap.get(attId).peopleInMeeting == null ? '' : attModelMap.get(attId).peopleInMeeting; // Get the current value of this property
                if(!String.isEmpty(tmpVal)) tmpVal = tmpVal + ', '; // if the property is not empty, add a comma to it so we separate the names like "Frank Jones, Martha Smith, Larry Edwards".
                tmpVal += mtgRmAtt.Collateral_Name__c + ' (' + mtgRmAtt.Attendee_Type__c + ')'; // Add the next person's name to the string.

                attModelMap.get(attId).peopleInMeeting = tmpVal; // Assign the new value of the string back to the property.
            }
        }


        // Update the "Other People" list for each attendee.
        for(String attId:otherPeopleMap.keySet()){
            for(Engagement_Attendee__c att:otherPeopleMap.get(attId)){
                String tmpVal = attModelMap.get(attId).otherPeople == null ? '' : attModelMap.get(attId).otherPeople;
                if(!String.isEmpty(tmpVal)) tmpVal += ', ';
                tmpVal += att.Collateral_Name__c + ' (' + att.Attendee_Type__c + ')';

                attModelMap.get(attId).otherPeople = tmpVal;
            }
        }



    }


    private String formatDate(Date theDate, String dateFormat){
        String result;
        if(theDate != null){
            DateTime dtResult = DateTime.newInstance(theDate.year(), theDate.month(), theDate.day(),0,0,0);
            result = dtResult.format(dateFormat);
        } else {
            result = '';
        }
        return result;
    }

    private String convertStatustoSymbol(String statusVal){
        
        switch on statusVal {
            when 'Not Attending' {	
                return '*';
            }	
            when 'Confirmed' {	
                return 'A';
            }
            when 'Tentative' {
                return '?';
            }
            when 'Duplicate' {
                return 'D';
            }
            when else {	
                return '';
            }
        }
    }


    private String formatMemberNumber(Engagement_Attendee__c att){
        if(att.Member_Number__c != null){
            return att.Member_Number__c;
        } else if (att.Attendee_Type__c != null) {
            if(att.Attendee_Type__c.equalsIgnoreCase('Speaker')){
                return 'SP';
            } else if (att.Attendee_Type__c.equalsIgnoreCase('Moderator')){
                return 'MD';
            } else {
                return 'VS';
            }
        }
        return '';
    }
    
}