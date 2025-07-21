@RestResource(urlMapping='/RoomBlockOptions/*')
global class RoomBlockOptionsAPI {
    
    @HttpPost
    global static RoomBlockModel.RoomBlockOptionsResponse getRoomBlockOptions(String engagementId, String surveyId){

        RoomBlockModel.RoomBlockOptionsResponse resp = new RoomBlockModel.RoomBlockOptionsResponse();
        String memberContactId = '';

        // Engagement Query
        Engagement__c engResult = [SELECT 
                                    Id, 
                                    Name,
                                    X20_Group__c,
                                    X20_Group__r.Name,
                                    X20_Group__r.Group_Name__c,
                                    X20_Group__r.Moderator__r.Name,
                                    X20_Group__r.Moderator__r.Email,
                                    X20_Group__r.Meeting_Support_Contact__r.Name,
                                    X20_Group__r.Meeting_Support_Contact__r.Email,
                                    Proprietary_Group__c,
                                    Proprietary_Group__r.Name,
                                    Proprietary_Group__r.Group_Name__c,
                                    Proprietary_Group__r.Group_Owner__r.Name,
                                    Proprietary_Group__r.Group_Owner__r.Email,
                                    Proprietary_Group__r.Meeting_Support_Contact__r.Name,
                                    Proprietary_Group__r.Meeting_Support_Contact__r.Email,
                                    (SELECT Room_Type__c, Room_Rate__c FROM EngRoomBlocks__r),
                                    Engagement_Start_Date__c,
                                    Engagement_End_Date__c,
                                    Reception_Date__c,
                                    No_Reception__c, 
                                    Room_Block_Hotel__c,
                                    Room_Block_Deadline__c,
                                    City__c,
                                    State_pl__c, 
                                    Country_pl__c 
                                FROM Engagement__c 
                                WHERE Id = :engagementId];

        // Build the response
        if(engResult == null){
            resp.statusCode = '500';
            resp.message = 'No room options found for engagement id ' + engagementId;
        } else {
            resp.statusCode = '200';
            resp.message = engResult.EngRoomBlocks__r.size() + ' room options found for engagement id ' + engagementId;


            // Attempt to parse the surveyId
            if( !String.isBlank(surveyId) ){
                if(surveyId.contains('-')){
                    memberContactId = surveyId.split('-')[0].trim();
                    System.debug('Member contact Id: ' + memberContactId);
                }
            }

            String groupType = engResult.X20_Group__c != null ? '20G' : 'PropG';
            RoomBlockModel.MemberInfo memInfo;
            
            if(memberContactId != ''){
                memInfo = getMemberInfo(surveyId, groupType);
                resp.membershipInfo = memInfo;
            }

            // Group Info
            resp.groupNumber = engResult.X20_Group__c != null ? engResult.X20_Group__r.Name : engResult.Proprietary_Group__r.Name;
            resp.groupName = engResult.X20_Group__c != null ? engResult.X20_Group__r.Group_Name__c : engResult.Proprietary_Group__r.Group_Name__c;
            resp.meetingSpecialistEmail = engResult.X20_Group__c != null ? engResult.X20_Group__r.Meeting_Support_Contact__r.Email : engResult.Proprietary_Group__r.Meeting_Support_Contact__r.Email;
            resp.meetingSpecialistName = engResult.X20_Group__c != null ? engResult.X20_Group__r.Meeting_Support_Contact__r.Name : engResult.Proprietary_Group__r.Meeting_Support_Contact__r.Name;
            resp.moderatorEmail = engResult.X20_Group__c != null ? engResult.X20_Group__r.Moderator__r.Email : engResult.Proprietary_Group__r.Group_Owner__r.Email;
            resp.moderatorName = engResult.X20_Group__c != null ? engResult.X20_Group__r.Moderator__r.Name : engResult.Proprietary_Group__r.Group_Owner__r.Name;

            // Engagement info
            resp.meetingCity = engResult.City__c;
            resp.meetingState = engResult.State_pl__c;
            resp.meetingCountry = engResult.Country_pl__c;
            resp.meetingLocation = engResult.City__c;
            if(String.isNotBlank(engResult.State_pl__c)) {
                resp.meetingLocation += ', ' + engResult.State_pl__c;
            }
            if(String.isNotBlank(engResult.Country_pl__c)) {
                resp.meetingLocation +=  ', ' + engResult.Country_pl__c;
            }
            System.debug('~~~resp.meetingLocation: ' + resp.meetingLocation);
            resp.meetingStartDate = engResult.Engagement_Start_Date__c;
            resp.meetingEndDate = engResult.Engagement_End_Date__c;
            resp.receptionDateTime = engResult.Reception_Date__c;
            resp.hasReception = !engResult.No_Reception__c;
            
            // Room Block Hotel Info
            resp.hotelName = engResult.Room_Block_Hotel__c;
            resp.surveyDeadline = engResult.Room_Block_Deadline__c;

            List<RoomBlockModel.RoomOption> roomOpts = new List<RoomBlockModel.RoomOption>();
            for(Engagement_Room_Block__c rb : engResult.EngRoomBlocks__r){
                RoomBlockModel.RoomOption opt = new RoomBlockModel.RoomOption();
                opt.roomRate = rb.Room_Rate__c;
                opt.roomType = rb.Room_Type__c;
                roomOpts.add(opt);
            }
            resp.roomOptions = roomOpts;

        }

        return resp;
    }


    private static RoomBlockModel.MemberInfo getMemberInfo(String surveyId, String groupType){
        
        RoomBlockModel.MemberInfo memberResult = new RoomBlockModel.MemberInfo();


        // Attempt to parse the surveyId
        String memberContactId = '';
       // String engagemetnId = '';

        if( !String.isBlank(surveyId) ){
            if(surveyId.contains('-')){
                memberContactId = surveyId.split('-')[0].trim();
                //engagementId =    surveyId.split('-')[1].trim();
                System.debug('Member contact Id: ' + memberContactId);
            }
        }

        // Query for 20G or PropG member info.
        if(groupType == '20G'){
            List<X20_Group_Member_Contact__c> memContactResults = [select id, Contact__r.Name, Member_Email__c, X20_Groups_Member__r.Name from X20_Group_Member_Contact__c WHERE id = :memberContactId];
            if(memContactResults.isEmpty()){
                return null;
            } else {
                memberResult.memberName = memContactResults[0].Contact__r.Name;
                memberResult.memberNumber = memContactResults[0].X20_Groups_Member__r.Name;
            }
        } else {
            List<Proprietary_Account_Contact__c> propContactResults = [select id, Contact__r.Name, member_email__c, Proprietary_Account__r.Name from Proprietary_Account_Contact__c where id = :memberContactId];

            if( !propContactResults.isEmpty() ){
                memberResult.memberName = propContactResults[0].Contact__r.Name;
                memberResult.memberNumber = propContactResults[0].Proprietary_Account__r.Name;
            } else {
                return null;
            }
        }


        // Check for completed surveys.
        List<Room_Block_Survey_Response__c> rbsrResults = [select SurveyResponseDate__c from Room_Block_Survey_Response__c where Survey_Id__c = :surveyId and SurveyResponseDate__c != null];
        memberResult.surveySubmitDate = rbsrResults.isEmpty() ? null : rbsrResults[0].SurveyResponseDate__c;


        return memberResult;

    }
}