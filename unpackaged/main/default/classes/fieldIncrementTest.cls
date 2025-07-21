@isTest (SeeAllData=true)
public class fieldIncrementTest {
    static testMethod void TestfieldIncrement(){
        Opportunity opp = [select id from Opportunity limit 1];
        
        Test.startTest();
        
        fieldIncrement.vars var = new fieldIncrement.vars();
        var.recId = opp.id;
        var.fldNm = 'Demos_Completed__c';
        var.decrement = false;
        
        fieldIncrement.vars var2 = new fieldIncrement.vars();
        var2.recId = opp.id;
        var2.fldNm = 'Demos_Completed__c';
        var2.decrement = true;
        
        List<fieldIncrement.vars> vars = new List<fieldIncrement.vars>();
        vars.add(var);
        vars.add(var2);
        
        try{
            fieldIncrement.incrementField(vars);
        } catch(Exception er){
            system.debug(er);
        }
        
        try{
            fieldIncrement.incrementField(vars);
        } catch(Exception er){
            system.debug(er);
        }
        test.stopTest();
    }
}