global class RoomBlockModel {
    
    global class RoomBlockOptionsResponse{

        global String statusCode {get;set;} // 200=success, 500=error
        global String message {get;set;} // Any confirmation or error messages
        global String meetingCity {get;set;}
        global String meetingState {get;set;}
        global String meetingCountry {get;set;}
        global String meetingLocation {get;set;}
        global Date meetingStartDate {get;set;}
        global Date meetingEndDate {get;set;}
        global DateTime receptionDateTime {get;set;}
        global Boolean hasReception {get;set;}
        global String groupNumber {get;set;}
        global String groupName  {get;set;}
        global String moderatorName {get;set;}
        global String moderatorEmail {get;set;}
        global String meetingSpecialistName {get;set;}
        global String meetingSpecialistEmail {get;set;}
        global String hotelName {get;set;}
        global Date surveyDeadline {get;set;}
        global List<RoomOption> roomOptions {get;set;}
        global MemberInfo membershipInfo {get;set;}

    }

    global class RoomOption{
        global String roomType {get;set;}
        global Decimal roomRate {get;set;}
    }

    global class MemberInfo{
        global String memberNumber {get;set;} // The group member id
        global String memberName {get;set;} // The group contact name "Martin Smith"
        global DateTime surveySubmitDate {get;set;}
    }
    


    global class RoomBlockSelectionRequest{
        global String surveyId {get;set;}
        global List<RoomSelection> rooms {get;set;}
    }

    global class RoomSelection{
        global String roomType {get;set;}
        global Integer roomCount {get;set;}
        global Date plannedArrival {get;set;}
        global Date plannedDeparture {get;set;}
    }


    global class RoomBlockSubmitResponse{
        global String statusCode {get;set;} // 200=success, 500=error
        global String message {get;set;} // Any confirmation or error messages
    }

}