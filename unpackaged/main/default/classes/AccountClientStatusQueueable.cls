public class AccountClientStatusQueueable implements Queueable{
    public List<Id> bpIds;
    
    public AccountClientStatusQueueable(List<Id> bpIds) {
        this.bpIds = bpIds;
    }

    public void execute(QueueableContext context) {
        System.debug('~~~AccountClientStatusQueueable::execute: ' + this.bpIds);
    
        List<Id> actIds = new List<Id>();
        for(Billing_Product__c b : [SELECT Product_Service__r.Account__c FROM Billing_Product__c WHERE Id IN :this.bpIds]) {
            actIds.add(b.Product_Service__r.Account__c);
        }
        System.debug('~~~actIds: ' + actIds);
        List<Account> acts = new List<Account>();
        Map<Id,String> statusMap = new Map<Id,String>();
        Map<Id,Integer> activeMap = new Map<Id,Integer>();

        for(Billing_Product__c bp : [SELECT Id, Product_Service__r.Account__c, Product_Service__r.Account__r.Client_Status__c,
                                        Billing_Product_Status__c, Billing_Frequency__c
                                        FROM Billing_Product__c 
                                        WHERE Product_Service__r.Account__c IN :actIds]) {
            if(bp.Product_Service__c != null) {
                statusMap.put(bp.Product_Service__r.Account__c, bp.Product_Service__r.Account__r.Client_Status__c);
                Integer count = (bp.Billing_Product_Status__c.equalsIgnoreCase('Active') 
                                && !bp.Billing_Frequency__c.equalsIgnoreCase('One-Time')) ? 1 : 0;
                if(activeMap.containsKey(bp.Product_Service__r.Account__c)) {
                    Integer newCount = activeMap.get(bp.Product_Service__r.Account__c) + count;
                    activeMap.put(bp.Product_Service__r.Account__c, newCount);
                } else {
                    activeMap.put(bp.Product_Service__r.Account__c, count);
                }
            }
        }

        for(Id actId : statusMap.keySet()) {
            if((statusMap.get(actId) == null || statusMap.get(actId).equalsIgnoreCase('Prospect')) && activeMap.get(actId) > 0) {
                acts.add(new Account(Id = actId, Client_Status__c = 'Existing'));
            } else if((statusMap.get(actId) == null || statusMap.get(actId).equalsIgnoreCase('Existing')) && activeMap.get(actId) == 0) {
                acts.add(new Account(Id = actId, Client_Status__c = 'Prospect'));
            }
        }

        if(acts.size() > 0) {
            List<Database.SaveResult> dsrList = Database.update(acts, false);
            Logger.logErrorList('AccountClientStatusQueueable', dsrList, acts);
        }
    }
}