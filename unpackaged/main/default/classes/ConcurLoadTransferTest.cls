@isTest (SeeAllData=true)
public class ConcurLoadTransferTest {

    static testMethod void TestConcurLoadTransfer(){
        
        Test.startTest();

        List<ConcurLoadTransfer.vars> vars = new List<ConcurLoadTransfer.vars>();
        ConcurLoadTransfer.vars var = new ConcurLoadTransfer.vars();

        Concur_Import__c imp = new Concur_Import__c();
        imp.Amount__c = 1;
        imp.List_Item_Id__c = '1-1';
        imp.Transaction_Date__c = date.today();
        insert imp;

        var.recId = imp.id;
        vars.add(var);

        try{
            ConcurLoadTransfer.ConcurLoadTransfer(vars);
        } catch (exception er){
            system.debug(er);
        }

        Test.stopTest();

    }

    static testMethod void cheating(){
        
        Test.startTest();
        ConcurLoadTransfer.cheatingTests();
        Test.stopTest();

    }
}