// Derrick Chavez: SALES-977, 1915, 1903. Send out NCMi Institute Welcome Emails when Engagements and Attendees meet criteria. 
global with sharing class EngagementInstituteWelcomeEmailsBatch implements Database.Batchable<sObject>, Schedulable {

    private Boolean isScheduledRun = false;
    private Set<Id> engagementIds = new Set<Id>();

    // Constructor - used for Scheduled Run.
    public EngagementInstituteWelcomeEmailsBatch() {
       // this.engagementIds = engagementIds;
        this.isScheduledRun = true;
    }
    
    // Static method for trigger-based execution
    public static void runBatchFromTrigger(Set<Id> engagementIds) { 
        EngagementInstituteWelcomeEmailsBatch batch = new EngagementInstituteWelcomeEmailsBatch();
        batch.isScheduledRun = false;
        batch.engagementIds = engagementIds;
        Database.executeBatch(batch, 200);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {

        // run this query everyday at 10am. this is EXISTING functionality
        if(isScheduledRun) {
            Date fiveDaysAhead = Date.today().addDays(5); // need to get engagements that are have a start date five days from today. 
            System.debug('EngagementInstituteWelcomeEmailsBatch.start :: fiveDaysAhead: ' + fiveDaysAhead);
            
            return Database.getQueryLocator(
                            [SELECT Id,Status__c, RecordType.DeveloperName, Engagement_Start__c, Engagement_End__c, Course__r.Name, Engagement_Start_Date__c,
                                    Engagement_End_Date__c, Location_Times__c, Campus_Room__c, Class_Requirements__c, Travel_Lodging_Instructions__c, Name, Homework__c
                             FROM Engagement__c  
                             WHERE Status__c = 'Firm'
                             AND (RecordType.DeveloperName = 'Institute' OR RecordType.DeveloperName = 'Institute_Offsite')    
                             AND Engagement_Start_Date__c = :fiveDaysAhead    
                             Order By Engagement_Start_Date__c DESC  
                            ]);
        } else {
            // run this query from the trigger whenever the engagement and attendee meet criteria. CRITERIA IS CHECKED IN THE TRIGGER. NO NEED TO VALIDATE AGAIN
            return Database.getQueryLocator(
                [SELECT Id,Status__c, RecordType.DeveloperName, Engagement_Start__c, Engagement_End__c, Course__r.Name, Engagement_Start_Date__c,
                        Engagement_End_Date__c, Location_Times__c, Campus_Room__c, Class_Requirements__c, Travel_Lodging_Instructions__c, Name, Homework__c
                 FROM Engagement__c  
                 WHERE Id IN :engagementIds  
                 Order By Engagement_Start_Date__c DESC  
                ]);
        }
    } 

    global void execute(Database.BatchableContext BC, List<Engagement__c> engagements) {
        System.debug('EngagementInstituteWelcomeEmailsBatch.execute is running!');
        Set<Id> engagementIds = new Set<Id>();
        Map<Id, Engagement__c> engagementMap = new Map<Id, Engagement__c>(); 

        // loop through engagements, and get their Ids to use in a query to get their related attendees. 
        // build a map of enggements to pass into the sendEmail method. this will allow us to loop through the attendees and build the email body with the current engagement.
        for(Engagement__c eng :engagements) {
            engagementIds.add(eng.Id);
            engagementMap.put(eng.Id, eng);
        }

        List<Engagement_Attendee__c> attendees = [SELECT Id, Attendance_Status__c, contact__r.name, Contact_Email__c, Engagement__c, Welcome_Email_Sent__c
                                                  FROM Engagement_Attendee__c
                                                  WHERE Engagement__c IN :engagementIds
                                                  AND Attendance_Status__c = 'Registration Confirmed'
                                                  AND Contact_Email__c != NULL
                                                  AND Welcome_Email_Sent__c = null];
        
        System.debug('EngagementInstituteWelcomeEmailsBatch.execute :: attendees: ' + attendees);
        System.debug('EngagementInstituteWelcomeEmailsBatch.execute :: engagementMap: ' + engagementMap);
        sendWelcomeEmailBatch(attendees, engagementMap);
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('EngagementInstituteWelcomeEmailsBatch.finish is running!');
        /*
        String[] toAddresses = new String[]{'dchavez@ncmassociates.com'};
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            	email.setSubject('EngagementInstituteWelcomeEmailsBatch');
             	email.setPlainTextBody('EngagementInstituteWelcomeEmailsBatch has finished running!');
                email.setToAddresses(toAddresses); 
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});     
         */
        
    }

    private static void sendWelcomeEmailBatch(List<Engagement_Attendee__c> attendees, Map<Id, Engagement__c> engagementMap) {
        System.debug('EngagementInstituteWelcomeEmailsBatch.sendWelcomeEmailBatch is running!');
		Blob companyLogo = getEmailLogo();
        Blob welcomeLetter = getExistingPDF();
        Messaging.EmailFileAttachment pdfAttachment = new Messaging.EmailFileAttachment();
        Messaging.EmailFileAttachment logoAttachment = new Messaging.EmailFileAttachment();
                     
        if(welcomeLetter != null) {
            pdfAttachment.setFilename('NCM Welcome Letter.pdf');
            pdfAttachment.setBody(welcomeLetter);
            pdfAttachment.setContentType('application/pdf');
        }
        if(companyLogo != null) {     
            logoAttachment.setFilename('ncmLogo.png');
            logoAttachment.setBody(companyLogo);
            logoAttachment.setContentType('image/png');
            logoAttachment.setInline(true);
        }  
        
        // get Master NCMi Email custom label.
        String myLabelValue = System.Label.Master_NCMi_Email;
        List<String> ccAddresses = new List<String>();        
        for(String email :myLabelValue.split(',')) {
        	ccAddresses.add(email.trim());
        }
        
        // get OrgWideEmaiAddress for sender name (setReplyTo).
        OrgWideEmailAddress[] owea = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'ncmi@ncmassociates.com'];
        Id orgWideEmailId = (owea.size() > 0) ? owea[0].Id : null;
        System.debug('EngagementInstituteWelcomeEmailsBatch.sendWelcomeEmailBatch :: OrgWideEmailAddress :: ' + owea[0].Address);

        Map<Id, Engagement__c> engagementsToUpdate = new Map<Id, Engagement__c>();
        List<Engagement_Attendee__c> attendeesToUpdate = new List<Engagement_Attendee__c>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        // loop through each Attendee and get their Engagement. Depending on the Engagement Record Type is how the template will be created. Update the Attendee and Engagement Welcome Email Sent fields after emails are sent.
        for(Engagement_Attendee__c ea : attendees) {
            Engagement__c engagement = engagementMap.get(ea.Engagement__c); // retrieve the related engagement
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[]{ea.Contact_Email__c};
                
            if(engagement.RecordType.DeveloperName == 'Institute') {
                email.setSubject('Welcome to Kansas City! - Important Class Information for your Upcoming Training'); // Onsite
                email.setHtmlBody(createOnsiteTemplate(engagement, ea.contact__r.name));
                email.setFileAttachments(new Messaging.EmailFileAttachment[]{pdfAttachment, logoAttachment}); // setFileAttachments only holds a list
            } else {
                email.setSubject('Welcome to the NCM Institute! - Important Class Information for your Upcoming Training'); // Offsite
                email.setHtmlBody(createOffsiteTemplate(engagement, ea.contact__r.name));
                email.setFileAttachments(new Messaging.EmailFileAttachment[]{logoAttachment}); 
            }                 
            email.setReplyTo('ncmi@ncmassociates.com'); 
            email.setCcAddresses(ccAddresses);
            email.setToAddresses(toAddresses);
            if(orgWideEmailId != null) {
                email.setOrgWideEmailAddressId(orgWideEmailId);
            }            
            emails.add(email);
            
            ea.Welcome_Email_Sent__c = DateTime.now();
            attendeesToUpdate.add(ea);
            engagement.Welcome_Email_Sent__c = DateTime.now();
            engagementsToUpdate.put(engagement.Id, engagement);                

        }

        try {            
            Messaging.sendEmail(emails);  
            update(attendeesToUpdate);        
            update(engagementsToUpdate.values());      
        } catch(Exception ex) {            
            System.debug('EngagementInstituteWelcomeEmailsBatch.sendWelcomeEmailBatch method has Exception:: ' + ex.getMessage());
            Logger.logError('EngagementInstituteWelcomeEmailsBatch', 'Error', UserInfo.getUserName(), 'Error occurred in the sendWelcomeEmailBatch method.', ex.getMessage(), ex.getStackTraceString());            
        }
     
    }

    // this is a File I created under the Libary - 'NCMi Institute Welcome Email'. I granted the All Internal User Public Group. For this to work properly the title must match and the triggering User must have access to the File.
    // the batch will cause an error if nothing is returned or someone doesn't have access.  
    private static Blob getExistingPDF() {
        try {
            ContentVersion welcomeLetter = [SELECT title, VersionData FROM ContentVersion WHERE title = 'NCM Welcome Letter 3 7 23' Order By createdDate DESC LIMIT 1];
            return welcomeLetter.VersionData;
        } catch(Exception ex) {
            System.debug('EngagementInstituteWelcomeEmailsBatch.getExistingPDF :: caught an exception. ' + ex.getMessage());  
            return null;
        }
    }

    // this is a File I created under the Libary - 'NCMi Institute Welcome Email'. I granted the All Internal User Public Group. For this to work properly the title must match and the triggering User must have access to the File.
    // the batch will cause an error if nothing is returned or someone doesn't have access.
    private static Blob getEmailLogo() {
        try {
            ContentVersion ncmLogo = [SELECT title, VersionData FROM ContentVersion WHERE title = 'NCM_Email_Logo' Order By createdDate DESC LIMIT 1];
            return ncmLogo.VersionData;
        } catch(Exception ex) {
            System.debug('EngagementInstituteWelcomeEmailsBatch.getExistingPDF :: caught an exception. ' + ex.getMessage());  
            return null;
        }
    }

    private static String createOnsiteTemplate(Engagement__c engagement, String contactName) {
        String cleanedStartDate = engagement.Engagement_Start__c.format('M.d.yyyy');
        String cleanedEndDate = engagement.Engagement_End__c.format('M.d.yyyy');    
        String cleanedLocationTimes = cleanRichTextField(engagement.Location_Times__c);
        String cleanedClassRequirements = cleanRichTextField(engagement.Class_Requirements__c);
        String cleanedHomework = cleanRichTextField(engagement.Homework__c);
        String cleanedTravelLodging = cleanRichTextField(engagement.Travel_Lodging_Instructions__c);
    
        String htmlBody = '<html><body style="font-family: Arial; font-size: 9pt; margin: 0; padding: 0;">';    
        // outer table
        htmlBody += '<table role="presentation" style="max-width: 800px; width: auto; border-collapse: collapse; margin: 0 auto;" cellpadding="0" cellspacing="0">';
        htmlBody += '<tr><td align="center">';    
        // inner table
        htmlBody += '<table role="presentation" style="max-width: 800px; width: auto; font-family: Arial; font-size: 9pt;" cellpadding="0" cellspacing="0">';
        htmlBody += '<tr><td style="word-wrap: break-word;">';    
        // email content
        htmlBody += '<img src="cid:ncmLogo.png" alt="Company Logo" width="150"><br>';
        htmlBody += '<p>Dear ' + contactName + ',</p>';
        htmlBody += '<p>On behalf of all of us at the NCM Institute, thank you for joining us!</p>';
        htmlBody += '<p style="font-size: 10pt; color: red">' + engagement.Course__r.Name + ' will start on ' + cleanedStartDate + ' and will end on ' + cleanedEndDate + '.</p>';
        htmlBody += '<p>Important details about the NCM Institute, your class, and the hotel used by NCM Travel Solutions are included here.</p>';
    
        htmlBody += '<h3 style="font-size: 15pt; color: #000066;"><b>Location & Schedule</b></h3>';
        htmlBody += '<p>Your classroom location is <b><font color="red">' + engagement.Campus_Room__c + '</font></b>.</p>';
        htmlBody += '<p>' + cleanedLocationTimes + '</p>';
    
        htmlBody += '<h3 style="font-size: 15pt; color: #000066;"><b>Class Requirements</b></h3>';
        htmlBody += '<p>' + cleanedClassRequirements + '</p>';
    
        htmlBody += '<h3 style="font-size: 15pt; color: #000066;"><b>Homework</b></h3>';
        htmlBody += '<p>' + cleanedHomework + '</p>';
    
        htmlBody += '<h3 style="font-size: 15pt; color: #000066;"><b>Travel & Lodging Instructions</b></h3>';
        htmlBody += '<p>' + cleanedTravelLodging + '</p>';
    
        htmlBody += '<h3 style="font-size: 15pt; color: #000066;"><b>Parking Details</b></h3>';
        htmlBody += '<p><b>Main Parking Lot:</b></p>';
        htmlBody += '<ul>';
        htmlBody += '<li>Turn onto <b>Grand Avenue</b>.</li>';
        htmlBody += '<li>Parking is available in the <b>middle two rows</b> of the lot, outlined in <b>white</b>.</li>';
        htmlBody += '<li><b>Do not park</b> in:</li>';
        htmlBody += '<ul>';
        htmlBody += '<li>Stalls marked for <b>Grand Street Cafe</b></li>';
        htmlBody += '<li><b>1-hour parking</b> spots (These are outlined in <b>red</b>.)</li>';
        htmlBody += '</ul></ul>';
    
        htmlBody += '<p><b>If No Parking is Available:</b></p>';
        htmlBody += '<ul><li>See an <b>NCMi staff member</b> on the 4th Floor to get a <b>QR code</b> for the parking garage.</li></ul>';
    
        htmlBody += '<p><b>Parking Garage Directions:</b></p>';
        htmlBody += '<ul>';
        htmlBody += '<li>From Grand Avenue, turn right onto McGee Street (the next right after the main lot).</li>';
        htmlBody += '<li>This will take you to the <b>parking garage</b>.</li>';
        htmlBody += '<li>Park on <b>Lower Level A</b>.</li>';
        htmlBody += '<li>Take the <b>elevator to Level 1</b>.</li>';
        htmlBody += '<li><b>Do not park</b> in any <b>reserved spots</b>.</li>';
        htmlBody += '</ul>';
    
        htmlBody += '<p>Please let us know if you have any additional questions. We look forward to having you in class with us!</p>';
        htmlBody += '<p>Thank you again, and safe travels.</p>';

        htmlBody += 'NCM Institute<br>';
        htmlBody += '<b>NCM Associates, Inc.</b><br>';
        htmlBody += 'Office: 866.756.2620<br>';
        htmlBody += 'Fax: 913.273.1227<br>';
        htmlBody += 'ncmi@ncmassociates.com<br><br>';
    
        htmlBody += '<p><a href="https://go.ncmassociates.com/Data-Privacy-Policy.html" target="_blank">NCM Associates Data Privacy Policy</a></p>';
        // close tables
        htmlBody += '</td></tr></table></td></tr></table>';
        htmlBody += '</body></html>';
    
        return htmlBody;
	}

    private static String createOffsiteTemplate(Engagement__c engagement, String contactName) {        
		String cleanedStartDate = engagement.Engagement_Start__c.format('M.d.yyyy');
        String cleanedEndDate = engagement.Engagement_End__c.format('M.d.yyyy');
        String cleanedLocationTimes = cleanRichTextField(engagement.Location_Times__c);
        String cleanedClassRequirements = cleanRichTextField(engagement.Class_Requirements__c);
        String cleanedHomework = cleanRichTextField(engagement.Homework__c);
        String cleanedTravelLodging = cleanRichTextField(engagement.Travel_Lodging_Instructions__c);
        
        String htmlBody = '<html><body style="font-family: Arial; font-size: 9pt; margin: 0; padding: 0;">';    
        // outer table
        htmlBody += '<table role="presentation" style="max-width: 800px; width: auto; border-collapse: collapse; margin: 0 auto;" cellpadding="0" cellspacing="0">';
        htmlBody += '<tr><td align="center">';    
        // inner  table
        htmlBody += '<table role="presentation" style="max-width: 800px; width: auto; font-family: Arial; font-size: 9pt;" cellpadding="0" cellspacing="0">';
        htmlBody += '<tr><td style="word-wrap: break-word;">';    
        // email content
        htmlBody += '<img src="cid:ncmLogo.png" alt="Company Logo" width="150"><br>'; // this is needed along with creating attachment to embed a logo. 
        htmlBody += '<p>Dear ' + contactName + ',</p>';        
        htmlBody += '<p>On behalf of all of us at the NCM Institute, thank you for joining us!</p>';
        htmlBody += '<p style="font-size: 10pt; color: red">' + engagement.Course__r.Name + ' will start on ' + cleanedStartDate + ' and will end on ' + cleanedEndDate + '.</p>';
        htmlBody += '<p>Important details about the NCM Institute, your class, and the hotel used by NCM Travel Solutions are included here.</p><p></p>';
        
        htmlBody += '<h3 style="font-size: 15pt; color: #000066;"><b>Location & Schedule</b></h3>';         
        htmlBody += '<p>' + cleanedLocationTimes + '</p>';
        
        htmlBody += '<h3 style="font-size: 15pt; color: #000066;"><b>Class Requirements</b></h3>';  
        htmlBody += '<p>' + cleanedClassRequirements + '</p>';
        
        htmlBody += '<h3 style="font-size: 15pt; color: #000066;"><b>Homework</b></h3>'; 
        htmlBody += '<p>' + cleanedHomework + '</p>';
        
        htmlBody += '<h3 style="font-size: 15pt; color: #000066;"><b>Travel & Lodging Instructions</b></h3>'; 
        htmlBody += '<p>' + cleanedTravelLodging + '</p><br>';     
        
        htmlBody += 'NCM Institute<br>';
        htmlBody += '<b>NCM Associates, Inc.</b><br>';
        htmlBody += 'Office: 866.756.2620<br>';
        htmlBody += 'Fax: 913.273.1227<br>';
        htmlBody += 'ncmi@ncmassociates.com<br><br>';

        htmlBody += '<p><a href="https://go.ncmassociates.com/Data-Privacy-Policy.html" target="_blank">NCM Associates Data Privacy Policy</a></p>';
        // close tables
        htmlBody += '</td></tr></table></td></tr></table>';
        htmlBody += '</body></html>';
        
        return htmlBody;
    }
      
    private static String cleanRichTextField(String value) {        
        if (value == null) return '';
    
        String cleanedText = value;    
        // remove soft hyphens
        cleanedText = cleanedText.replaceAll('&shy;', '');
        cleanedText = cleanedText.replaceAll('\u00AD', '');
        // remove layout tags, keep line breaks
        cleanedText = cleanedText.replaceAll('(?i)<div[^>]*>', '');
        cleanedText = cleanedText.replaceAll('(?i)</div>', '<br>');
        cleanedText = cleanedText.replaceAll('(?i)<p[^>]*>', '');
        cleanedText = cleanedText.replaceAll('(?i)</p>', '<br>');
        // replace non-breaking spaces
        cleanedText = cleanedText.replaceAll('&nbsp;', ' ');
        // trim extra line breaks
        cleanedText = cleanedText.replaceAll('(<br>\\s*){2,}', '<br><br>');    
        
        return cleanedText;
	}
    
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new EngagementInstituteWelcomeEmailsBatch(), 200);
    }

}