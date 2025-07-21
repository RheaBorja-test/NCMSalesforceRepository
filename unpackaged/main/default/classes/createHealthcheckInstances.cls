public class createHealthcheckInstances {
    public class vars {
        @InvocableVariable(label='Group Id' Required=true)
        public id grpId;
        @InvocableVariable(label='Opportunity Id' Required=true)
        public id oppId;
    }
    
    @InvocableMethod
    public static void createInstances(List<vars> vars){
        list<Healthcheck_Instance__c> hlthInsts = new list<Healthcheck_Instance__c>();
        for (vars var : vars){
            list<X20_Groups_Member__c> mems = [select id, Account__c, Member_Name__c, Account__r.Name, Account__r.Primary_Billing_Account__c
                                                from X20_Groups_Member__c 
                                                where Group_ID__c = :var.grpId and Status__c = 'Active'];
            for (X20_Groups_Member__c mem : mems){
                list<Healthcheck_Store__c> hlthStrLst = [select id from Healthcheck_Store__c where Account__c = :mem.Account__c];
                Healthcheck_Store__c hlthStr;
                if (hlthStrLst.size() > 0){
                    hlthStr = hlthStrLst.get(0);
                } else{
                    hlthStr = new Healthcheck_Store__c();
                    hlthStr.Account__c = mem.Account__c;
                    hlthStr.Contact__c = mem.Member_Name__c;
                    hlthStr.Name = mem.Account__r.Name;
                    insert hlthStr;
                }
                
                Healthcheck_Instance__c hlthInst = new Healthcheck_Instance__c();
                hlthInst.Account__c = mem.Account__c;
                hlthInst.Billing_Account__c = mem.Account__r.Primary_Billing_Account__c;
                hlthInst.Contact__c = mem.Member_Name__c;
                hlthInst.Healthcheck_Store__c = hlthStr.id;
                hlthInst.Name = mem.Account__r.Name;
                hlthInst.Originating_Opportunity__c = var.oppId;
                hlthInst.RecordTypeId = Schema.SObjectType.Healthcheck_Instance__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId();
                hlthInst.X20_Groups__c = var.grpId;
                hlthInst.X20_Groups_Member__c = mem.id;
                
                hlthInsts.add(hlthInst);
            }
        }
        
        if(hlthInsts.size() > 0){
            List<database.SaveResult> srList = database.insert(hlthInsts);
            for(database.SaveResult sr : srList){
                if(sr.isSuccess()){
                    system.debug('Successfully created Instance. ID:' + sr.getId());
                } else{
                    for(database.Error er : sr.getErrors()){
                        system.debug('Issue creating Instance:' + er.getMessage());
                    }
                }
            }
        }
    }
}