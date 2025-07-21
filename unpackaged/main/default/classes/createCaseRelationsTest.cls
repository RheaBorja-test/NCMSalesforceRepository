@isTest (SeeAllData=true)
public class createCaseRelationsTest {
    static testMethod void TestcreateCaseRelations(){
        
        createCaseRelations.vars var = new createCaseRelations.vars();
        var.cseId = [select id from Client_Support_Ticket__c limit 1].id;
        var.objNme = 'axcessa_Platform_Engagement__c';
        var.soqlWhere = 'axcessa_Group__c = \'' + 
            [select axcessa_Group__c from axcessa_Platform_Engagement__c where Store_Status__c = 'ACTIVE' limit 1].axcessa_Group__c + 
            '\' and Store_Status__c = \'ACTIVE\'';
        var.childFldNme = 'axcessa_Store__c';
        
        List<createCaseRelations.vars> vars = new List<createCaseRelations.vars>();
        vars.add(var);
        
        test.startTest();
        try{
            createCaseRelations.createCaseRelations(vars);
        } catch(exception er){
            system.debug(er);
        }
        test.stopTest();
    }
}