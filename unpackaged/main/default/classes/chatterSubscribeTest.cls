@isTest (SeeAllData=true)
public class chatterSubscribeTest {
    static testMethod void TestchatterSubscribe(){
        Opportunity opp = [select id from Opportunity limit 1];
        
        Test.startTest();
        
        chatterSubscribe.vars var = new chatterSubscribe.vars();
        var.userId = [select id from User where name like 'Stephen Clark'].id;
        var.recId = opp.id;
        
        List<chatterSubscribe.vars> vars = new List<chatterSubscribe.vars>();
        vars.add(var);
        
        try{
            chatterSubscribe.addSub(vars);
        } catch(Exception er){
            system.debug(er);
        }
        try{
            chatterSubscribe.addSub(vars);
        } catch(Exception er){
            system.debug(er);
        }
        Test.stopTest();
    }
}