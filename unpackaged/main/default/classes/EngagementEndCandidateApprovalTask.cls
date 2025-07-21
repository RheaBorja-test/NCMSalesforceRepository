public with sharing class EngagementEndCandidateApprovalTask {

    @InvocableMethod(label='Generate Candidate Approval Tasks' description='For any 20G Candidates in the meeting, create an approval task for the group owner.' category='Engagement')
    public static void createCandidateApprovalTasks( List<List<Engagement__c>> engagementList) {

        final String logTag = '[createCandidateApprovalTasks]';
        Engagement__c eng = engagementList[0][0];
        System.debug(logTag + 'Engagement: ' + eng.Name + ' - ' + eng.Engagement_End_Date__c);

        Set<Id> memberIdSet = new Set<Id>();
        for(Engagement_Attendee__c att : [select id, X20_Groups_Member__c from Engagement_Attendee__c WHERE Engagement__c = :eng.Id AND Attendance_Status__c = 'Confirmed' AND X20_Groups_Member__r.Type__c = 'Candidate']){
            memberIdSet.add(att.X20_Groups_Member__c);
        }
        System.debug(logTag + 'There are ' + memberIdSet.size() + ' confirmed candidate attendee members for this engagement (' + eng.Id + ').');

        List<X20_Groups_Member__c> twentyGroupMembers = [SELECT 
                                                    Id, 
                                                    Name, 
                                                    Group_ID__c,
                                                    Group_ID__r.Name,
                                                    Group_Id__r.NCM_Proprietor__c,
                                                    Group_Id__r.NCM_Proprietor__r.Email,
                                                    Group_Id__r.NCM_Proprietor__r.User_Id__c
                                                   FROM X20_Groups_Member__c 
                                                   WHERE Id IN :memberIdSet];

        
        if(!twentyGroupMembers.isEmpty()){
            System.debug(logTag + 'There are ' + twentyGroupMembers.size() + ' 20 Group Member candidates to process for Engagement ' + eng.Id);
            String candApprRecType = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Candidate Approval').getRecordTypeId();
            List<Task> newTasks = new List<Task>();
            Map<Id,X20_Groups_Member__c> memberMap = new Map<Id,X20_Groups_Member__c>();

            for(X20_Groups_Member__c grpMember:twentyGroupMembers){
                
                memberMap.put(grpMember.Id, grpMember);

                Task newTask = new Task(
                    RecordTypeId = candApprRecType,
                    WhatId = grpMember.Id,
                    WhoId = grpMember.Group_Id__r.NCM_Proprietor__c, //eng.Engagement_Owner__c,
                    OwnerId = grpMember.Group_Id__r.NCM_Proprietor__r.User_Id__c,
                    Subject = 'Moderator Candidate Approval/Rejection: ' + grpMember.Name,
                    ActivityDate = eng.Engagement_End_Date__c.addDays(2),
                    X20_Group__c = grpMember.Group_ID__c,
                    Group_Number__c = grpMember.Group_ID__r.Name,
                    Membership_20G__c = grpMember.Id,
                    Engagement__c = eng.Id
                );
                newTasks.add(newTask);
                

            }

            

            if(!newTasks.isEmpty()){
                System.debug(logTag + 'Creating ' + newTasks.size() + ' new Task records.');
                Database.SaveResult[] lsr = Database.insert(newTasks, false);
                List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
            
                Integer i = 0;
                for(Database.SaveResult sr:lsr){
                    Task t = newTasks[i];

                    if(!sr.isSuccess()){
                        // Error inserting task.
                        System.debug(logTag + 'There was a problem inserting the new Task record for ' + t.WhatId + '. Reason: ' + sr.getErrors()[0].getMessage());
                    } else {
                        System.debug(logTag + 'Task created for member ' + t.Membership_20G__c + ' for (whoId) ' + t.whoId + ', (ownerId) ' + t.OwnerId);
                
                        X20_Groups_Member__c memberInfo = memberMap.get(t.Membership_20G__c);
                        Messaging.SingleEmailMessage taskEmail = createTaskEmail(t, memberInfo);
                        emailsToSend.add(taskEmail);
                    }

                    i++;
                }


                if(!emailsToSend.isEmpty()){
                    System.debug(logTag + 'Sending ' + emailsToSend.size() + ' task notification emails..');
                    Messaging.sendEmail(emailsToSend);
                }


            } else {
                System.debug(logTag + 'No new tasks will be inserted.');
            }
        } else {
            System.debug(logTag + 'There are no 20 Group Member candidates to process for Engagement ' + eng.Id);
        }

    }


    private static Messaging.SingleEmailMessage createTaskEmail(Task tsk, X20_Groups_Member__c member){

        Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
		emailMsg.setToAddresses(new List<String>{tsk.whoId});
		emailMsg.setReplyTo('salesforceadmin@ncmassociates.com');
		emailMsg.setSenderDisplayName('NCM Task Assignment');
		emailMsg.setSubject('Candidate Approval Task Assigned for ' + tsk.Group_Number__c);

		String recordlink = URL.getOrgDomainUrl().toExternalForm() + '/' + tsk.Id;
        String body = '<p style="font-size:18px;color:blue;font-weight:bold;">New Task</p><p>' + 
                      '<b>20 Group Member Account: </b>' + member.Name + '<br/>' + 
                      '<b>Due Date: </b>' + tsk.ActivityDate + '<br/><br/>' + 
                      'For more details, click the following link:<br/><a href=\'' + recordlink + '\'>Approval Task for ' + tsk.Group_Number__c + '</a></p>';
		emailMsg.setHtmlBody(body);

        return emailMsg;

    }

    /*
    private static Messaging.SingleEmailMessage createTaskEmail(Task tsk, String modEmail, String candidateName, String groupName){

        Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
		emailMsg.setToAddresses(new List<String>{modEmail});
		emailMsg.setReplyTo('salesforceadmin@ncmassociates.com');
		emailMsg.setSenderDisplayName('Candidate Approval Task Assigned for ' + groupName);
		emailMsg.setSubject('Candidate Approval Task Assigned for ' + groupName);

		string body = 'A Candidate Approval Task has been created for you to approve or reject the following candidate: <br/>';
		body = body + 'Candidate: ' + candidateName;
		body = body + 'Task: ' + '/' + tsk.Id;
		emailMsg.setHtmlBody(body);

        return emailMsg;

    }
    */

}