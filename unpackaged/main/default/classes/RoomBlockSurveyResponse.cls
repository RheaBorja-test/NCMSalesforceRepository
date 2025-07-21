@RestResource(urlMapping='/RoomBlockSurveyResponse/*')
global class RoomBlockSurveyResponse {


    @HttpPost
    global static RoomBlockModel.RoomBlockSubmitResponse submitSurveyResponse(RoomBlockModel.RoomBlockSelectionRequest req){
        
        RoomBlockModel.RoomBlockSubmitResponse resp = new RoomBlockModel.RoomBlockSubmitResponse();
        String surveyId = String.escapeSingleQuotes(req.surveyId);
        
        // Find the survey id for this response.
        List<Room_Block_Survey_Response__c> rbRespResults = [select id from Room_Block_Survey_Response__c where Survey_Id__c = :surveyId];
        if(rbRespResults.isEmpty()){
            resp.statusCode = '500';
            resp.message = 'No survey found matching ' + surveyId;
            
        } else {
            
            
            Room_Block_Survey_Response__c r = rbRespResults[0];
            resetExistingRoomBlockSelections(r.Id); // Clear out any existing room selections (in case they have submitted their selections previously)
            r.SurveyResponseDate__c = DateTime.now();
            
            try{
                update(r);

                // Create Room Selection records
                List<Room_Block_Selection__c> roomSelections = new List<Room_Block_Selection__c>();
                for(RoomBlockModel.RoomSelection roomSel : req.rooms){
                    if(roomSel.roomCount == null || roomSel.roomCount < 1){
                        resp.statusCode = '500';
                        resp.message = 'Room selection invalid: must have a Room Count value that is a number greater than 0.';
                        return resp;
                    }
                    if(String.isBlank(roomSel.roomType)){
                        resp.statusCode = '500';
                        resp.message = 'Room selection invalid: a RoomType must be specified.';
                        return resp;
                    }

                    Room_Block_Selection__c rbSel = new Room_Block_Selection__c();
                    rbSel.Room_Block_Survey_Response__c = r.Id;
                    rbSel.Room_Count__c = roomSel.roomCount;
                    rbSel.Room_Type__c = roomSel.roomType;
                    rbSel.Planned_Arrival__c = roomSel.plannedArrival;
                    rbSel.Planned_Departure__c = roomSel.plannedDeparture;
                    
                    roomSelections.add(rbSel);
                }
                insert(roomSelections);
                System.debug('Inserted ' + roomSelections.size() + ' new room selections for ' + r.Id);

                resp.statusCode = '200';
                resp.message = 'Room selections saved';

            } catch (DmlException e){
                
                System.debug('Error saving room selections: ' + e.getMessage());
                Logger.logError('RoomBlockSurveyResponse', 'Error', UserInfo.getUserName(), 'Error saving rooming selections', e.getMessage(), e.getStackTraceString());
                
                resp.statusCode = '500';
                resp.message = 'Error updating rooming preferences: ' + e.getMessage();
                
            }
        }
    
        return resp;
    }


    private static void resetExistingRoomBlockSelections(String rbsId){
        List<Room_Block_Selection__c> existingRBS = [select id from Room_Block_Selection__c where Room_Block_Survey_Response__c = :rbsId];
        if(!existingRBS.isEmpty()){
            try{
                delete(existingRBS);
            } catch(DmlException dex){
                System.debug('Error deleting existing room block selections: ' + dex.getMessage());
                Logger.logError('RoomBlockSurveyResponse', 'Error', UserInfo.getUserName(), 'API error', dex.getMessage(), dex.getStackTraceString());
            }
        }
    }
    
}