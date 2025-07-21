@isTest (SeeAllData=true)
public class relateAllContentTest {
    static testMethod void TestrelateAllContent(){
        test.startTest();
        
        relateAllContent.vars var = new relateAllContent.vars();
        ContentDocument conDoc = [select (select LinkedEntityId from ContentDocumentLinks) from ContentDocument limit 1];
        ContentDocumentLink conDocLnk = conDoc.ContentDocumentLinks.get(0);
        var.mainRecId = conDocLnk.LinkedEntityId;
        var.relRecId = [select id from Account limit 1].id;
        
        List<relateAllContent.vars> vars = new List<relateAllContent.vars>();
        vars.add(var);
        
        try{
            relateAllContent.relateContent(vars);
        } catch (exception er){
            system.debug(er);
        }
        
        test.stopTest();
    }
}