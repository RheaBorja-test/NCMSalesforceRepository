public class axcessaBillProd {
    public class vars {

        @InvocableVariable(label='axcessa CEM' Required=true)
        public Id axcId;
        
    }
    
    @InvocableMethod
    public static void addUpdBProd(List<vars> vars){
        list<Billing_Product__c> bProds = new list<Billing_Product__c>();
        list<axcessa_Platform_Engagement__c> axcCems = new list<axcessa_Platform_Engagement__c>();
        id pbId = [select id from Pricebook2 where IsStandard = true].id;
        
        id ax1_5 = [select id from Product2 where Name = 'FEES - AXCESSA (1-5 STORES)' limit 1].id;
        PriceBookEntry pbe1_5 = [select id, UnitPrice, Product2id from PriceBookEntry where Product2Id = :ax1_5 and Pricebook2id = :pbId];
        
        id ax6_14 = [select id from Product2 where Name = 'FEES - AXCESSA (6+ STORES)' limit 1].id;
        PriceBookEntry pbe6_14 = [select id, UnitPrice, Product2id from PriceBookEntry where Product2Id = :ax6_14 and Pricebook2id = :pbId];
        
        id ax15 = [select id from Product2 where Name = 'FEES - AXCESSA (15+ STORES)' limit 1].id;
        PriceBookEntry pbe15 = [select id, UnitPrice, Product2id from PriceBookEntry where Product2Id = :ax15 and Pricebook2id = :pbId];
        
        integer day = date.today().day();
        integer month;
        integer year;
        date bDate;
        if (day > 15){
            month = date.today().addMonths(1).month();
            year = date.today().addMonths(1).year();
        } else {
            month = date.today().month();
            year = date.today().year();
        }
        bDate = date.valueOf(year + '-' + month + '-25');
        
        for (vars var : vars){
            axcessa_Platform_Engagement__c axcCem = [select id, Monthly_Fee__c, Billing_Account__c, Dimension_1__c, Dimension_2__c, 
                                                     	Main_Product__c, Mobile_Fee__c 
                                                     from axcessa_Platform_Engagement__c 
                                                     where id = :var.axcId];
            boolean hsBprod = false;
            list<Billing_Product__c> varBprods = [select id, Product__c from Billing_Product__c where axcessa_Platform_Engagement__c = :var.axcId];
            for (Billing_Product__C bProd : varBprods){
                if (bProd.Product__c == axcCem.Main_Product__c){
                    hsBprod = true;
                       
                    PriceBookEntry pbe = new PriceBookEntry();
                    if (axcCem.Main_Product__c == ax1_5){
                        pbe = pbe1_5;
                    } else if (axcCem.Main_Product__c == ax6_14){
                        pbe = pbe6_14;
                    } else if (axcCem.Main_Product__c == ax15){
                        pbe = pbe15;
                    } 
                       
                    if (pbe.UnitPrice < axcCem.Monthly_Fee__c){
                        axcCem.Monthly_Fee__c = pbe.UnitPrice;
                        axcCems.add(axcCem);
                    }
                       
                    bProds.add(updBprod(bProd, axcCem, pbe, bDate));
                } else if (bProd.Product__c == ax1_5 || bProd.Product__c == ax6_14 || bProd.Product__c == ax15){
                       bProd.Billing_Product_Status__c = 'Inactive';
                       bProds.add(bProd);
                }
            }
            if (!hsBprod){
                PriceBookEntry pbe = new PriceBookEntry();
                if (axcCem.Main_Product__c == ax1_5){
                    pbe = pbe1_5;
                } else if (axcCem.Main_Product__c == ax6_14){
                    pbe = pbe6_14;
                } else if (axcCem.Main_Product__c == ax15){
                    pbe = pbe15;
                }
                
                if (pbe.UnitPrice < axcCem.Monthly_Fee__c){
                    axcCem.Monthly_Fee__c = pbe.UnitPrice;
                    axcCems.add(axcCem);
                }
                
                Billing_Product__c bProd = new Billing_Product__c();
                
                bProds.add(updBprod(bProd, axcCem, pbe, bDate));
            }
        }
        
        upsert bProds;
        upsert axcCems;
    }
    
    private static Billing_Product__c updBprod(Billing_Product__c bProd, axcessa_Platform_Engagement__c axcCem, PriceBookEntry pbe, date bDate){
        
        bProd.Billing_Product_Status__c = 'Active';                       
        
        bProd.Product__c = pbe.Product2Id;
        bProd.Value__c = axcCem.Monthly_Fee__c;
        bProd.Billing_Account__c = axcCem.Billing_Account__c;
        bProd.axcessa_Platform_Engagement__c = axcCem.id;
        bProd.Next_Billing_Date__c = bDate;
        bProd.Dimension_1__c = axcCem.Dimension_1__c;
        bProd.Dimension_2__c = axcCem.Dimension_2__c;                       
        
        bProd.Billing_Frequency__c = 'Monthly';
        bProd.Billing_Product_Status__c = 'Waiting on Sign Off';
        bProd.Recurring_Billing_Day__c = 25;
        bProd.Write_to_Opp__c = false;
        
        return bProd;
    }
    
}