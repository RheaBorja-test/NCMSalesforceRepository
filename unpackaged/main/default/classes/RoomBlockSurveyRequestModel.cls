// Derrick Chavez; Created 2.26.2024
// This class defines the data structure we'll be sending to the Workato API. 
public class RoomBlockSurveyRequestModel {

    public String engagementId {get;set;}  
    public String proprietaryGroup {get; set;}          // Proprietary_Group__c(lookup Prooprietary Grup)
    public String x_20engagementGroup {get;set;}       // X20_Group__c(lookup to 20 Groups) 
    public String meetingLocation {get;set;}  
    public String meetingLocationCity {get;set;}     // Confirmed_Hotel__c; Lookup(Account)
    public String meetingLocationState {get;set;}    // Confirmed_Hotel__c; Lookup(Account)
    public String memberGroupNumber {get;set;}       // Group_Number__c;  (formula text)   
    public Date   meetingStartDate {get;set;}        // Engagement_Start_Date__c; (date field needs to be parsed into Month and Year)
    public Date   memberResponseDeadline {get;set;}  // Engagement RoomBlockDeadline
    public List<GroupContactModel> contacts {get;set;} // Since there can be more than one contact under an account, 
                                                       // we use a list and an inner class to represent contacts.
    

    // Here's an inner-class to represent each contact under the account.  (X20_Group_Member_Contact__c)
    public class GroupContactModel {

        public String surveyId {get;set;}         // SurveyID (memberContactId + engagementId)
        public String membershipId {get;set;}     // 20 Group Member Acccount Id
        public String memberContactId {get;set;}  // 20 Group  Memmber Contact__c
        public String memberContactFirstName {get;set;}  
        public String memberContactEmail {get;set;}  
        public String memberContactName {get;set;}
        public String memberGroupType {get;set;} // To store "20 Group" or "Proprietary Group".
        
    }
}