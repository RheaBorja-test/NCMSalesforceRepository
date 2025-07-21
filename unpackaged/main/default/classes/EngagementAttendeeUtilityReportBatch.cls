global class EngagementAttendeeUtilityReportBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    
    global Integer attendeeSize = 0; // variable to determine if no records need to be processed. 
    // Key: Engagement Name, Value: CSV content (header + data rows)
    global Map<String, String> usEngagementMap = new Map<String, String>();
    global Map<String, String> caEngagementMap = new Map<String, String>();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('EngagementAttendeeUtilityReportBatch Start is Running!');

        return Database.getQueryLocator(
            [SELECT Id, 
                    Name,
                    Attendance_Status__c,  
                    Engagement__r.Name,  
                    Engagement__r.RecordType.Name, 
                    Engagement__r.Country_pl__c,
                    Contact__r.Name,  
                    Contact_Email__c, // Contact Email / Attendee Email
                    Financial_Data_Account__r.Name, // Account: Account Name / Financial Data Account
                    Financial_Data_Account__r.ShippingPostalCode, // Account: Shipping Zip/Postal Code / Financial Data Account Zip 
                    Financial_Data_Number__c,  
                    Financial_Data_Notes__c,
                    Last_Time_Rescheduled__c,  
                    Registration_Received__c                             
            FROM    Engagement_Attendee__c
            WHERE   Attendance_Status__c = 'Registration Confirmed'
            AND     Engagement__r.RecordType.Name LIKE 'NCM Institute Class%' 
            AND     Engagement__r.Course__r.Composite_PTA__c = true
            AND (
                (
            		(Engagement__r.Country_pl__c = 'United States' OR Engagement__r.Country_pl__c = '')                        
                	AND Engagement__r.Engagement_Start_Date__c > NEXT_N_DAYS:7 
                	AND Engagement__r.Engagement_Start_Date__c <= NEXT_N_DAYS:35  
			    	)
                OR 
                	(
                    Engagement__r.Country_pl__c = 'Canada'
                    AND     Engagement__r.Engagement_Start_Date__c > NEXT_N_DAYS:7 
                    AND     Engagement__r.Engagement_Start_Date__c <= NEXT_N_DAYS:42
                    )
                )                 
            ]);        
    } 

    global void execute(Database.BatchableContext BC, List<Engagement_Attendee__c> attendees) {
        System.debug('EngagementAttendeeUtilityReportBatch Execute is Running!');
        attendeeSize = 1;
        
        // Generate CSV content
        for(Engagement_Attendee__c attendee : attendees) {
            String csvHeader;
            String engagementName = attendee.Engagement__r.Name;
            Boolean isVirtualTraining = attendee.Engagement__r.RecordType.Name.contains('Virtual Training');
           
            if(isVirtualTraining) {
                csvHeader = 'Account: Account Name,Account: Shipping Zip/Postal Code,Contact,Contact Email,Financial Data Number,Financial Data Notes,Registration Received,Engagement: Engagement Name,Last Time Rescheduled\n';         
            } else {
                csvHeader = 'Financial Data Account,Financial Data Account Zip,Contact,Attendee Email,Financial Data Number,Financial Data Notes,Registration Received,Engagement: Engagement Name,Last Time Rescheduled\n';
            }   
        
            String csvRow = '"' + attendee.Financial_Data_Account__r.Name + '","' + attendee.Financial_Data_Account__r.ShippingPostalCode + '","' + attendee.Contact__r.Name + '","' + attendee.Contact_Email__c + '","' +
                                + attendee.Financial_Data_Number__c  + '","' + attendee.Financial_Data_Notes__c + '","' + attendee.Registration_Received__c + '","' + attendee.Engagement__r.Name + '","' + attendee.Last_Time_Rescheduled__c + '"' + '\n';
			
            // Append to the engagement-specific CSV
            // If the Engagement is new, then add the header + row to usEngagementMap.
            // If the Engagement already exists, then append only the row to the existing CSV data.            
            if(attendee.Engagement__r.Country_pl__c == 'Canada') {
            	if(!caEngagementMap.containsKey(engagementName)) {
                	caEngagementMap.put(engagementName, csvHeader + csvRow);
                } else {
                	caEngagementMap.put(engagementName, caEngagementMap.get(engagementName) + csvRow);
                }
            } else {
				if(!usEngagementMap.containsKey(engagementName)) {
                	usEngagementMap.put(engagementName, csvHeader + csvRow);
                } else {
                usEngagementMap.put(engagementName, usEngagementMap.get(engagementName) + csvRow);
                }            
            }
        }        
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('EngagementAttendeeUtilityReportBatch has Finished!');  
        System.debug('EngagementAttendeeUtilityReportBatch usEngagementMap: ' + usEngagementMap);
        System.debug('EngagementAttendeeUtilityReportBatch caEngagementMap: ' + caEngagementMap);
        
        if(!usEngagementMap.isEmpty()) {
        	sendEmail(usEngagementMap, 'US', 'notEmpty'); 
        } else {
            sendEmail(usEngagementMap, 'US', 'Empty');
        }
        if(!caEngagementMap.isEmpty()) {
        	sendEmail(caEngagementMap, 'CA', 'notEmpty');     
        } else {
            sendEmail(caEngagementMap, 'CA', 'Empty');
        }   
        String myLabelValue = System.Label.Master_Data_Service_NCMi_Email;
        List<String> toAddresses = new List<String>();  
        
        for(String email :myLabelValue.split(',')) {
        	toAddresses.add(email.trim());
        }        
        if(attendeeSize == 0) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            	email.setSubject('NCMi Utility CSV Report');
             	email.setPlainTextBody('No Engagements meet the criteria for this week.');
                email.setToAddresses(toAddresses); 
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});            
        }
    }
	
    // Create private variable to use for test coverage
    @TestVisible()
    private static Messaging.SingleEmailMessage testEmail; 
    
    // Send email with multiple attachments
    @TestVisible()
    private void sendEmail(Map<String, String> engagementCsvMap, String country, String mapVal) {
        System.debug('EngagementAttendeeUtilityReportBatch sendEmail is Running!');
        System.debug('engagementCsvMap: ' + engagementCsvMap);

        String myLabelValue = System.Label.Master_Data_Service_NCMi_Email;
        List<String> toAddresses = new List<String>();        
        for(String email :myLabelValue.split(',')) {
        	toAddresses.add(email.trim());
        }
        
        // Create a CSV attachment for each engagement
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        for (String engagementName : engagementCsvMap.keySet()) {
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFilename(engagementName.replaceAll('[^a-zA-Z0-9_-]', '_') + '.csv'); // replace special chars with '_'
            attachment.setBody(Blob.valueOf(engagementCsvMap.get(engagementName)));
            attachment.setContentType('text/csv');
            attachments.add(attachment);
        }         
        System.debug('Attachments.size: ' + attachments.size());
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if(country == 'US' || String.isBlank(country)) {
            email.setSubject('NCMi Utility CSV - US');
            if(mapVal == 'Empty') {  
                email.setPlainTextBody('No Engagements meet the criteria for this week.');
                email.setToAddresses(toAddresses); 
            } else {
            	email.setPlainTextBody('Attached are the scheduled NCMi Utility CSV - US reports, one per Engagement.');
                email.setToAddresses(toAddresses);  
                email.setFileAttachments(attachments);
            }            
            testEmail = email;          
        } else if(country == 'CA') {
            email.setSubject('NCMi Utility CSV - CA');
            if(mapVal == 'Empty') {  
                email.setPlainTextBody('No Engagements meet the criteria for this week.');
                email.setToAddresses(toAddresses);  
            } else {
            	email.setPlainTextBody('Attached are the scheduled NCMi Utility CSV - CA reports, one per Engagement.');
                email.setToAddresses(toAddresses);  
                email.setFileAttachments(attachments);
            }
            testEmail = email;
        }     
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new EngagementAttendeeUtilityReportBatch(), 200);
    }

}