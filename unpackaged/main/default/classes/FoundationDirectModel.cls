global class FoundationDirectModel {
    global class FoundationDirectResponse {
        global String status {get;set;}
        global String message {get;set;}
    }
    global class UpdateAccountRequest{
        global String accountId {get;set;}
        global String fdId {get;set;}
    }
}