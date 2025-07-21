@isTest
public class EngagementEndCandidateApprovalTask_Tests {
    
    @TestSetup
    static void makeData(){

        SampleDataFactory.create20GroupAccountData();
                
        // Query for the Twenty Group created by SampleDataFactory.
        Twenty_Groups__c test20Group = [SELECT Id, Name, NCM_Proprietor__c FROM Twenty_Groups__c LIMIT 1];
        Id twentyGroupId = test20Group.Id;

        // Query for the record that was created on  line 8 for the Billing NCM Billing Contact Id.
        Id ncmBillingContactId = test20Group.NCM_Proprietor__c;

        // Get the Engagement Record Type for Retail Solutions.
        Id engagementRecTypeId = Schema.SObjectType.Engagement__c.getRecordTypeInfosByName().get('Retail Solutions').getRecordTypeId();
        
        // Call the method from SampleDataFactory and pass in values created above. 
        SampleDataFactory.createEngagement_20G(twentyGroupId, engagementRecTypeId, ncmBillingContactId); 

        Engagement__c testEngagement = [select id, Name, Engagement_End_Date__c, Engagement_Owner__c from Engagement__c order by CreatedDate DESC LIMIT 1];

        // Add some Candidates to the Engagement
        Account candidateAcct = new Account(
            Name = 'Sample Porsche of Plainville',
            BillingStreet = '111 Main St', 
            BillingCity = 'Metroville', 
            BillingStateCode = 'NC', 
            BillingPostalCode = '27554'
        );
        insert(candidateAcct);

        Contact candContact = new Contact(
            AccountId = candidateAcct.Id, 
            FirstName = 'Bob', 
            LastName = 'Jones', 
            Email = 'bob.jones@noemail.com',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId(),
            MailingStreet = '4717 Grand Ave., Ste 500',
            MailingCity = 'Kansas City',
            MailingState = 'Missouri',
            MailingPostalCode = '64112'
        );
        insert(candContact);

        X20_Groups_Member__c candidateMember = new X20_Groups_Member__c(
            Group_ID__c = twentyGroupId,
            Account__c = candidateAcct.Id,
            Member_Number__c = 4,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addYears(3),
            Type__c = 'Candidate',
            Status__c = 'Submitted'
        );
        insert(candidateMember);

        X20_Group_Member_Contact__c candMemContact = new X20_Group_Member_Contact__c(
            X20_Group__c = twentyGroupId,
            X20_Groups_Member__c = candidateMember.Id,
            Contact__c = candContact.Id,
            Member_Email__c = candContact.Email,
            Contact_Active_Date__c = Date.today(),
            Contact_Status__c = 'Active',
            Contact_Type__c = 'Member'
        );
        insert(candMemContact);

        Engagement_Attendee__c candidateAtt = new Engagement_Attendee__c(
            Contact__c = candContact.Id,
            Account__c = candidateAcct.Id,
            X20_Groups_Member__c = candidateMember.Id,
            Name = candContact.Name,
            Engagement__c = testEngagement.Id,
            Arrival__c = Datetime.now().addDays(30),
            Departure__c = Datetime.now().addDays(34),
            Attendance_Status__c = 'Confirmed',
            Attendee_Type__c = 'Member',
            Attendee_Notes__c = 'Test'
        );
        insert(candidateAtt);

    }


    @isTest
    static void test1(){

        List<Engagement_Attendee__c> attList = [select id, name,X20_Groups_Member__r.Name, Attendance_Status__c, Engagement__r.Name from Engagement_Attendee__c];
        for(Engagement_Attendee__c att:attList){
            System.debug('Attendee: ' + att.Name + ' - ' + att.X20_Groups_Member__r.Name + ' - ' + att.Engagement__r.Name);
        }
        
        Engagement__c testEng = [select id, name, Engagement_Owner__c, Engagement_End_Date__c from Engagement__c limit 1];
        List<List<Engagement__c>> inputList = new List<List<Engagement__c>>();
        List<Engagement__c> engList = new List<Engagement__c>();
        engList.add(testEng);
        inputList.add(engList);
         
        // Get the 20 Group moderator user
        
        
        Test.startTest();
            EngagementEndCandidateApprovalTask.createCandidateApprovalTasks(inputList);
        Test.stopTest();

        List<Task> taskResults = [select id, whoId, whatId from Task];// where createddate = TODAY];
        Assert.areEqual(2,taskResults.size());

    }

}