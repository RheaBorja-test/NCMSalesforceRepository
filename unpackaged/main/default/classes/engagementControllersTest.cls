@isTest (SeeAllData=true)
public class engagementControllersTest {

    static testMethod void testGetRooms() {
        
        Test.startTest();
        
        List<engagementControllers.vars> vars = new List<engagementControllers.vars>();
        engagementControllers.vars var = new engagementControllers.vars();
        var.memCnt = 10;

        id usrConId = [select id, NCM_Associates_Contact_ID__c from User where id = :UserInfo.getUserId()].NCM_Associates_Contact_ID__c;
        Engagement__c eng = createEngagement(usrConId);
        var.eng = eng;
        vars.add(var);

        list<list<Room__c>> roomsRet = new list<list<Room__c>>();
        try{
            roomsRet = engagementControllers.getRooms(vars);
        } catch(exception er){
            system.debug(er);
        }

        list<Room__c> rms = roomsRet.get(0);

        try{
            engagementControllers.updateRooms(rms);
        } catch(exception er){
            system.debug(er);
        }

        try{
            rms = engagementControllers.getRoomsForEngagement(eng.id);
        } catch(exception er){
            system.debug(er);
        }

        Test.stopTest();

    }

    static testMethod void testGetAttendeeActivityParticipation() {

        Test.startTest();

        id usrConId = [select id, NCM_Associates_Contact_ID__c from User where id = :UserInfo.getUserId()].NCM_Associates_Contact_ID__c;
        id ncmAccId = [select id from Account where name = 'NCM Associates'].id;

        Engagement__c eng = createEngagement(usrConId);
        Engagement_Activity__c act = createActivity(eng.id);
        Engagement_Attendee__c att = createAttendee(eng.id, usrConId, ncmAccId);

        engagementControllers.getActivityParticipation(act.id);
        list<Activity_Participation__c> ptcs = engagementControllers.getAttendeeParticipation(att.id);

        for (Activity_Participation__c ptc : ptcs){
            ptc.Total_Number_of_Participants__c = 2;
        }

        engagementControllers.upsertParticipation(ptcs);

        Test.stopTest();

    }

    private static Engagement__c createEngagement(id usrConId){
        Engagement__c eng = new Engagement__c();
        eng.Engagement_Owner__c = usrConId;
        
        eng.Rooms_From__c = date.today();
        eng.Rooms_To__c = date.today().addDays(7);
        
        eng.Engagement_Start__c = Datetime.now().addDays(1);
        eng.Engagement_End__c = datetime.now().addDays(4);

        eng.NCM_Arrival__c = date.today();
        eng.NCM_Departure__c = date.today().addDays(5);

        insert eng;
        return eng;
    }

    private static Engagement_Activity__c createActivity(id engId){
        Engagement_Activity__c act = new Engagement_Activity__c();

        act.Engagement__c = engId;
        act.Name = 'Test Activity';
        act.Start__c = datetime.now();
        act.End_Time__c = datetime.now().addHours(1);
        act.Description__c = 'Created during Test Run';

        insert act;
        return act;
    }

    private static Engagement_Attendee__c createAttendee(id engId, id usrConId, id ncmAccId){
        Engagement_Attendee__c att = new Engagement_Attendee__c();

        att.Contact__c = usrConId;
        att.Account__c = ncmAccId;
        att.Name = 'Test Attendee';
        att.Engagement__c = engId;
        att.Arrival__c = Datetime.now();
        att.Departure__c = datetime.now().addHours(1);

        insert att;
        return att;
    }

}