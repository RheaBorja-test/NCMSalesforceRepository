/* This class handles the functionality behind the Email Room Block Survey button/flow. It gathers the contacts that are related to the 
 * Engagement and processes the ones that meet the criteria to be sent a survey. Contacts that have not responded to the survey have the 
 * ability to be resent a survey without duplicating Room_Block_Survey_Response__c records. If they have reponded they will not be resent a survey. 
 * The info is sent to the Workato API.
*/
public class RoomBlockSurveyRequest {

    // Invocable Method that gets Engagement and Room Block Information.Sends a JSON request to Workato. 
    @InvocableMethod( label       = 'Send Room Block Survey' 
                      description = 'Converts Room Block Survey Info into JSON to send to API'
                      category    = 'Engagement')
    public static List<String> sendRoomBlockSurvey(List<String> engageIdList) {

        String engageId = engageIdList[0]; // Pass in the first Engagement Id passed in. 
        final String GROUP_TYPE_PROPRIETARY = 'Proprietary Group';
        final String GROUP_TYPE_20G = '20 Group';
        
        System.debug('EngagementModel: sendRoomBlockSurvey: EngagementId ' + engageId);
      
        // Step 1; Query the data we'll need to populate our model. Make sure to get the 20 Group and Prop Group fields. 
        List<Engagement__c> engagementList = [SELECT Id, Name, Confirmed_Hotel__r.Name, Room_Block_Hotel__c, Room_Block_Deadline__c, 
                                                     Room_Block_Count__c, Engagement_Start_Date__c, Group_Number__c,
                                                     Confirmed_Hotel__r.ShippingCity, City__c, State_pl__c, 
                                                     Confirmed_Hotel__r.ShippingStateCode, X20_Group__c, Proprietary_Group__c,
                                                     (SELECT ID, Name, Contact__c, Attendance_Status__c FROM Engagement_Attendees__r)  
                                              FROM  Engagement__c 
                                              WHERE Id = :engageId];
        
        // Query all existing Response records that have not responded. 
        List<Room_Block_Survey_Response__c> responseList = [SELECT Id, Survey_Id__c, X20_Group_Member_Contact__c, Engagement__c, Proprietary_Account_Contact__c, SurveySentDate__c, SurveyResponseDate__c
                                                            FROM Room_Block_Survey_Response__c 
                                                            WHERE Engagement__c = :engageId];
        System.debug('RoomBlockSurveyRequest responseList: ' + responseList);
                     
        // 1381 - Get any Room Block Survey Request records that currently exist and create
        // a map of ContactID => RBS so we know who's already been sent an email.
        Map<Id, Room_Block_Survey_Response__c> contactRBSMap = new Map<Id,Room_Block_Survey_Response__c>();
                
        for(Room_Block_Survey_Response__c rbs :responseList) {
            if(rbs.X20_Group_Member_Contact__c != null) {
	        	contactRBSMap.put(rbs.X20_Group_Member_Contact__c, rbs);
            } else if (rbs.Proprietary_Account_Contact__c != null) {
            	contactRBSmap.put(rbs.Proprietary_Account_Contact__c, rbs);
            } else {
                System.debug('RBS does not have a 20 Group Contact OR a Prop Account Contact: ' + rbs.Survey_Id__c);
            }
        }
        System.debug('contactRBSMap has ' + contactRBSMap.size() + ' elements.');                

        if(engagementList.isEmpty()) {
            System.debug('No results found for Engagement Id: ' + engageId);
            return engageIdList;
        } 

        // Step 2: Loop through the query results and populate the model. Initialize a new list of GroupContactModel objects.   
        RoomBlockSurveyRequestModel rbsModel = new RoomBlockSurveyRequestModel();
        Engagement__c engage = engagementList[0]; 
        rbsModel.engagementId = engageId;  
        //String x20Group = engage.X20_Group__c;
        rbsModel.x_20engagementGroup = engage.X20_Group__c;
        rbsModel.proprietaryGroup = engage.Proprietary_Group__c; 
        rbsModel.meetingLocation = engage.Confirmed_Hotel__r.Name;          // meeting location confirmed hotel    
        rbsModel.meetingLocationCity = engage.Confirmed_Hotel__r.ShippingCity == null ? engage.City__c : engage.Confirmed_Hotel__r.ShippingCity;
        rbsModel.meetingLocationState = engage.Confirmed_Hotel__r.ShippingStateCode == null ? engage.State_pl__c : engage.Confirmed_Hotel__r.ShippingStateCode;
        rbsModel.memberGroupNumber = engage.Group_Number__c;                // Group_Number__c;  (formula field)   
        rbsModel.meetingStartDate = engage.Engagement_Start_Date__c;        // Engagement_Start_Date__c; (date field needs to be parsed into Month and Year, MAYBE!!!!)
        rbsModel.memberResponseDeadline = engage.Room_Block_Deadline__c;    // Engagement or Room Block?
        
        // Track any current Engagement Attendees for this engagement.
        Map<String, Engagement_Attendee__c> currentAttendeeMap = new Map<String,Engagement_Attendee__c>();
        for(Engagement_Attendee__c att:engage.Engagement_Attendees__r){
            currentAttendeeMap.put(att.Contact__c, att);
        }
        System.debug('currentAttendeeMap contains ' + currentAttendeeMap.size() + ' elements.');
        
        // Initialize the lists we will need. 
        List<RoomBlockSurveyRequestModel.GroupContactModel> groupConModelList = new List<RoomBlockSurveyRequestModel.GroupContactModel>();
        List<X20_Group_Member_Contact__c> x20GroupMemberContactList  = new List<X20_Group_Member_Contact__c>();
        List<Proprietary_Account_Contact__c> propGroupContactModelList = new List<Proprietary_Account_Contact__c>();

        if(String.isNotBlank(rbsModel.x_20engagementGroup)) {  
            
            // Query the 20 Group Member Contact
            x20GroupMemberContactList  = [ SELECT Id, Contact__r.FirstName, Contact__r.Name, Member_Email__c, Additional_Dist_List_Email_Addresses__c, X20_Groups_Member__c, Contact_Status__c, X20_Group__c 
                                           FROM  X20_Group_Member_Contact__c
                                           WHERE X20_Group__c = :rbsModel.x_20engagementGroup 
                                            AND X20_Groups_Member__r.Type__c = 'Full Member'
                                            AND X20_Groups_Member__r.Status__c = 'Active'
                                            AND Contact_Status__c = 'Active' 
                                            AND Contact_Type__c  = 'Member' 
                                            AND Member_Email__c != null
                                        ];
            //Loop through the query results and populate the model for 20 Group
            for(X20_Group_Member_Contact__c x20Contact : x20GroupMemberContactList){

                // 1382: Check if this contact has already received and responded to a survey invite email.
                if(contactRBSMap.containsKey(x20Contact.Id) && contactRBSMap.get(x20Contact.Id).SurveyResponseDate__c != null){
                    System.debug('Contact has already been sent a survey email: ' + x20Contact.Id + '. Skipping.');
                    continue; // Skip to the next contact.
                }
                if(currentAttendeeMap.containsKey(x20Contact.Contact__c)){
                    if(currentAttendeeMap.get(x20Contact.Contact__c).Attendance_Status__c == 'Not Attending'){
                        System.debug('Contact ' + x20Contact.Id + ' is marked as not attending this engagement. Skipping.');
                        continue;
                    }
                }
                System.debug('Processing 20 Group Member Contact: ' + x20Contact.Contact__r.Name);

                RoomBlockSurveyRequestModel.GroupContactModel groupConModel = new RoomBlockSurveyRequestModel.GroupContactModel();
                groupConModel.memberContactFirstName = x20Contact.Contact__r.FirstName;
                groupConModel.membershipId = x20Contact.X20_Groups_Member__c; 
                groupConModel.surveyId = x20Contact.Id + '-' + engageId; // (MemberContactId + engagementId) 
                groupConModel.memberContactEmail = x20Contact.Member_Email__c;
                // If the Group member contact record specifies additional email addresses (like an administrative assistant), add them to the memberContactEmail field separated with a semicolon.
                if(x20Contact.Additional_Dist_List_Email_Addresses__c != null){
                    String emailList = x20Contact.Additional_Dist_List_Email_Addresses__c;//.replace(',',';');
                    //emailList = x20Contact.Additional_Dist_List_Email_Addresses__c.replace(' ',';');
                    groupConModel.memberContactEmail += ',' + emailList;
                }
                groupConModel.memberContactId = x20Contact.Id;
                groupConModel.memberContactName = x20Contact.Contact__r.Name;
                groupConModel.memberGroupType = GROUP_TYPE_20G;
                groupConModelList.add(groupConModel);
                
            }
            rbsModel.contacts = groupConModelList;   
            System.debug('RoomBlockSurveyRequest: rbsModel.contacts: ' + rbsModel.contacts); 
                 
        } else if(String.isNotBlank(engage.Proprietary_Group__c)) {		
            
            // Query the Prop Group Member Contact 
            propGroupContactModelList = [SELECT Id, Contact__c, Contact__r.FirstName, Contact__r.Name, Status__c, Proprietary_Account__c, Proprietary_Group__c, Member_Email__c, Additional_Dist_List_Email_Addresses__c 
                                         FROM  Proprietary_Account_Contact__c
                                         WHERE Proprietary_Group__c = :engage.Proprietary_Group__c 
                                            AND Proprietary_Account__r.Type__c = 'Full Member'
                                            AND Proprietary_Account__r.Status__c = 'Active'
                                            AND Status__c = 'Active' 
                                            AND Contact_Type__c = 'Member' 
                                            AND Member_Email__c != null
                                        ];

            //Loop through the query results and populate the model for PropGroup
            for(Proprietary_Account_Contact__c propContact : propGroupContactModelList){
                // 1382: Check if this contact has already received and responded to a survey invite email.
                if(contactRBSMap.containsKey(propContact.Id) && contactRBSMap.get(propContact.Id).SurveyResponseDate__c != null){
                    System.debug('Contact has already been sent a survey email: ' + propContact.Id + '. Skipping.');
                    continue; // Skip to the next contact.
                }                
                if(currentAttendeeMap.containsKey(propContact.Contact__c)){
                    if(currentAttendeeMap.get(propContact.Contact__c).Attendance_Status__c == 'Not Attending'){
                        System.debug('Contact ' + propContact.Id + ' is marked as not attending this engagement. Skipping.');
                        continue;
                    }
                }

                RoomBlockSurveyRequestModel.GroupContactModel groupConModel = new RoomBlockSurveyRequestModel.GroupContactModel();                
                groupConModel.memberContactFirstName = propContact.Contact__r.FirstName;
                groupConModel.memberContactEmail = propContact.Member_Email__c;
                // If the Group member contact record specifies additional email addresses (like an administrative assistant), add them to the memberContactEmail field separated with a semicolon.
                if(propContact.Additional_Dist_List_Email_Addresses__c != null){
                    String emailList = propContact.Additional_Dist_List_Email_Addresses__c;//.replace(',',';');
                    //emailList = propContact.Additional_Dist_List_Email_Addresses__c.replace(' ',';');
                    groupConModel.memberContactEmail += ',' + emailList;
                }
                groupConModel.membershipId = propContact.Proprietary_Account__c; 
                groupConModel.memberContactId = propContact.Id;
                groupConModel.surveyId = propContact.Id + '-' + engageId; // (MemberContactId + engagementId)     
                groupConModel.memberContactName = propContact.Contact__r.Name;
                groupConModel.memberGroupType = GROUP_TYPE_PROPRIETARY;
                groupConModelList.add(groupConModel);                
            
            }
            rbsModel.contacts = groupConModelList; // RoomBlockSurveyRequestModel class  
            System.debug('RoomBlockSurveyRequest: rbsModel.contacts: ' + rbsModel.contacts);  
        }         
        
        // create a new list of room block response that we can populate.
        List<Room_Block_Survey_Response__c> rbsResponseList = new List<Room_Block_Survey_Response__c>();
                
        // SALES-1748 - Added logic to have the ability to resend surveys without duplicating Room_Block_Survey_Response__c records. 
        // loop rbsModel.contacts
        for(RoomBlockSurveyRequestModel.GroupContactModel ct :rbsModel.contacts) {
            if(contactRBSMap.containsKey(ct.memberContactId)) {
                // Get the existing response and decide if they need a resend or not.
                Room_Block_Survey_Response__c  existingResponse = contactRBSMap.get(ct.memberContactId);            
                if(existingResponse.SurveyResponseDate__c == null) {
                    // No survey received, prepare to resend.
                    System.debug('RoomBlockSurveyRequest Existing Response, send survey and update existing response record.');
                    existingResponse.SurveySentDate__c = DateTime.now(); 
                    rbsResponseList.add(existingResponse);
                } else {
                    System.debug('RoomBlockSurveyRequest Existing Response, but no resend is nescessary.');
                }
            } else {
                System.debug('RoomBlockSurveyRequest New Response, send survey and create a new response record.');
                // Create an RBS response record for each Contact to track who was sent a survey email and when. 
                Room_Block_Survey_Response__c rbsResponse = new Room_Block_Survey_Response__c();
                rbsResponse.Engagement__c = engage.Id;
                rbsResponse.Name = ct.memberContactName;//engage.Name;
                rbsResponse.Survey_Id__c = ct.memberContactId + '-' + engage.Id;  // (MemberContactId + engagementId) 
                rbsResponse.SurveySentDate__c = DateTime.now(); 
                rbsResponse.Email_Addresses_Sent__c = ct.memberContactEmail;
    
                if(ct.memberGroupType == GROUP_TYPE_20G) {
                    rbsResponse.X20_Group_Member_Contact__c = ct.memberContactId;
                } else if (ct.memberGroupType == GROUP_TYPE_PROPRIETARY) {
                    rbsResponse.Proprietary_Account_Contact__c = ct.memberContactId;
                } else {
                    System.debug('Group type undefined: ' + ct.memberGroupType);
                }            
                rbsResponseList.add(rbsResponse);                
            }  
        }      
        upsert(rbsResponseList);
       
        //Step 3: Convert our model to JSON so we can send it to the API. 
        String surveyData = JSON.serializePretty(rbsModel);
        System.debug('RoomBlockSurveyRequest: resultJson: ' + surveyData);

        // STEP 4: Call the API and pass our data.
        sendSurveyToWorkato(surveyData);
        
        // STEP 5: Return a list with the same number of results as what was passed in.
        return engageIdList;
    } 
    
    @future(callout=true)
    private static void sendSurveyToWorkato(String surveyData){
        WorkatoAPI api = new WorkatoAPI();
        api.sendSurveyData(surveyData);
    }
     
}