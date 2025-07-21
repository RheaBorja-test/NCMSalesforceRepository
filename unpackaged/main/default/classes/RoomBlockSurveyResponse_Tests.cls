@isTest
public class RoomBlockSurveyResponse_Tests {

    @testSetup
    static void setupData(){
        
        SampleDataFactory.create20GroupAccountData();
        Twenty_Groups__c test20G = [select id from Twenty_Groups__c limit 1];
        String engRecTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('Retail Solutions').getRecordTypeId();
        String contactRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('NCM Associates').getRecordTypeId();
        Contact billingContact = [select id, name from Contact where RecordTypeId = :contactRecTypeId LIMIT 1];
        SampleDataFactory.createEngagement_20G(test20G.Id, engRecTypeId, billingContact.Id);
        
    }
    
    @isTest
    static void apiUpdatesResponseRecord(){
        
        Engagement__c eng = [select id from Engagement__c limit 1];
        Room_Block_Survey_Response__c testRec = new Room_Block_Survey_Response__c();
        testRec.Engagement__c = eng.Id;
        testRec.Survey_Id__c = '1234-abcd';
        testRec.SurveySentDate__c = Date.today();
        insert(testRec);
        
        Date arrival = Date.today().addDays(5);
        Date depart = Date.today().addDays(10);
        Integer numRooms = 5;
        String roomType = 'Deluxe Suite';
        RoomBlockModel.RoomBlockSubmitResponse respResult;
        RoomBlockModel.RoomBlockSelectionRequest req = new RoomBlockModel.RoomBlockSelectionRequest();
        req.surveyId = testRec.Survey_Id__c;
        List<RoomBlockModel.RoomSelection> roomSelections = new List<RoomBlockModel.RoomSelection>();
        
        // 1st rooming selection
        RoomBlockModel.RoomSelection roomSel1 = new RoomBlockModel.RoomSelection();
        roomSel1.plannedArrival = Date.today().addDays(30);
        roomSel1.plannedDeparture = Date.today().addDays(35);
        roomSel1.roomCount = 3;
        roomSel1.roomType = 'Deluxe Suite';
        roomSelections.add(roomSel1);
        
        // 2nd rooming selection
        RoomBlockModel.RoomSelection roomSel2 = new RoomBlockModel.RoomSelection();
        roomSel2.plannedArrival = Date.today().addDays(30);
        roomSel2.plannedDeparture = Date.today().addDays(35);
        roomSel2.roomCount = 5;
        roomSel2.roomType = 'Standard Room';
        roomSelections.add(roomSel2);

        req.rooms = roomSelections;


        Test.startTest();
        	respResult = RoomBlockSurveyResponse.submitSurveyResponse(req);
        Test.stopTest();
        
        
        // Did the response have a success result?
        Assert.areEqual('200', respResult.statusCode);
        
        Room_Block_Survey_Response__c testResult = [SELECT 
                                                        Id, 
                                                        Name, 
                                                        SurveyResponseDate__c,
                                                        (select Room_Type__c, Room_Count__c, Planned_Arrival__c, Planned_Departure__c FROM Room_Block_Selections__r)
                                                    FROM Room_Block_Survey_Response__c
                                                    WHERE Survey_Id__c = :testRec.Survey_Id__c];
        
        //Assert.areEqual(DateTime.now(), testResult.SurveyResponseDate__c);
        Assert.areEqual(roomSelections.size(), testResult.Room_Block_Selections__r.size());
    }
    
    
    @isTest
    static void invalidSurveyIdPassedReturns500Code(){
        
        Date arrival = Date.today().addDays(5);
        Date depart = Date.today().addDays(10);
        Integer numRooms = 5;
        String roomType = 'Deluxe Suite';
        RoomBlockModel.RoomBlockSubmitResponse respResult;
        RoomBlockModel.RoomBlockSelectionRequest req = new RoomBlockModel.RoomBlockSelectionRequest();
        req.surveyId = 'Invalid-survey-id';
        
        Test.startTest();
        	respResult = RoomBlockSurveyResponse.submitSurveyResponse(req);
        Test.stopTest();
        
        Assert.areEqual('500', respResult.statusCode);
        
    }
}