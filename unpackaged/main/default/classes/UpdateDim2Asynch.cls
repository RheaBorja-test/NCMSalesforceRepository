public class UpdateDim2Asynch implements Queueable {
    private List<String> ids;
    public UpdateDim2Asynch(List<String> ids) {
        this.ids = ids;
    }
    public  void execute(QueueableContext context) {
        try {
            Id x = (Id) ids[0];
            List<Billing_Product__c> billProds= new List<Billing_Product__c>();
            c2g__codaDimension2__c dim2 = new c2g__codaDimension2__c(); 
            String srch = 'SELECT Id, (SELECT Id FROM Billing_Products__r WHERE Billing_Product_Status__c IN (\'Active\', \'Suspended\')), ';
            Schema.SObjectType twentyGroupObject = Schema.Twenty_Groups__c.getSObjectType();
            Schema.SObjectType propGroupObject = Schema.Proprietary_Group__c.getSObjectType();
            Schema.SObjectType record = x.getsobjecttype();
            if(record == twentyGroupObject) {
                System.debug('~~~20 Group');
                srch = srch + 'Group_ID__r.NCM_Proprietor__r.Name FROM X20_Groups_Member__c WHERE Group_ID__c IN :ids';
                List<X20_Groups_Member__c> returnedList = Database.query(srch);
                //System.debug('~~~returnedList: ' + returnedList);
                for(X20_Groups_Member__c sObj : returnedList) {
                    billProds.addAll(sObj.Billing_Products__r);
                }
                dim2 = [SELECT Id FROM c2g__codaDimension2__c WHERE Name = :returnedList[0].Group_ID__r.NCM_Proprietor__r.Name LIMIT 1];
            } else if(record == propGroupObject) { 
                System.debug('~~~Prop Group');
                srch = srch + 'Proprietary_Group__r.Group_Owner__r.Name FROM Proprietary_Account__c WHERE Proprietary_Group__c IN :ids';
                List<Proprietary_Account__c> returnedList = Database.query(srch);
                //System.debug('~~~returnedList: ' + returnedList);
                for(Proprietary_Account__c sObj : returnedList) {
                    billProds.addAll(sObj.Billing_Products__r);
                }
                dim2 = [SELECT Id FROM c2g__codaDimension2__c WHERE Name = :returnedList[0].Proprietary_Group__r.Group_Owner__r.Name LIMIT 1];
            } else {
                System.debug('~~~None');
            }
        
            if(billProds.size() > 0 && dim2 != null) {
                for(Billing_Product__c bp : billProds) {
                    bp.Dimension_2__c = dim2.Id;
                }
                List<Database.SaveResult> srs = Database.update(billProds, false);
                List<Error_Logger__c> loggers = new List<Error_Logger__c>();
                for(Integer i = 0; i < srs.size(); i++) {
                    if(!srs[i].isSuccess()) {
                        Error_Logger__c el = new Error_Logger__c(Record_Id__c = billProds[1].Id,
                                                                Source__c = 'UpdateDim2Asynch',
                                                                Description__c = srs[i].getErrors()[0].getMessage());
                        loggers.add(el);
                    }
                }
                if(loggers.size() > 0) {
                    Database.insert(loggers, false);
                }
            }
        } catch(Exception e) {
            insert new Error_Logger__c(Source__c = 'UpdateDim2Asynch',
                                        Error_Message__c = e.getMessage(),
                                        Stack_Trace__c = e.getStackTraceString(),
                                        Error_Type__c = e.getTypeName());
        }
    }
}