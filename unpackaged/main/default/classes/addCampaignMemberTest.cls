@isTest (SeeAllData=true)
public class addCampaignMemberTest {
    static testMethod void addCampaignMemberTest() {
        
        Lead ld = [select id from Lead where Status != 'Qualified' limit 1];
        Contact con = [select id from Contact limit 1];
        Campaign cmp = [select name, Parent.Name from Campaign where ParentId <> null limit 1];
            
        addCampaignMember.vars var = new addCampaignMember.vars();
        List<addCampaignMember.vars> vars = new List<addCampaignMember.vars>();
        
        var.recId = ld.id;
        var.parCmpName = cmp.parent.name;
        var.cmpName = cmp.Name;
        vars.add(var);
        
        var = new addCampaignMember.vars();
        var.recId = con.id;
        var.parCmpName = cmp.parent.name;
        var.cmpName = cmp.Name;
        var.cmpStatus = 'Open';
        vars.add(var);
        
        test.startTest();
        try{
            addCampaignMember.addMember(vars);
        } catch(DMLException er){
            system.debug(er);
        }
        test.stopTest();
    }
}