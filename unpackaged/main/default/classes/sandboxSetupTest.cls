@isTest
class sandboxSetupTest {
    @isTest
    static void testMySandboxPrep() {
        test.startTest();
        
        list<Account> accs = [select id from Account where name = 'NCM Associates'];
        if (accs.size() > 0){
            try{
                delete accs;
            } catch (exception er){
                system.debug(er);
            }
        }
        
        list<User> usrs = [select id, NCM_Associates_Contact_ID__c, Email
                           from User 
                           where isActive = true and Profile.Name = 'System Administrator'];
        
        list<id> conIds = new list<id>();
        for (User usr : usrs){
            usr.email = usr.email + '.invalid';
            conIds.add(usr.NCM_Associates_Contact_ID__c);
        }
        
        try{
            update usrs;
        } catch (exception er){
            system.debug(er);
        }
        
        list<contact> cons = [select id from Contact where id in :conIds];
        if (cons.size() > 0){
            try{
                delete cons;
            } catch (exception er){
                system.debug(er);
            }
        }
        
        test.testSandboxPostCopyScript(new sandboxSetup(), UserInfo.getOrganizationId(), UserInfo.getOrganizationId(), UserInfo.getOrganizationName());
        
        test.stopTest();
    }
}