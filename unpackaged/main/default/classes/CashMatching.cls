//Test coverage for this class is provided by ApplyPaymentsBatchTest
//because there was no clean way to bulkify the queries needed for the cash
//matching process, The class recieves a list, but chains them to run them
//one at a time, queuable context to avoid exceeding govenor limits. 
public class CashMatching implements Queueable{
    public class CashMatchingException extends Exception {}
    private List<c2g__codaCashEntry__c> ceList;
    //the name field is not included with the cash entries in the list
    //so the construcctor queries for all fields needed on the cash entries
    public CashMatching(List<c2g__codaCashEntry__c> ceList1) {
        List<Id> idList = new List<Id>();
        for(c2g__codaCashEntry__c ce : ceList1) {
            idList.add(ce.Id);
        }
        this.ceList = [SELECT Id, Name, c2g__Reference__c, c2g__Account__c, c2g__Period__c, c2g__Value__c 
                        FROM c2g__codaCashEntry__c 
                        WHERE Id IN :idList];        
    }
    
    public void execute(QueueableContext context) {
        //processes the first cash entry in the list and removes it
        c2g__codaCashEntry__c ce = ceList.remove(0);
        try {
            //Declare variables
            Id periodId = ce.c2g__Period__c;
            List<c2g__codaTransactionLineItem__c> ceTransList = [SELECT Id, SystemModstamp, c2g__DocumentValue__c, c2g__LineReference__c, c2g__Account__c
                                                        FROM c2g__codaTransactionLineItem__c
                                                        WHERE c2g__Transaction__r.c2g__DocumentNumber__c = :ce.Name 
                                                        AND c2g__MatchingStatus__c = 'Available'];

            List<String> references = new List<String>();
            for(c2g__codaTransactionLineItem__c tli : ceTransList) {
                references.add(tli.c2g__LineReference__c);
            }

            List<c2g__codaTransactionLineItem__c> sinTransList = [SELECT Id, SystemModstamp, c2g__DocumentOutstandingValue__c 
                                                        FROM c2g__codaTransactionLineItem__c
                                                        WHERE c2g__Transaction__r.c2g__DocumentNumber__c IN :references 
                                                        AND c2g__MatchingStatus__c = 'Available'];
            //check that these 2 variable are not null  
            if(ceTransList.size() < 1 || sinTransList.size() < 1) {
                throw new CashMatchingException();
            }
            
            //Setup the match operation
            Id acctId = ceTransList[0].c2g__Account__c;
            c2g.CODAAPICashMatchingTypes_8_0.Configuration configuration = new c2g.CODAAPICashMatchingTypes_8_0.Configuration();
            configuration.Account = c2g.CODAAPICommon.getRef(acctId, null);
            //Choose Document or Account depending on the Currency Mode you would choose if you were doing this from the UI.
            configuration.MatchingCurrencyMode = c2g.CODAAPICashMatchingTypes_8_0.enumMatchingCurrencyMode.Document;
            configuration.MatchingDate = System.Today();
            configuration.DiscountDate = System.today();
            configuration.MatchingPeriod = c2g.CODAAPICommon.getRef(periodId, null);
            
            //Make thelist of cash entries to post
            List<c2g.CODAAPICashMatchingTypes_8_0.Item> items = new List<c2g.CODAAPICashMatchingTypes_8_0.Item>();
        
            for(c2g__codaTransactionLineItem__c sinTrans : sinTransList) {                
                c2g.CODAAPICashMatchingTypes_8_0.Item item1 = new c2g.CODAAPICashMatchingTypes_8_0.Item();
                items.add(item1);
                item1.TransactionLineItem = c2g.CODAAPICommon.getRef(sinTrans.Id, null);
                item1.TransactionLineItemSystemModStamp = sinTrans.SystemModstamp;
                item1.Paid = sinTrans.c2g__DocumentOutstandingValue__c > ce.c2g__Value__c ? ce.c2g__Value__c : sinTrans.c2g__DocumentOutstandingValue__c;
                item1.Discount = 0;
                item1.WriteOff = 0;
            }

            for(c2g__codaTransactionLineItem__c ceTrans : ceTransList) {  
                c2g.CODAAPICashMatchingTypes_8_0.Item item2 = new c2g.CODAAPICashMatchingTypes_8_0.Item();
                items.add(item2);
                item2.TransactionLineItem = c2g.CODAAPICommon.getRef(ceTrans.Id, null);
                item2.TransactionLineItemSystemModStamp = ceTrans.SystemModstamp;
                item2.Paid = ceTrans.c2g__DocumentValue__c;
                item2.Discount = 0;
                item2.WriteOff = 0;
            }
            //create the context
            c2g.CODAAPICommon_8_0.Context cntx = new c2g.CODAAPICommon_8_0.Context();
            cntx.CompanyName = 'NCM Associates, Inc.';
            
            //create a null analysis object, since there are no discounts or write-offs
            c2g.CODAAPICashMatchingTypes_8_0.Analysis analysisInfoAPI = new c2g.CODAAPICashMatchingTypes_8_0.Analysis();
            
            // Finally, perform the match
            c2g.CODAAPICommon.Reference matchReference = c2g.CODAAPICashMatching_8_0.Match(cntx, configuration, items, analysisInfoAPI);
        } catch(Exception ex) {
            Logger.logErrorEvent('CashMatching', null, UserInfo.getName(), ex.getTypeName(), ex.getMessage(), ex.getStackTraceString(), ce.Id);
        }
        
        if(ceList.size() > 0) {
            //chain the same queueable class with the just matched cash entry removed (see line 20)
            System.enqueueJob(new CashMatching(ceList));
        }
    }
}