// Derrick: SALES-1677/1843, 2/26/2025. Send CSV Email with attachement when Attendance Status criteria are met on Engagement_Attendee__c and Engagement__c.
public class EngagementAttendeeUtilityReportQueueable implements Queueable {

    private String newId;
    private String status;
    private String oldEngId;
    
    public EngagementAttendeeUtilityReportQueueable(String newId, String oldEngId, String status) {
        this.newId = newId;
        this.status = status;
        this.oldEngId = oldEngId;
    }

    public void execute(QueueableContext context) {
        System.debug('EngagementAttendeeUtilityReportQueueable.execute newID is: ' + newId);
        System.debug('EngagementAttendeeUtilityReportQueueable.execute oldEngId is: ' + oldEngId);
		
        if(status != 'Rebooking') {
        	sendUtilityReport(newId, status);    
        } else if(status == 'Rebooking' && oldEngId != null) {
            sendUtilityReportRebooking(oldEngId, status);
        } 
    }
       
    private static void sendUtilityReport(String attendeeId, String status) {
        System.debug('EngagementAttendeeUtilityReportQueueable.sendUtilityReport is running.');
        
        Engagement_Attendee__c attendee = getEngagementAttendee(attendeeId);        
        if(attendee == null) {
        	System.debug('EngagementAttendeeUtilityReportQueueable.sendUtilityReport:: No Matching engagement attendee found for ID: ' + attendeeId);
            return;
        }       
        List<Engagement_Attendee__c> attendees = getAttendeesForEngagement(attendee.Engagement__c);
        if(attendees.isEmpty()) {
            System.debug('EngagementAttendeeUtilityReportQueueable.sendUtilityReport:: No Matching attendees with engagements found.');
            return;
        }
        Boolean isVirtualTraining = attendee.Engagement__r.RecordType.Name.contains('Virtual Training'); 
        String csvContent = generateCsvContent(attendees, isVirtualTraining);
        sendEmail(attendee, csvContent, attendee.Engagement__r.Name, attendee.Engagement__r.Country_pl__c, status);  
    }
    
    private static void sendUtilityReportRebooking(String oldEngId, String status) {
        System.debug('EngagementAttendeeUtilityReportQueueable.sendUtilityReportRebooking is running.');
        
        Engagement_Attendee__c attendee = getAttendeeByEngagement(oldEngId);        
        if(attendee == null) {
            System.debug('EngagementAttendeeUtilityReportQueueable.sendUtilityReportRebooking:: No Matching engagement attendee found for ID: ' + oldEngId);
            return;
        }        
        List<Engagement_Attendee__c> attendees = getAttendeesForEngagement(attendee.Engagement__c);
        if(attendees.isEmpty()) {
            System.debug('EngagementAttendeeUtilityReportQueueable.sendUtilityReportRebooking:: No Matching attendees with engagements found.');
            return;
        }
        Boolean isVirtualTraining = attendee.Engagement__r.RecordType.Name.contains('Virtual Training'); 
        String csvContent = generateCsvContent(attendees, isVirtualTraining);
        sendEmail(attendee, csvContent, attendee.Engagement__r.Name, attendee.Engagement__r.Country_pl__c, status); 
    }
    
    private static Engagement_Attendee__c getEngagementAttendee(String attendeeId) {
        Engagement_Attendee__c attendee = [SELECT Id, Engagement__r.Name, Engagement__r.RecordType.Name, Engagement__r.Country_pl__c, Contact__r.Name, Contact_Email__c
                                           FROM Engagement_Attendee__c WHERE Id =:attendeeId LIMIT 1];
        return attendee;
    }
    
    // for 'Rebooking' you need the oldEngId to get the correct Engagement_Attendees. Query using the oldEngId, instead of newId.
    // reason being is when an attendee status gets updated to 'Rebooking', the engagement gets changed to a 'NCMi Rebooking' engagement. 
    // 'NCMi Rebooking' is not a real engagement, but more of a holding record, so you need to capture the engagement record before it gets changed to get the attendees. 
    private static Engagement_Attendee__c getAttendeeByEngagement(String oldEngagementId) {
        Engagement_Attendee__c attendee = [SELECT Id, Engagement__r.Name, Engagement__r.RecordType.Name, Engagement__r.Country_pl__c, Contact__r.Name, Contact_Email__c
                                           FROM Engagement_Attendee__c WHERE Engagement__c =:oldEngagementId LIMIT 1];
        return attendee;
    }
    
    // get all the Attendees that are 'Registration Confirmed' and the related Engagement. 
    private static List<Engagement_Attendee__c> getAttendeesForEngagement(String engagementId) {
        List<Engagement_Attendee__c> attendees = 
                        [SELECT Id, Name, Attendance_Status__c, Engagement__r.Name, Engagement__r.RecordType.Name,
                                Engagement__r.Country_pl__c, Contact__r.Name, Contact_Email__c,
                                Financial_Data_Account__r.Name, Financial_Data_Account__r.ShippingPostalCode,
                                Financial_Data_Number__c, Financial_Data_Notes__c, Last_Time_Rescheduled__c,                                                                                         
                                Registration_Received__c, Engagement__r.Engagement_Start_Date__c, Engagement__r.Engagement_Start__c                                                                                       
                        FROM    Engagement_Attendee__c
                        WHERE   Engagement__c = :engagementId
                        AND     Attendance_Status__c = 'Registration Confirmed' // only want to send attendees in this status. 
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
                                (Engagement__r.Country_pl__c = 'Canada')
                                AND Engagement__r.Engagement_Start_Date__c > NEXT_N_DAYS:7 
                                AND Engagement__r.Engagement_Start_Date__c <= NEXT_N_DAYS:42
                                )
                           ) ];                 
        return attendees;
    }
    
    private static String generateCsvContent(List<Engagement_Attendee__c> attendees, Boolean isVirtualTraining) {
		String csvHeader;                
        if(isVirtualTraining) {
            csvHeader = 'Account: Account Name,Account: Shipping Zip/Postal Code,Contact,Contact Email,Financial Data Number,Financial Data Notes,Registration Received,Engagement: Engagement Name,Last Time Rescheduled\n';         
        } else {
            csvHeader = 'Financial Data Account,Financial Data Account Zip,Contact,Attendee Email,Financial Data Number,Financial Data Notes,Registration Received,Engagement: Engagement Name,Last Time Rescheduled\n';
        }           
        String csvContent = csvHeader;

        // Generate CSV content
        for(Engagement_Attendee__c ea : attendees) {
            String csvRow = '"' + ea.Financial_Data_Account__r.Name + '","' + ea.Financial_Data_Account__r.ShippingPostalCode + '","' + ea.Contact__r.Name + '","' + ea.Contact_Email__c + '","' +
                            + ea.Financial_Data_Number__c  + '","' + ea.Financial_Data_Notes__c + '","' + ea.Registration_Received__c + '","' + ea.Engagement__r.Name + '","' + ea.Last_Time_Rescheduled__c + '"' + '\n';
            
            csvContent += csvRow;            
        }      
        return csvContent;        
    }
   
    @TestVisible()
    private static void sendEmail(Engagement_Attendee__c attendee, String csvContent, String engagementName, String country, String status) {
        System.debug('EngagementAttendeeUtilityReportQueueable.sendEmail is running!');
        
        String myLabelValue = System.Label.Master_Data_Service_NCMi_Email;
        List<String> toAddresses = new List<String>();          
        for(String email :myLabelValue.split(',')) {
        	toAddresses.add(email.trim());
        }
        
        String displayContact = 'Contact Name: ' + attendee.Contact__r.Name + ',' + ' Contact Email: ' + attendee.Contact_Email__c + ' has been updated.';
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();  
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFilename(engagementName.replaceAll('[^a-zA-Z0-9_-]', '_') + '.csv'); // replace special chars with '_'
            attachment.setBody(Blob.valueOf(csvContent));
            attachment.setContentType('text/csv');
            attachments.add(attachment);
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if(country == 'United States' || String.isBlank(country)) {
            if(status == 'Registration Confirmed') {
            	email.setSubject('Registration Update - NCMi Utility CSV - US');
            	email.setPlainTextBody('Attached are the scheduled NCMi Utility CSV - US Engagements.' + '\n' + displayContact);                
            } else if(status != 'Registration Confirmed') {
                email.setSubject('Cancellation Update - NCMi Utility CSV - US');
                email.setPlainTextBody('Attached are the scheduled NCMi Utility CSV - US Engagements.');               
            }
        } else if(country == 'Canada') {
            if(status == 'Registration Confirmed') {
                email.setSubject('Registration Update - NCMi Utility CSV - CA');
            	email.setPlainTextBody('Attached are the scheduled NCMi Utility CSV - Canada Engagements.'+ '\n' + displayContact);       
            } else if(status != 'Registration Confirmed') {
                email.setSubject('Cancellation Update - NCMi Utility CSV - CA');
            	email.setPlainTextBody('Attached are the scheduled NCMi Utility CSV - Canada Engagements.');       
            } 
        }         
        email.setToAddresses(toAddresses);  
        email.setFileAttachments(attachments);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }
    
}