@isTest (SeeAllData=true)
public class chatterPostTest {
    static testMethod void TestchatterPost(){
        Opportunity opp = [select id from Opportunity limit 1];
        
        Test.startTest();
        
        chatterPost.vars var = new chatterPost.vars();
        var.subjectNameOrId = opp.id;
        var.Title = 'Subject';
        var.text = 'Body Info';
        var.linkURL = 'www.bing.com';
        
        List<chatterPost.vars> vars = new List<chatterPost.vars>();
        vars.add(var);
        
        try{
            chatterPost.postFeedItem(vars);
        } catch(Exception er){
            system.debug(er);
        }
        Test.stopTest();
    }
}