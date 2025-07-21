@isTest
private class ActivityParticipationUtility_Test {

    @testSetup
    static void makeData() {
        Account acct = new Account(Name = 'Test');
        insert(acct);
        Contact con = new Contact(LastName = 'Test', FirstName = 'Test', AccountId = acct.Id);
        insert(con);
        Engagement__c eng = new Engagement__c(Name = 'Test Eng');
        insert(eng);
        Engagement_Attendee__c ea = new Engagement_Attendee__c(Name = 'test', Engagement__c = eng.Id,
        Contact__c = con.Id);
        insert ea;
        Id meetingRTId = Schema.SObjectType.Engagement_Activity__c.getRecordTypeInfosByName().get('Meeting').getRecordTypeId();
        Id receptionRTId = Schema.SObjectType.Engagement_Activity__c.getRecordTypeInfosByName().get('Reception').getRecordTypeId();
        Id activityRTId = Schema.SObjectType.Engagement_Activity__c.getRecordTypeInfosByName().get('Engagement Activity').getRecordTypeId();
        Engagement_Activity__c act1 = new Engagement_Activity__c(Name = 'test', Engagement__c = eng.Id, RecordTypeId = meetingRTId);
        Engagement_Activity__c act2 = new Engagement_Activity__c(Name = 'test', Engagement__c = eng.Id, RecordTypeId = meetingRTId);
        Engagement_Activity__c act3 = new Engagement_Activity__c(Name = 'test', Engagement__c = eng.Id, RecordTypeId = receptionRTId);
        Engagement_Activity__c act4 = new Engagement_Activity__c(Name = 'test', Engagement__c = eng.Id, RecordTypeId = activityRTId);
        insert(new List<Engagement_Activity__c>{act1, act2, act3, act4}); 
        
    }

    @isTest
    static void testSinglePositive() {
        Engagement_Attendee__c ea = [SELECT Id FROM Engagement_Attendee__c LIMIT 1];
        List<Engagement_Activity__c> acts = [SELECT Id FROM Engagement_Activity__c];
        Test.startTest();
        insert(new Activity_Participation__c(Engagement_Attendee__c = ea.Id, Engagement_Activity__c = acts[0].Id));
        Test.stopTest();
        Engagement_Attendee__c ea1 = [SELECT Id, In_Meeting_Room__c FROM Engagement_Attendee__c WHERE Id = :ea.Id];
        Assert.isTrue(ea1.In_Meeting_Room__c);
    }

    @isTest
    static void testSingleNegative() {
        Engagement_Attendee__c ea = [SELECT Id FROM Engagement_Attendee__c LIMIT 1];
        List<Engagement_Activity__c> acts = [SELECT Id FROM Engagement_Activity__c];
        Test.startTest();
        Activity_Participation__c ap = new Activity_Participation__c(Engagement_Attendee__c = ea.Id, Engagement_Activity__c = acts[0].Id);
        insert(ap);
        delete(ap);
        Test.stopTest();
        Engagement_Attendee__c ea1 = [SELECT Id, In_Meeting_Room__c FROM Engagement_Attendee__c WHERE Id = :ea.Id];
        Assert.isFalse(ea1.In_Meeting_Room__c);
    }

    @isTest
    static void testEditPositive() {
        Engagement_Attendee__c ea = [SELECT Id FROM Engagement_Attendee__c LIMIT 1];
        List<Engagement_Activity__c> acts = [SELECT Id FROM Engagement_Activity__c];
        Test.startTest();
        Activity_Participation__c ap = new Activity_Participation__c(Engagement_Attendee__c = ea.Id, Engagement_Activity__c = acts[0].Id);
        insert(ap);
        ap.Total_Number_of_Participants__c = 2;
        update(ap);
        Test.stopTest();
        Engagement_Attendee__c ea1 = [SELECT Id, In_Meeting_Room__c FROM Engagement_Attendee__c WHERE Id = :ea.Id];
        Assert.isTrue(ea1.In_Meeting_Room__c);
    }
}