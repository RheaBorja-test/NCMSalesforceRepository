// Derrick Chavez: 6.11.2025; SALES-1195,2096
// If a Moderator (Group Owner) is updated on Proprietary Group, then the system will automatically change 
// the previous Group Owner, and add the new Group Owner to all future Engagements with a status of 'Tentative’, 'Firm’, or 'Cancellation Inquiry’.
// Instead of replacing the old Attendee, it will set the Attendance Status to 'Cancelled'. 
public class PropGroupController {
    
    public static void handleGroupOwnerChange(List<Proprietary_Group__c> newList, Map<Id, Proprietary_Group__c> oldMap) {
        
        // Create two maps to track the previous Group Owner Contact ID and the new Group Owner Conact ID. 
        Map<Id, Id> oldGroupOwnerMap = new Map<Id,Id>();
        Map<Id, Id> newGroupOwnerMap = new Map<Id,Id>();
        
        // Identify changes to the Group Owner (Group_Owner__c).
        for(Proprietary_Group__c propGroup : newList) {
            Id oldGroupOwnerId = oldMap.get(propGroup.Id).Group_Owner__c;
            Id newGroupOwnerId = propGroup.Group_Owner__c;
            
            // If Group Owner is changed, then add the values to the maps. 
            if(oldGroupOwnerId != newGroupOwnerId) {
                if(oldGroupOwnerId != null) {
                    oldGroupOwnerMap.put(propGroup.Id, oldGroupOwnerId); // track which Attendee (Group Owner) to set to 'Cancelled'. 
                }
                if(newGroupOwnerId != null) {
                    newGroupOwnerMap.put(propGroup.Id, newGroupOwnerId); // track which Attendee (Group Owner), needs to be created. 
                }
            }            
        }

        // Add all the Keys (Prop Group Ids) to a Set, then pass into each method to get the Engagements.
        Set<Id> groupIds = new Set<Id>();
        groupIds.addAll(oldGroupOwnerMap.keySet());
        groupIds.addAll(newGroupOwnerMap.keySet());
        System.debug('PropGroupController.handleGroupOwnerChange:: groupIds: ' + groupIds);

        if(groupIds.isEmpty()) return;   

        // Get the future Engagements and cancel the Engagement Attendees. 
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
            SELECT Id, Name, Proprietary_Group__c, Engagement_Start__c
            FROM Engagement__c
            WHERE Proprietary_Group__c IN :groupIds AND Engagement_Start__c > TODAY
        ];
        
        System.debug('PropGroupController.getFutureEngagements: engagements ' + engagements);
        return engagements;
    }

    private static List<Engagement__c> getRelavantFutureEngagements(Set<Id> groupIds) {

        List<Engagement__c> engagements = [
            SELECT Id, Name, Proprietary_Group__c, Engagement_Start__c, Engagement_End__c, Status__c
            FROM Engagement__c
            WHERE Proprietary_Group__c IN :groupIds AND Engagement_Start__c > TODAY 
            AND Status__c IN ('Tentative', 'Firm', 'Cancellation Inquiry')
        ];
        
        System.debug('PropGroupController.getRelavantFutureEngagements: engagements ' + engagements);
        return engagements;
    }

    // Change the previous Group Owner on Engagement Attendees with Attendance Status 'Cancelled'. 
    private static void cancelModeratorAttendees(List<Engagement__c> engagements, Map<Id, Id> oldGroupOwnerMap) {
                
        if (engagements == null || engagements.isEmpty()) {
            System.debug('PropGroupController.cancelModeratorAttendees :: No engagements provided to cancelModeratorAttendees.');
            return;
    	}

        // Create a map to relate each Engagement to it's related Proprietary Group.
        Map<Id, Id> engagementToGroup = new Map<Id, Id>();
        for(Engagement__c eng : engagements) {            
            engagementToGroup.put(eng.Id, eng.Proprietary_Group__c);
        }
        
        // Get all Moderator Attendees for the engagements. 
        List<Engagement_Attendee__c> attendees = [
            SELECT Id, Name, Engagement__c, Attendee_Type__c, Contact__c, Attendance_Status__c
            FROM Engagement_Attendee__c 
            WHERE Engagement__c IN :engagementToGroup.keySet() 
            AND Attendee_Type__c = 'Moderator'
        ];
        
        System.debug('PropGroupController.cancelModeratorAttendees: ' + attendees);
        List<Engagement_Attendee__c> attendeesToUpdate = new List<Engagement_Attendee__c>();

        // Set the Attendees Attendance Status to 'Cancelled' whose Contact matches the old Group Owner.
        for(Engagement_Attendee__c ea : attendees) {
            Id propGroupId = engagementToGroup.get(ea.Engagement__c); // Get the related Proprietary Group Id for the current Engagement.
            Id oldGroupOwnerId = oldGroupOwnerMap.get(propGroupId); // Get the old Group Owner Id.
            
            if(oldGroupOwnerId == null) continue;

            if(oldGroupOwnerId == ea.Contact__c) {
                ea.Attendance_Status__c = 'Cancelled';
                attendeesToUpdate.add(ea);
            }
        }

        if(!attendeesToUpdate.isEmpty()) {
            System.debug('PropGroupController.cancelModeratorAttendees :: attendeesToUpdate: ' + attendeesToUpdate);
            List<Database.SaveResult> results = Database.update(attendeesToUpdate, false);
            Logger.logErrorList('PropGroupController.cancelModeratorAttendees', results, attendeesToUpdate);
            //update(attendeesToUpdate);
        }       
    }

    // Add new Engagement Attendees with Type of 'Moderator', and other fields.
    private static void addModeratorAttendees(List<Engagement__c> engagements, Map<Id, Id> newGroupOwnerMap) {
    
        if (engagements == null || engagements.isEmpty()) {
            System.debug('PropGroupController.addModeratorAttendees :: No engagements passed to addModeratorAttendees.');
            return;
        }
    
        // Create a map to relate each Engagement to its related Proprietary Group.
        Map<Id, Id> engagementToGroup = new Map<Id, Id>();
        for (Engagement__c eng : engagements) {            
            engagementToGroup.put(eng.Id, eng.Proprietary_Group__c);
        }
    
        // Get all existing Moderator Attendees for the relevant Engagements.
        List<Engagement_Attendee__c> attendees = [
            SELECT Id, Name, Engagement__c, Attendee_Type__c, Contact__c, Collateral_Name__c 
            FROM Engagement_Attendee__c 
            WHERE Engagement__c IN :engagementToGroup.keySet() 
            AND Attendee_Type__c = 'Moderator'
        ];
    
        // Get Group Owner Contact records to populate Engagement Attendees.
        Set<Id> groupOwnerIds = new Set<Id>(newGroupOwnerMap.values());
    
        Map<Id, Contact> contactMap = new Map<Id, Contact>([
            SELECT Id, FirstName, LastName, Nickname__c, AccountId, Account.ShippingCity, Account.ShippingStateCode 
            FROM Contact
            WHERE Id IN :groupOwnerIds
        ]);
    
        System.debug('PropGroupController.addModeratorAttendees:: contactMap: ' + contactMap);    
        List<Engagement_Attendee__c> attendeesToCreate = new List<Engagement_Attendee__c>();
        
        // Loop through each Engagement to create a new Moderator Attendee.
        for (Engagement__c eng : engagements) {
            Id propGroupId = eng.Proprietary_Group__c;
            Id newGroupOwnerId = newGroupOwnerMap.get(propGroupId);
    
            // Skip if no valid Group Owner is assigned or not found in the Contact map.
            if (newGroupOwnerId == null || !contactMap.containsKey(newGroupOwnerId)) {
                continue;
            }    
            Contact con = contactMap.get(newGroupOwnerId);
    
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

        if (!attendeesToCreate.isEmpty()) {
            System.debug('PropGroupController.addModeratorAttendees :: attendeesToCreate: ' + attendeesToCreate);
            List<Database.SaveResult> results = Database.insert(attendeesToCreate, false);
            Logger.logErrorList('PropGroupController.addModeratorAttendees', results, attendeesToCreate);
            //insert(attendeesToCreate);
        }
	}

}