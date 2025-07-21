@isTest (SeeAllData=true)
public class createHealthcheckInstancesTest {
    static testMethod void TestcreateHealthcheckInstances(){
        Opportunity opp = [select id from Opportunity limit 1];
        X20_Groups_Member__c mem = [select id, Group_ID__c from X20_Groups_Member__c where Status__c = 'Active' limit 1];
        
        createHealthcheckInstances.vars var = new createHealthcheckInstances.vars();
        var.grpId = mem.Group_ID__c;
        var.oppId = opp.id;
        
        List<createHealthcheckInstances.vars> vars = new List<createHealthcheckInstances.vars>();
        vars.add(var);
        
        Test.startTest();
        
        try{
            createHealthcheckInstances.createInstances(vars);
        } catch(Exception er){
            system.debug(er);
        }
        
        Test.stopTest();
    }
}