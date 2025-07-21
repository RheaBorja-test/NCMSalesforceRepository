@isTest (SeeAllData=true)
public class axcessaBillProdTest {
    static testMethod void TestaxcessaBillProd(){
        axcessa_Platform_Engagement__c axcCem = [select id 
                                                 from axcessa_Platform_Engagement__c 
                                                 where Main_Product__c <> null 
                                                 limit 1];
        
        Test.startTest();
        
        axcessaBillProd.vars var = new axcessaBillProd.vars();
        var.axcId = axcCem.id;
        
        list<Billing_Product__c> bProds = [select id from Billing_Product__c where axcessa_Platform_Engagement__c = :axcCem.id];
        
        List<axcessaBillProd.vars> vars = new List<axcessaBillProd.vars>();
        vars.add(var);
        
        try{
            axcessaBillProd.addUpdBProd(vars);
        } catch(Exception er){
            system.debug(er);
        }
        
        if (bProds.size() > 0){
            delete bProds;
        }
        
        try{
            axcessaBillProd.addUpdBProd(vars);
        } catch(Exception er){
            system.debug(er);
        }
        
        Test.stopTest();
    }
}