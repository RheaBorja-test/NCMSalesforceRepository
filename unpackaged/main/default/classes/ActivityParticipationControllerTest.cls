@isTest
public class ActivityParticipationControllerTest {

    @IsTest
    static void getActivitiesTest(){
        
        String acctRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NCM Client').getRecordTypeId();
        String contactRecType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId();

        Account acct = new Account(
            RecordTypeId = acctRecType,
            Name = 'Sample Auto Group',
            BillingStreet = '1 Auto Way',
            BillingCity = 'Sampleton',
            BillingState = 'North Carolina',
            BillingPostalCode = '28461',
            BillingCountry = 'United States',
            AccountSource = 'Marketing',        // required
            Industry = 'Auto Retail New',       // required
            Franchise_s__c = 'Chevrolet;Dodge;Ford;Jeep'

        );
        insert(acct);
        
        // Contact
        Contact con = new Contact(
                RecordTypeId = contactRecType,
                FirstName = 'Marv',
                LastName = 'Sampleton',
                AccountId = acct.Id,
                Email = 'marv.sampleton@ncmassociates.com',
                MailingStreet = '100 Automotive Way',
                MailingCity = 'Southport',
                MailingState = 'North Carolina',
                MailingPostalCode = '28461'
        );
        insert con;
              
        Engagement__c eng = new Engagement__c(Name = 'Test Engagament');
        insert eng;
        System.debug('~~~engagement inserted');
        Engagement_Activity__c act = new Engagement_Activity__c(Name = 'Test Activity', Engagement__c = eng.Id);
        insert act;
        System.debug('~~~activity inserted');
        Engagement_Attendee__c attendee = new Engagement_Attendee__c(Contact__c = con.Id, Engagement__c = eng.Id);
        insert attendee;
        System.debug('~~~engagement Attendee inserted');
        Activity_Participation__c ap = new Activity_Participation__c(Engagement_Activity__c = act.Id, 
                                                                    Engagement_Attendee__c = attendee.Id,
                                                                    Total_Number_of_Participants__c = 1);
        insert ap;
        List<ActivityParticipationController.Act> acts = ActivityParticipationController.getActivities(attendee.Id);
        System.debug('~~~acts: ' + acts);
        Assert.isTrue(acts[0].Bool);
    }

    @IsTest
    static void makeActivityParticipationTest() {
        
        String acctRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NCM Client').getRecordTypeId();
        String contactRecType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId();

        Account acct = new Account(
            RecordTypeId = acctRecType,
            Name = 'Sample Auto Group',
            BillingStreet = '1 Auto Way',
            BillingCity = 'Sampleton',
            BillingState = 'North Carolina',
            BillingPostalCode = '28461',
            BillingCountry = 'United States',
            AccountSource = 'Marketing',        // required
            Industry = 'Auto Retail New',       // required
            Franchise_s__c = 'Chevrolet;Dodge;Ford;Jeep'

        );
        insert(acct);
        
        // Contact
        Contact con = new Contact(
                RecordTypeId = contactRecType,
                FirstName = 'Marv',
                LastName = 'Sampleton',
                AccountId = acct.Id,
                Email = 'marv.sampleton@ncmassociates.com',
                MailingStreet = '100 Automotive Way',
                MailingCity = 'Southport',
                MailingState = 'North Carolina',
                MailingPostalCode = '28461'
        );
        insert con;
        
        Engagement__c eng = new Engagement__c(Name = 'Test Engagament');
        insert eng;
        System.debug('~~~engagement inserted');
        Engagement_Activity__c act = new Engagement_Activity__c(Name = 'Test Activity', Engagement__c = eng.Id);
        insert act;
        System.debug('~~~activity inserted');
        Engagement_Attendee__c attendee = new Engagement_Attendee__c(Contact__c = con.Id, Engagement__c = eng.Id);
        insert attendee;
        System.debug('~~~engagement Attendee inserted');
        
        ActivityParticipationController.makeActivityParticipation(attendee.Id, act.Id);

        List<Activity_Participation__c> aps = [SELECT Id 
                                        FROM Activity_Participation__c 
                                        WHERE Engagement_Activity__c = :act.ID 
                                        AND Engagement_Attendee__c = :attendee.Id];
        Assert.areEqual(1, aps.size());
        
    }

    @IsTest
    static void deleteActivityParticipationTest(){

        String acctRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NCM Client').getRecordTypeId();
        String contactRecType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId();

        Account acct = new Account(
            RecordTypeId = acctRecType,
            Name = 'Sample Auto Group',
            BillingStreet = '1 Auto Way',
            BillingCity = 'Sampleton',
            BillingState = 'North Carolina',
            BillingPostalCode = '28461',
            BillingCountry = 'United States',
            AccountSource = 'Marketing',        // required
            Industry = 'Auto Retail New',       // required
            Franchise_s__c = 'Chevrolet;Dodge;Ford;Jeep'

        );
        insert(acct);
        
        Contact con = new Contact(
                RecordTypeId = contactRecType,
                FirstName = 'Marv',
                LastName = 'Sampleton',
                AccountId = acct.Id,
                Email = 'marv.sampleton@ncmassociates.com',
                MailingStreet = '100 Automotive Way',
                MailingCity = 'Southport',
                MailingState = 'North Carolina',
                MailingPostalCode = '28461'
        );
        insert con;

        Engagement__c eng = new Engagement__c(Name = 'Test Engagament');
        insert eng;
        System.debug('~~~engagement inserted');
        Engagement_Activity__c act = new Engagement_Activity__c(Name = 'Test Activity', Engagement__c = eng.Id);
        insert act;
        System.debug('~~~activity inserted');
        Engagement_Attendee__c attendee = new Engagement_Attendee__c(Contact__c = con.Id, Engagement__c = eng.Id);
        insert attendee;
        System.debug('~~~engagement Attendee inserted');
        Activity_Participation__c ap = new Activity_Participation__c(Engagement_Activity__c = act.Id, Engagement_Attendee__c = attendee.Id);
              
        ActivityParticipationController.deleteActivityParticipation(attendee.Id, act.Id);
        
        List<Activity_Participation__c> aps = [SELECT Id 
                                        FROM Activity_Participation__c 
                                        WHERE Engagement_Activity__c = :act.ID 
                                        AND Engagement_Attendee__c = :attendee.Id];
        Assert.areEqual(0, aps.size());
        
    }

}