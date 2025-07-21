@isTest (SeeAllData=true)
public class createContactRolesTest {
    static testMethod void TestcreateContactRoles(){
        Opportunity opp = [select id from Opportunity limit 1];
        X20_Groups_Member__c mem = [select id, Group_ID__c from X20_Groups_Member__c where Part_of_Executive_Committee__c = 'Yes' limit 1];
        
        createContactRoles.vars var = new createContactRoles.vars();
        var.oppId = opp.id;
        var.objNme = 'X20_Groups_Member__c';
        var.soqlWhere = 'Group_ID__c = \'' + mem.Group_ID__c + '\' and Part_of_Executive_Committee__c = \'Yes\' ';
        var.conFldNme = 'Member_Name__c';
        var.roleType = '';
        
        List<createContactRoles.vars> vars = new List<createContactRoles.vars>();
        vars.add(var);
        
        Test.startTest();
        
        try{
            createContactRoles.createConRoles(vars);
        } catch(Exception er){
            system.debug(er);
        }
        
        Test.stopTest();
    }
}