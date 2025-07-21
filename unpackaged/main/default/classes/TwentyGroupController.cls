// Derrick Chavez: 6.11.2025; SALES-1195,2096
// If a Moderator (Group Owner) is updated on a TwentyGroup, then the system will automatically change 
// the previous Group Owner, and add the new Group Owner to all future Engagements with a status of 'Tentative’, 'Firm’, or 'Cancellation Inquiry’.
// Instead of replacing the old Attendee, it will set the Attendance Status to 'Cancelled'. 
public class TwentyGroupController {
    
    public static void handleGroupOwnerChange(List<Twenty_Groups__c> newList, Map<Id,Twenty_Groups__c> oldMap) {

        // Create two maps to track the previous Group Owner Contact ID and the new Group Owner Conact ID. 
        Map<Id, Id> oldGroupOwnerMap = new Map<Id,Id>();
        Map<Id, Id> newGroupOwnerMap = new Map<Id,Id>();
        
        // Identify changes to the Group Owner (NCM_Proprietary__c).
        for(Twenty_Groups__c twentyGroup : newList) {
            Id oldGroupOwnerId = oldMap.get(twentyGroup.Id).NCM_Proprietor__c;
            Id newGroupOwnerId = twentyGroup.NCM_Proprietor__c;
            
            // If Group Owner is changed, then add both values to the maps. 
            if(oldGroupOwnerId != newGroupOwnerId) {
                if(oldGroupOwnerId != null) {
                    oldGroupOwnerMap.put(twentyGroup.Id, oldGroupOwnerId); // track which Attendee (Group Owner) to set to 'Cancelled'. 
                }
                if(newGroupOwnerId != null) {
                    newGroupOwnerMap.put(twentyGroup.Id, newGroupOwnerId); // track which Attendee (Group Owner), needs to be created. 
                }
            }            
        }

        // Add all the Keys (Twenty Group Ids) to a Set, then pass into each method to get the Engagements.
        Set<Id> groupIds = new Set<Id>();
        groupIds.addAll(oldGroupOwnerMap.keySet());
        groupIds.addAll(newGroupOwnerMap.keySet());
        System.debug('handleGroupOwnerChange:: groupIds: ' + groupIds);

        if(groupIds.isEmpty()) return;
        
        // Get the future Engagements and cancel Engagement Attendees. 
        List<Engagement__c> engagementsToUpdate = getFutureEngagements(groupIds);
        System.debug('handleGroupOwnerChange :: engagementsToUpdate: ' + engagementsToUpdate);
        if(!oldGroupOwnerMap.isEmpty()) {
            cancelModeratorAttendees(engagementsToUpdate, oldGroupOwnerMap);
        }
        // Get the the relavant future Engagements and add Engagement Attendees. 
        List<Engagement__c> engagementsToAdd = getRelavantFutureEngagements(groupIds);
        if(!newGroupOwnerMap.isEmpty()) {
            addModeratorAttendees(engagementsToAdd, newGroupOwnerMap);
        }      
    }

    private static List<Engagement__c> getFutureEngagements(Set<Id> groupIds) {

        List<Engagement__c> engagements = [
            SELECT Id, Name, X20_Group__c, Engagement_Start_Date__c, Engagement_Start__c, Status__c
            FROM Engagement__c
            WHERE X20_Group__c IN :groupIds AND Engagement_Start_Date__c > TODAY
        ];
        
        System.debug('TwentyGroupController.getFutureEngagements: engagements ' + engagements);
        return engagements;
    }

    private static List<Engagement__c> getRelavantFutureEngagements(Set<Id> groupIds) {

        List<Engagement__c> engagements = [
            SELECT Id, Name, X20_Group__c, Engagement_Start_Date__c,Engagement_Start__c, Engagement_End__c, Status__c
            FROM Engagement__c
            WHERE X20_Group__c IN :groupIds AND Engagement_Start_Date__c > TODAY 
            AND Status__c IN ('Tentative', 'Firm', 'Cancellatiion Inquiry')
        ];
        
        System.debug('TwentyGroupController.getRelavantFutureEngagements: engagements ' + engagements);
        return engagements;
    }

    // Delete previous Group Owner on Engagement Attendees with Type of 'Moderator'.
    private static void cancelModeratorAttendees(List<Engagement__c> engagements, Map<Id, Id> oldGroupOwnerMap) {
		
        if (engagements == null || engagements.isEmpty()) {
            System.debug('TwentyGroupController.cancelModeratorAttendees :: No engagements provided to cancelModeratorAttendees.');
            return;
    	}
        
        // Create a map to relate each Engagement to it's related Twenty Group.
        Map<Id, Id> engagementToGroup = new Map<Id, Id>();
        for(Engagement__c eng : engagements) {            
            engagementToGroup.put(eng.Id, eng.X20_Group__c);
        }
        
        // Get all Moderator Attendees for the engagements. 
        List<Engagement_Attendee__c> attendees = [
            SELECT Id, Name, Engagement__c, Attendee_Type__c, Contact__c 
            FROM Engagement_Attendee__c 
            WHERE Engagement__c IN :engagementToGroup.keySet() 
            AND Attendee_Type__c = 'Moderator'
        ];

        System.debug('TwentyGroupController.cancelModeratorAttendees: ' + attendees);
        List<Engagement_Attendee__c> attendeesToUpdate = new List<Engagement_Attendee__c>();

        // Remove the Attendees whose Contact matches the old Group Owner.
        for(Engagement_Attendee__c ea : attendees) {
            Id twentyGroupId = engagementToGroup.get(ea.Engagement__c); // Get the related Twenty Group Id for the current Engagement.
            Id oldGroupOwnerId = oldGroupOwnerMap.get(twentyGroupId); // Get the old Group Owner Id.
            
            if(oldGroupOwnerId == null) continue;

            if(oldGroupOwnerId == ea.Contact__c) {
                ea.Attendance_Status__c = 'Cancelled';
                attendeesToUpdate.add(ea);
            }
        }

        if(!attendeesToUpdate.isEmpty()) {
            System.debug('TwentyGroupController.cancelModeratorAttendees :: attendeesToUpdate: ' + attendeesToUpdate);
            List<Database.SaveResult> results = Database.update(attendeesToUpdate, false);
            Logger.logErrorList('TwentyGroupController.cancelModeratorAttendees', results, attendeesToUpdate);
           // update(attendeesToUpdate);
        }       
    }

    // Add new Engagement Attendees with Type of 'Moderator', and other fields.
    private static void addModeratorAttendees(List<Engagement__c> engagements, Map<Id, Id> newGroupOwnerMap) {

        // Create a map to relate each Engagement to it's related Twenty Group.
        Map<Id, Id> engagementToGroup = new Map<Id, Id>();
        for(Engagement__c eng : engagements) {            
            engagementToGroup.put(eng.Id, eng.X20_Group__c);
        }

        // Get all Moderator Attendees for the engagements. 
        List<Engagement_Attendee__c> attendees = [
            SELECT Id, Name, Engagement__c, Attendee_Type__c, Contact__c, Collateral_Name__c 
            FROM Engagement_Attendee__c 
            WHERE Engagement__c IN :engagementToGroup.keySet() 
            AND Attendee_Type__c = 'Moderator'
        ];

        // Get Group Owner Ids to get the related Account Info. newPropOwnerMap(TwentyGroupId, GroupOwnerId/ContactId)        
        Set<Id> groupOwnerIds = new Set<Id>(newGroupOwnerMap.values()); // Cast the returned List to a Set. 

        Map<Id, Contact> contactMap = new Map<Id, Contact>([
            SELECT Id, FirstName, LastName, Nickname__c, AccountId, Account.ShippingCity, Account.ShippingStateCode 
            FROM Contact
            WHERE Id IN :groupOwnerIds
        ]);
        
        System.debug('TwentyGroupController.addModeratorAttendees:: contactMap: ' + contactMap);
        List<Engagement_Attendee__c> attendeesToCreate = new List<Engagement_Attendee__c>();
        
        // Loop through each Engagement to create a new Moderator Attendee. 
        for(Engagement__c eng : engagements) {
            Id twentyGroupId = eng.X20_Group__c; // Get the related Twenty Group Id for the current Engagement.
            Id newGroupOwnerId = newGroupOwnerMap.get(twentyGroupId); // Get the new Group Owner Id for this Twenty Group. 

            // Skip if no valid Group Owner is assigned or not found in the Contact map.
            if(newGroupOwnerId == null || !contactMap.containsKey(newGroupOwnerId)) {
                continue;
            }
            // Get the current Contact record.
            Contact con = contactMap.get(newGroupOwnerId);

            // Create the new Engagement Attendee record. 
            Engagement_Attendee__c newAttendee = new Engagement_Attendee__c();
            newAttendee.Contact__c = con.Id;
            newAttendee.Account__c = con.AccountId;
            newAttendee.Attendee_Type__c = 'Moderator';
            newAttendee.Engagement__c = eng.Id;
            newAttendee.City__c = con.Account.ShippingCity;
            newAttendee.State__c = con.Account.ShippingStateCode;  
            newAttendee.Age_Group__c = 'Adult';
            newAttendee.Arrival__c = eng.Engagement_Start__c.addDays(-1);
            newAttendee.Departure__c = eng.Engagement_End__c;
            newAttendee.Attendance_Status__c = 'Confirmed';
            if(!String.isBlank(con.Nickname__c)) {
                newAttendee.Collateral_Name__c = con.Nickname__c + ' ' + con.LastName;
            } else {
                newAttendee.Collateral_Name__c = con.FirstName + ' ' + con.LastName;
            }
            attendeesToCreate.add(newAttendee);            
        }
        
        if(!attendeesToCreate.isEmpty()) {
            System.debug('TwentyGroupController.addModeratorAttendees :: attendeesToCreate: ' + attendeesToCreate);
            List<Database.SaveResult> results = Database.insert(attendeesToCreate, false);
            Logger.logErrorList('TwentyGroupController.addModeratorAttendees', results, attendeesToCreate);
            //insert(attendeesToCreate);
        }
    }

}