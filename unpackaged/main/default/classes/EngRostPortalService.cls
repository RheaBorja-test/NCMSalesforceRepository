@RestResource(urlMapping='/EngRostPortalAPI/*')
// We access this API from workbench with "/services/apexrest/EngRostPortalAPI/aBK7h000000Fz0MGAS" or /services/apexrest/EngRostPortalAPI/aBK7h000000Fz9nGAC
global class EngRostPortalService {

	@HttpGet
    global static EngagementRosterModel.EngagementRosterResponse getEngRostPortal() {
		EngagementRosterModel.EngagementRosterResponse Results=new EngagementRosterModel.EngagementRosterResponse();
		//Parse the group account number
    	RestRequest req = RestContext.request;
    	String engID = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        System.debug('Eng ID: ' + engID);
			engagement__c engagementResult = getEngagement(engID);
		
        	//Build the JSON payload to return.
			if(engagementResult == null){
				results.status = 'Error';
				results.statusCode = '500';
				results.message = 'No Engagement results found for engagement Id ' + engID;
			} else {
				results.status = 'Success';
				results.statusCode = '200';
				results.message = ' Engagement result found for engagement Id ' + engID;
				results.engagementid = engagementResult.id;
                
                // Engagement Info
				EngagementRosterModel.Engagement engInfo = new EngagementRosterModel.Engagement();
					engInfo.engagementId = engagementResult.id;
					engInfo.startDate = engagementResult.Engagement_Start_Date__c;
					engInfo.endDate = engagementResult.Engagement_End_Date__c;
					engInfo.confirmedHotel = engagementResult.Confirmed_Hotel__r.Name;
					engInfo.roomsFrom = engagementResult.Rooms_From__c;
                	engInfo.roomsTo = engagementResult.Rooms_To__c;
                    engInfo.roomBlockCutoff = engagementResult.Room_Block_Cut_off__c;
                	engInfo.meetingCycle = engagementResult.Meeting_Cycle__c;
                	engInfo.groupName = engagementResult.X20_Group__c != null ? engagementResult.X20_Group__r.Group_Name__c : engagementResult.Proprietary_Group__r.Group_Name__c;
					engInfo.groupNumber = engagementResult.X20_Group__c != null ? engagementResult.X20_Group__r.Name : engagementResult.Proprietary_Group__r.Group_Number__c;
                	engInfo.meetingSupportContactName = engagementResult.X20_Group__c != null ? engagementResult.X20_Group__r.Meeting_Support_Contact__r.Name : engagementResult.Proprietary_Group__r.Meeting_Support_Contact__r.Name;
					engInfo.meetingSupportContactEmail = engagementResult.X20_Group__c != null ? engagementResult.X20_Group__r.Meeting_Support_Contact__r.Email : engagementResult.Proprietary_Group__r.Meeting_Support_Contact__r.Email;
					
                // Engagement Activities Info
                enginfo.activities = new List<EngagementRosterModel.EngagementActivity>();
                for(Engagement_Activity__c act : engagementResult.Activities__r){
                	EngagementRosterModel.EngagementActivity actInfo = new engagementRosterModel.EngagementActivity();
                	actInfo.id = act.Id;
					actInfo.name = act.Name;
                    actInfo.headCount = act.Total_Number_of_All_Participants__c;
                    actInfo.startDate = act.Start__c;
                    enginfo.activities.add(actinfo);
                }

				// Activity Participation Info
				Map<Id, List<EngagementRosterModel.AttendeeActivitySummary>> attendeeActivityMap = getAttendeeActivities(engagementResult.Id);

                
                // Attendee Info	
                enginfo.attendees = new List<EngagementRosterModel.EngagementAttendee>();
                for(Engagement_Attendee__c att : engagementResult.Engagement_Attendees__r){
                	EngagementRosterModel.EngagementAttendee attInfo = new engagementRosterModel.EngagementAttendee();
                   	//(SELECT Id, Name, X20_Groups_Member__r.Group_Member_Number__c, X20_Groups_Member__r.Type__c, Contact__r.Name, Attendee_Type__c, Attendance_Status__c, Arrival__c, Departure__c
                    attInfo.name = att.Name;
                    attInfo.memberNumber = att.X20_Groups_Member__r.Member_Number__c;
                    attInfo.attendeeId = att.Id;
                    attInfo.attendeeType = att.Attendee_Type__c;
                    attInfo.attendeeStatus = att.Attendance_Status__c;
                    attInfo.groupMemberType = att.X20_Groups_Member__r.Type__c;
                    attInfo.arrivalDate = att.Arrival__c;
                    attInfo.departureDate = att.Departure__c;
                    attInfo.collateralName = att.Collateral_Name__c;
                    attInfo.duplicateMember = att.Duplicate__c;
                    attInfo.ageGroup = att.Age_Group__c;
                    attInfo.inMeetingRoom = att.In_Meeting_Room__c;
                  	attInfo.hotelConfirmed = att.Hotel_Confirmed__c;
                    attInfo.hotelConfirmationNumber = att.Hotel_Confirmation_Number__c;
					attInfo.associatedAttendee = att.Associated_Attendee__c;                    
					attInfo.activities = attendeeActivityMap.get(att.Id);
                    enginfo.attendees.add(attinfo);
                } 
                
				Results.engagement = engInfo;

			}


		return Results;

	}



    public static engagement__c getEngagement(string engId){
        List<Engagement__c> engagementResults = [SELECT Id, Name, Rooms_From__c, Rooms_To__c, Room_Block_Cut_off__c, Meeting_Cycle__c, X20_Group__r.Name, X20_Group__r.Group_Name__c, X20_Group__r.Meeting_Support_Contact__r.Name, X20_Group__r.Meeting_Support_Contact__r.Email, Proprietary_Group__c, Proprietary_Group__r.Name, Proprietary_Group__r.Group_Name__c, Proprietary_Group__r.Group_Number__c, Proprietary_Group__r.Meeting_Support_Contact__r.Name, Proprietary_Group__r.Meeting_Support_Contact__r.Email, Engagement_Start_Date__c, Engagement_End_Date__c, Confirmed_Hotel__r.Name, Confirmed_Hotel__r.ShippingStreet, Confirmed_Hotel__r.ShippingCity, Confirmed_Hotel__r.ShippingState, Confirmed_Hotel__r.ShippingPostalCode, Confirmed_Hotel__r.ShippingCountry, Status__c, Street_Address__c, City__c, State__c, Country__c, Total_Registrations__c, 
											(SELECT Id, Name, Member_Number__c, X20_Groups_Member__r.Group_Member_Number__c, X20_Groups_Member__r.Type__c, X20_Groups_Member__r.Member_Number__c, Hotel_Confirmed__c, Hotel_Confirmation_Number__c, Number_of_Rooms__c, Contact__r.Name, Age_Group__c, In_Meeting_Room__c, Duplicate__c, Collateral_Name__c, Associated_Attendee__c, Associated_Attendee__r.Attendance_Status__c, Attendee_Type__c, Attendance_Status__c, Arrival__c, Departure__c FROM Engagement_Attendees__r WHERE Attendance_Status__c NOT IN ('Removed','Cancelled') ),
                                          		(SELECT Id, Name, Start__c, Total_Number_of_All_Participants__c FROM Activities__r ORDER BY Start__c ASC)
                                            FROM Engagement__c 
                                            WHERE Id = :engID];
        if(engagementResults.isEmpty()){
			return null;
		} else {
			return engagementResults[0];
		}
    }
    


	private static Map<Id, List<EngagementRosterModel.AttendeeActivitySummary>> getAttendeeActivities(String engagementID){
		Map<Id, List<EngagementRosterModel.AttendeeActivitySummary>> resultMap = new Map<Id, List<EngagementRosterModel.AttendeeActivitySummary>>();

		for(Activity_Participation__c ap : [SELECT Id, Engagement_Activity__c, Engagement_Activity__r.Name, Engagement_Attendee__c, Engagement_Attendee__r.Associated_Attendee__c FROM Activity_Participation__c WHERE Engagement_Attendee__r.Engagement__c = :engagementID AND Engagement_Attendee__r.Attendance_Status__c IN ('Confirmed','Tentative')]){
			//Map<String, Integer> activityMap = new Map<String, Integer>();
			String activityName = ap.Engagement_Activity__r.Name;
			Integer activityHeadCount = 0;
			List<EngagementRosterModel.AttendeeActivitySummary> activityList = new List<EngagementRosterModel.AttendeeActivitySummary>();

			String attendeeId = ap.Engagement_Attendee__c;

			// Check if we already have a map for this attendee that we need to update.
			if(resultMap.containsKey(attendeeId)){
				activityList = resultMap.get(attendeeId);
			}

			EngagementRosterModel.AttendeeActivitySummary actSum = new EngagementRosterModel.AttendeeActivitySummary();
			actSum.id = ap.Engagement_Activity__c;
			actSum.name = ap.Engagement_Activity__r.Name;
			actSum.count = 1;
			activityList.add(actSum);

			resultMap.put(attendeeId, activityList);
		}
		
		return resultMap;
	}

}