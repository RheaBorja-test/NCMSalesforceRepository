global class CustomerSubscriptionModel {

    global class CustomerEntitlementsResponse{
        global String status {get;set;}
        global String message {get;set;}
        global List<AccountInfo> accounts {get;set;}
    }

    global class AccountInfo{
        global String accountId {get;set;}
        global String name {get;set;}
        global Boolean axcessaClient {get;set;}
        global Boolean ncmiClient {get;set;}
        global List<GroupMembership> groups {get;set;}
    }

    global class GroupMembership{
        global String groupType {get;set;}
        global String groupNumber {get;set;}
        global String memberNumber {get;set;}
        global String zipCodePrefix {get;set;}
    }
}