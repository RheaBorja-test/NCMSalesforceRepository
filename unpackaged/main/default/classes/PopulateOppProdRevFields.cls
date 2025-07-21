global class PopulateOppProdRevFields implements Database.Batchable<SObject>{
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            'SELECT Id, Quantity, UnitPrice, Contract_Months__c, Product2.Locked_Frequency__c FROM OpportunityLineItem WHERE ' +
            'Opportunity.IsClosed = false OR Opportunity.CreatedDate = THIS_YEAR' 
        ); 
    }

    global void execute(Database.BatchableContext BC, List<OpportunityLineItem> scope) {
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for(OpportunityLineItem oli : scope) {
            OpportunityLineItem newOLI = new OpportunityLineItem(Id = oli.Id);
            if(oli.Product2.Locked_Frequency__c == 'Monthly') {
                newOLI.MRR__c = oli.UnitPrice * oli.Quantity;
            } else if(oli.Product2.Locked_Frequency__c == 'Quarterly') {
                newOLI.MRR__c = oli.UnitPrice * oli.Quantity / 3;
            }
            if(oli.Product2.Locked_Frequency__c != 'Monthly' && oli.Product2.Locked_Frequency__c != 'Quarterly') {
                newOLI.NRR__c = oli.UnitPrice * oli.Quantity;
            }
            if(oli.Contract_Months__c != null) {
                newOLI.TCV__c = newOLI.MRR__c * oli.Contract_Months__c;
            }
            if(newOLI.MRR__c != null || newOLI.NRR__c != null || newOLI.TCV__c != null) {
                oliList.add(newOLI);
            }

            if(oliList.size() > 0) {
                List<Database.SaveResult> dsrList = Database.update(oliList, false);
                Logger.logErrorList('PopulateOppProdRevFields', dsrList, oliList); 
            }
        }
    } 
    
    global void finish(Database.BatchableContext BC) {}
}