public without sharing class EngagementAttendeeService {
    
    public static void setAttendeeNumbering(List<Engagement_Attendee__c> newAttendees, Map<Id, Engagement_Attendee__c> oldMap){

        final String logTag = '[EngagementAttendeeService::setAttendeeNumbering]';

        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> engagementIdSet = new Set<Id>();
        
        // Collect all of the Engagement records we'll be working with. We need to know
        // the Last_Attendee_Used__c number for each so we know where to start counting 
        // from as we add new attendees to them.
        for(Engagement_Attendee__c att : newAttendees){
            engagementIdSet.add(att.Engagement__c);
            contactIdSet.add(att.Contact__c);
        }

        Map<Id,Contact> contactMap = new Map<Id,Contact>([SELECT Id, Name, Email FROM Contact WHERE Id IN :contactIdSet]);
        

        // Next, keep track of the current count for each Engagement. Assume that there is
        // more than one Engagement in play as this trigger can work on multiple Attendees at 
        // one time (ex: a user bulk uploads a list of 50 attendees, some for different engagements).
        Map<Id, Integer> engagementCountMap = new Map<Id, Integer>();
        Map<Id, Engagement__c> engagementsMap = new Map<Id,Engagement__c>([SELECT Id, Name, Engagement_Number__c, Last_Attendee_Used__c FROM Engagement__c WHERE Id IN :engagementIdSet]);

        for(Engagement__c eng : engagementsMap.values()){
            if(eng.Last_Attendee_Used__c == null) eng.Last_Attendee_Used__c = 0; // Initialize this to zero if not set already.
            engagementCountMap.put(eng.Id, Integer.valueOf(eng.Last_Attendee_Used__c) );
        }
        
            
        // Now loop through the new Engagement_Attendee__c records and set the Attendee Number with the next available number from the Engagement.
        for(Engagement_Attendee__c att : newAttendees){
            
            Integer nextAttNum = engagementCountMap.get(att.Engagement__c) + 1;
            att.Attendee_No__c = nextAttNum;
            // Keep track of what attendee # we assigned and store it with the appropriate Engagement.
            engagementCountMap.put(att.Engagement__c, nextAttNum); // update the map so we know what the last number was.
            att.Name = formatAttendeeName(att, contactMap, engagementsMap);
            
        }

        // Finally, update all of the Engagement's Last_Attendee_Used__c values to keep their count accurate.
        List<Engagement__c> engagementsToUpdate = new List<Engagement__c>();
        for(Id engId : engagementCountMap.keySet()){
            engagementsToUpdate.add(
                new Engagement__c(
                    Id = engId,
                    Last_Attendee_Used__c = engagementCountMap.get(engId)
                )
            );
        }
        try{
            update(engagementsToUpdate);
            System.debug(logTag + 'Updated ' + engagementsToUpdate.size() + ' Engagements with new Last_Attendee_Used__c values.');
        } catch (DmlException dmlEx){
            System.debug(logTag + 'Error updating Engagements: ' + dmlEx.getMessage());
        }
        
        
    }

    public static void checkAttendeeChanges(List<Engagement_Attendee__c> newAttendees, Map<Id, Engagement_Attendee__c> oldMap){

        final String logTag = '[EngagementAttendeeService::checkAttendeeChanges]';

        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> engagementIdSet = new Set<Id>();
        List<Engagement_Attendee__c> attendeeUpdateList = new List<Engagement_Attendee__c>();

        // Collect all of the Engagement records we'll be working with. We need to know
        // the Last_Attendee_Used__c number for each so we know where to start counting 
        // from as we add new attendees to them.
        for(Engagement_Attendee__c att : newAttendees){
            
            Engagement_Attendee__c oldAtt = oldMap.get(att.Id);
            if(oldAtt != null && oldAtt.Contact__c != att.Contact__c){
                System.debug(logTag + 'Attendee contact has changed, updating attendee name.');
                engagementIdSet.add(att.Engagement__c);
                contactIdSet.add(att.Contact__c);
                attendeeUpdateList.add(att);
            }
            
        }

        // If there's nothing in attendeeUpdateList, there's nothing to do..
        if(attendeeUpdateList.isEmpty()) return;

        Map<Id,Contact> contactMap = new Map<Id,Contact>([SELECT Id, Name, Email FROM Contact WHERE Id IN :contactIdSet]);    

        // Next, keep track of the current count for each Engagement. Assume that there is
        // more than one Engagement in play as this trigger can work on multiple Attendees at 
        // one time (ex: a user bulk uploads a list of 50 attendees, some for different engagements).
        Map<Id, Integer> engagementCountMap = new Map<Id, Integer>();
        Map<Id, Engagement__c> engagementsMap = new Map<Id,Engagement__c>([SELECT Id, Name, Engagement_Number__c, Last_Attendee_Used__c FROM Engagement__c WHERE Id IN :engagementIdSet]);

        // Now loop through the new Engagement_Attendee__c records and set the Attendee Number with the next available number from the Engagement.
        for(Engagement_Attendee__c att : attendeeUpdateList){
            
            att.Name = formatAttendeeName(att, contactMap, engagementsMap);
            
        }

        //update(attendeeUpdateList);            
    }
    
    // Derrick Chavez 5.09.25: SALES-1934: This was a bug ticket, but I also was able to convert the PB - Engagement Attendee Naming (Invocable).
    // If Attendee Name or Type is changed, and the Attendee Name doesn't meet correct format, then format the Attendee Name. The PB had a formula that was used for comparison.
    // [Engagement_Attendee__c].Contact__c.Contact_Name__c & " (" & TEXT( [Engagement_Attendee__c].Attendee_Type__c ) & ") - " & [Engagement_Attendee__c].Attendee_Code__c 
    public static void updateAttendeeName(List<Engagement_Attendee__c> newAttendees, Map<Id,Engagement_Attendee__c> oldMap) {
        final String logTag = '[EngagementAttendeeService::updateAttendeeName] is running!';      
        Set<Id> contactIds = new Set<Id>();  
        Set<Id> engagementIds = new Set<Id>();
        List<Engagement_Attendee__c> attendeesToUpdate = new List<Engagement_Attendee__c>();

        for(Engagement_Attendee__c att : newAttendees) {
            Engagement_Attendee__c oldAtt = oldMap.get(att.Id);
            // If the Name  or Attendee Type field has changed, add the Contact and Enagement to a set.
            if(oldAtt != null && att.Contact__c != null) {
                if(oldAtt.Name != att.Name || oldAtt.Attendee_Type__c != att.Attendee_Type__c) {
                    System.debug(logTag + 'Attendee Name field has changed, updating it with the correct format.');
                    contactIds.add(att.Contact__c);    
                    engagementIds.add(att.Engagement__c);  
                }      
            }
        }
        
        if(contactIds.isEmpty()) return;
        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, Name, Contact_Name__c, Email FROM Contact WHERE Id IN :contactIds]);        
        Map<Id, Engagement__c> engagementMap = new Map<Id,Engagement__c>([SELECT Id, Name, Engagement_Number__c FROM Engagement__c WHERE Id IN :engagementIds]);   

        // Loop through the new Engagement_Attendee__c records ,and set the Attendee Name with the correct format.
        for(Engagement_Attendee__c att :newAttendees) {   
            Engagement_Attendee__c oldAtt = oldMap.get(att.Id);                   
            if(oldAtt != null && att.Contact__c != null) {
                if(oldAtt.Name != att.Name || oldAtt.Attendee_Type__c != att.Attendee_Type__c) {
                    String expectedName = '';
                    // Get the Contact Name or Collateral Name and build the expectedName format to validate against the Attendee Name.
                    if(contactMap.containsKey(att.Contact__c)) {
                        Contact c = contactMap.get(att.Contact__c);
                        // Use Contact Name if its available.
                        expectedName += c.Contact_Name__c;
                    } else if(!String.isBlank(att.Collateral_Name__c)) {
                        // Use Collateral Name if Contact Name is not available.
                        expectedName += att.Collateral_Name__c;
                    }
                    
                    expectedName += ' (' + String.valueOf(att.Attendee_Type__c) + ') - ' + att.Attendee_Code__c;
                    System.debug(logTag + 'Expected Attendee Name: ' + expectedName);                

                    if(expectedName != att.Name) {
                        att.name = formatAttendeeName(att, contactMap, engagementMap);
                        attendeesToUpdate.add(att);                     
                    }
                }
            }           
        }
        // No update required. Before context. 
    }

    @testVisible
    private static String formatAttendeeName(Engagement_Attendee__c att, Map<Id,Contact> contactMap, Map<Id,Engagement__c> engMap){
        String attName = '';
        if(att.Contact__c != null){
            Contact ct = contactMap.get(att.Contact__c);
            attName += ct.Name;
        } else {
            attName += att.Collateral_Name__c;
        }

        Engagement__c eng = engMap.get(att.Engagement__c);
        attName += ' (' + att.Attendee_Type__c + ') - ' + eng.Engagement_Number__c + '-' + att.Attendee_No__c;

        System.debug('formatAttendeeName: ' + attName);
        return attName;

    } 


    //this method added by Tim Osborn on 8/28/2023 for SALES-970
    public static void removeFromActivities(List<Engagement_Attendee__c> newList, Map<Id,Engagement_Attendee__c> oldMap) {
        if(!TriggerHandler.isBypassed('EngagementAttendeeService.removeFromActivities')) {
            List<String> statuses = new List<String>{'Removed', 'Not Attending', 'Duplicate', 'Cancelled'};
            List<Engagement_Attendee__c> removedList = new List<Engagement_Attendee__c>();
            for(Engagement_Attendee__c eA : newList) {
                //Attendance_Status__c is a required field so I did not include null checking.
                if(statuses.contains(eA.Attendance_Status__c)
                    && eA.Attendance_Status__c != oldMap.get(eA.Id).Attendance_Status__c
                ) {
                    removedList.add(eA);
                }            
            }
            if(!removedlist.isEmpty()) {
                List<Activity_Participation__c> aPList = [SELECT Id 
                                                            FROM Activity_Participation__c 
                                                            WHERE Engagement_Attendee__c IN :removedList];
                List<Database.DeleteResult> drList = Database.delete(aPList, false);
                Logger.logDeleteErrorList('EngagementAttendeeService::removeFromActivities', drList, aPList);
            }
            TriggerHandler.bypass('EngagementAttendeeService.removeFromActivities');
        }
    }

    public static void uncheckMeetingroom(List<Engagement_Attendee__c> newList, Map<Id,Engagement_Attendee__c> oldMap) {
        List<Engagement_Attendee__c> dupList = new List<Engagement_Attendee__c>();
        for(Engagement_Attendee__c eA : newList) {
            //Attendance_Status__c is a required field so I did not include null checking.
            if(eA.Attendance_Status__c == 'Duplicate' 
                && oldMap.get(eA.Id).Attendance_Status__c != 'Duplicate'
                && eA.In_Meeting_Room__c == true
            ) {
                dupList.add(new Engagement_Attendee__c(Id = eA.Id, In_Meeting_Room__c = false));
            }            
        }
        if(!dupList.isEmpty()) {
            List<Database.SaveResult> dsrList = Database.update(dupList,false);
            Logger.logErrorList('EngagementAttendeeService::uncheckMeetingroom', dsrList, dupList);
        }
    }
    
    // Derrick: SALES-1677/1843, 2/26/2025. Send CSV Email with attachement when Attendance Status criteria are met on Engagement_Attendee__c and Engagement__c.
    public static void checkAttendeeStatus(List<Engagement_Attendee__c> newList, Map<Id,Engagement_Attendee__c> oldMap) {
        System.debug('EngagementAttendeeService.checkAttendeeStatus:: is running.');
        
        Engagement_Attendee__c newAttendee = newList[0];
		Engagement_Attendee__c oldAttendee = new Engagement_Attendee__c(); 
        Boolean shouldEnqueueJob = false;
        String oldEngagementId = null;
               
        if(oldMap != null) {
        	oldAttendee = oldMap.get(newAttendee.Id);  
        }
        if(oldMap == null) {
            shouldEnqueueJob = true;
        } else if(newAttendee.Attendance_Status__c != oldAttendee.Attendance_Status__c) {
            if(newAttendee.Attendance_Status__c == 'Registration Confirmed') {
            	shouldEnqueueJob = true;   
            } else if(newAttendee.Attendance_Status__c == 'Rebooking' && oldAttendee.Attendance_Status__c == 'Registration Confirmed') {
                shouldEnqueueJob = true; 
                oldEngagementId = oldAttendee.Engagement__c; // pass in the oldEngagementId. Needed for the 'Rebooking' status to query for attendees. 
            } else if((newAttendee.Attendance_Status__c != 'Registration Confirmed' || oldAttendee.Attendance_Status__c == 'Registration Confirmed') && newAttendee.Attendance_Status__c != 'Rebooking') {
                shouldEnqueueJob = true; 
            }
        } else {
            System.debug('EngagementAttendeeService.checkAttendeeStatus:: No Attendees meet the criteria.');
        }  
        
        if(shouldEnqueueJob) {
        	Id jobId = System.enqueueJob(new EngagementAttendeeUtilityReportQueueable(newAttendee.Id, oldEngagementId, newAttendee.Attendance_Status__c)); 
        }
    }

    // Derrick: SALES-1903; 4.17.25 - For my own sanity, I have a bit more comments than usual for readability. 
    // This formula is on the ENGAGEMENT_ATTENDEE_ON_EDIT FLOW. The flow sends out a 'REGISTRATION CONFIRMATION' email. I have made edits to some of the formula, and converted to Apex logic. 
    // Only return TRUE if ALL FOUR conditions are TRUE, then call EngagementInstituteWelcomeEmailsBatch. (I have added other coditinons as well to meet additional requirements)
    /*
    AND(
        -- Condition 1
        ISPICKVAL({!$Record.Attendance_Status__c}, 'Registration Confirmed'), --- Boolean isRegistrationConfirmed = attendee.Attendance_Status__c == 'Registration Confirmed';
        -- Condition 2
        CONTAINS({!$Record.RecordType.Name} , 'Institute') --- Boolean isInstituteRecordType = attendee.RecordType.Name.contains('Institute');
        -- Condition 3                  
        OR(
            {!$Record.Engagement__r.RecordType.Name} = 'NCM Institute Class - Onsite', --- Boolean isOnsiteOrOffsiteRecordType = attendee.Engagement__r.RecordType.DeveloperName = 'Institute'  
            {!$Record.Engagement__r.RecordType.Name} = 'NCM Institute Class - Offsite' --- Boolean isOnsiteOrOffsiteRecordType = attendee.Engagement__r.RecordType.DeveloperName = 'Institute_Offsite';
        ),
        -- Condition 4
        OR(
            ISNEW(),
            ISCHANGED({!$Record.Attendance_Status__c} ), --- Boolean isAttendanceStatusChanged = attendee.Attendance_Status__c != oldAttendee.Attendance_Status__c;
            ISCHANGED({!$Record.Engagement__c} ),        --- Boolean isEngagementChanged = attendee.Engagement__c != oldAttendee.Engagement__c;
            ISCHANGED({!$Record.Student__c} )            --- Boolean isStudentChanged = attendee.Student__c != oldAttendee.Student__c;
        ) 
    )
    */    
    public static void sendWelcomeEmails(List<Engagement_Attendee__c> newList, Map<Id,Engagement_Attendee__c> oldMap) {
        System.debug('EngagementAttendeeService.sendWelcomeEmails:: is running.');
        // query the records that may not be automatically included in trigger.new (newList)
        Map<Id, Engagement_Attendee__c> attendeeMap = new Map<Id, Engagement_Attendee__c>(
                                        [SELECT Id, Attendance_Status__c, Engagement__c, Student__c, Welcome_Email_Sent__c, RecordType.Name, 
                                                Engagement__r.Engagement_Start_Date__c , Engagement__r.RecordType.DeveloperName
                                         FROM Engagement_Attendee__c
                                         WHERE Id IN :newList]  
                                        );

        // set to hold qualifying records for batch processing. this will be sent to the batch constructor. 
        Set<Id> engagementIdsToProcess = new Set<Id>();  
        Date today = Date.today();
        Date fiveDaysAhead = today.addDays(5);
        Engagement_Attendee__c oldAttendee = new Engagement_Attendee__c(); 
		List<Engagement_Attendee__c> attendeesCleared = new List<Engagement_Attendee__c>();

        for(Engagement_Attendee__c attendee :attendeeMap.values()) {
             // AfterUpdate: get the old version of the record. 
            if(oldMap != null) {
                oldAttendee = oldMap.get(attendee.Id);  
            }

            // 1. Check Engagement Attendee_Status: Must be 'Registration Confirmed'. FORMULA: ISPICKVAL({!$Record.Attendance_Status__c}, 'Registration Confirmed'),  
            Boolean isRegistrationConfirmed = attendee.Attendance_Status__c == 'Registration Confirmed';
            System.debug('EngagementAttendeeService.sendWelcomeEmails:: isRegistrationConfirmed: ' + isRegistrationConfirmed);

            // 2. Check Engagement RecordType.Name must contain 'Institute'. FORMULA: CONTAINS({!$Record.RecordType.Name} , 'Institute') , 
            Boolean isInstituteRecordType = attendee.RecordType.Name.contains('Institute');
            System.debug('EngagementAttendeeService.sendWelcomeEmails:: isInstituteRecordType: ' + isInstituteRecordType); 

            // 3. Check the Engagment Record Type: Must be Onsite or Institute. FORMULA:
            //   OR(
            //   {!$Record.Engagement__r.RecordType.Name} = 'NCM Institute Class - Onsite',
            //   {!$Record.Engagement__r.RecordType.Name} = 'NCM Institute Class - Offsite' 
            Boolean isOnsiteOrOffsiteRecordType = attendee.Engagement__r.RecordType.DeveloperName == 'Institute' || attendee.Engagement__r.RecordType.DeveloperName == 'Institute_Offsite';
            System.debug('EngagementAttendeeService.sendWelcomeEmails:: isOnsiteOrOffsiteRecordType: ' + isOnsiteOrOffsiteRecordType);  

            // 4. Only run the logic if record is New (insert), OR specific fields have changed (update). (Attendance_Status__c, Engagement__c, Student__c)
            Boolean isNewOrIsChanged = oldAttendee == null || // isInsert
                                       attendee.Attendance_Status__c != oldAttendee.Attendance_Status__c || // Attendance_Status__c has changed
                                       attendee.Engagement__c != oldAttendee.Engagement__c || // Engagement__c has changed
                                       attendee.Student__c != oldAttendee.Student__c;        // Student__c has changed.
            System.debug('EngagementAttendeeService.sendWelcomeEmails:: isNewOrIsChanged: ' + isNewOrIsChanged); 
            
            // Always clear field when the previous conditions are met.
            if(isNewOrIsChanged && attendee.Attendance_Status__c != 'Attended') {
                attendee.Welcome_Email_Sent__c = null; // clear out the date, so the email can be resent.  
                attendeesCleared.add(attendee); 
            }           
            
            // 5. Check if Engagement has changed.
            Boolean isEngagementChanged = attendee.Engagement__c != oldAttendee.Engagement__c;
            System.debug('EngagementAttendeeService.sendWelcomeEmails:: isEngagementChanged: ' + isEngagementChanged);

            // 6.  Check to see if the new Attendee is within five days all the way up to the start date. 
            Boolean withinFiveDays = attendee.Engagement__r.Engagement_Start_Date__c != null && 
                                     attendee.Engagement__r.Engagement_Start_Date__c >= today && 
                                     attendee.Engagement__r.Engagement_Start_Date__c <= fiveDaysAhead;
            System.debug('EngagementAttendeeService.sendWelcomeEmails:: withinFiveDays: ' + withinFiveDays);
			
            // Make sure all the conditions return true, also make sure the Welcome Email Sent is NULL to avoid sending emails that have already been sent. 
            if(isRegistrationConfirmed && isInstituteRecordType && isOnsiteOrOffsiteRecordType && isNewOrIsChanged && withinFiveDays && attendee.Welcome_Email_Sent__c == null) {
                 engagementIdsToProcess.add(attendee.Engagement__c);                
            }
        }  
		// Clear out the Welcome Email Sent field. 
        if(!attendeesCleared.isEmpty()) {
            update(attendeesCleared);
        }
        if(!engagementIdsToProcess.isEmpty()) {          
            EngagementInstituteWelcomeEmailsBatch.runBatchFromTrigger(engagementIdsToProcess);
        }   

    }

}