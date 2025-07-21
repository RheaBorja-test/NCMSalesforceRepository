global class BillingProductsForTermedTST implements Database.Batchable<SObject>, Schedulable{
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        String ACTIVE = 'Active';
        String TERMED = 'Termed';
        String ONETIME = 'One-Time';
        String queryString = 'SELECT Id, Name FROM Billing_Product__c WHERE Billing_Product_Status__c = \''
        + ACTIVE + '\' AND Billing_Frequency__c != \'' + ONETIME + '\' AND Training_Subscription_Account__c != null' +
        ' AND Training_Subscription_Account__r.Training_Subscription__r.Term__c = \'' + TERMED + 
        '\' AND Training_Subscription_Account__r.Training_Subscription__r.Transitioned_to_Monthly__c = false';
        System.debug('~~~queryString: ' + queryString);
        return Database.getQueryLocator(queryString);
    }

    global void execute(Database.BatchableContext BC, List<Billing_Product__c> scope) { 
        Id bpId;
        try{
            for(Billing_Product__c bp : scope) {
                bp.Billing_Product_Status__c = 'Inactive';
                bpId = bp.Id;
            }
            List<Database.SaveResult> dsrList = Database.update(scope, false);
            Logger.logErrorList('BillingProductsForTermedTST', dsrList, scope);
        } catch (Exception ex) {
            Logger.logException('BillingProductsForTermedTST', bpId, ex);
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('BillingProductsForTermedTST::finish');
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BillingProductsForTermedTST());
    }
}