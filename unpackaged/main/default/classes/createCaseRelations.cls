public class createCaseRelations {
    public class vars {
        @InvocableVariable(label='Case Id' Required=true)
        public id cseId;
        @InvocableVariable(label='Object API Name' Required=true)
        public string objNme;
        @InvocableVariable(label='SOQL Where Clause' Required=true)
        public string soqlWhere;
        @InvocableVariable(label='Child Field API Name' Required=true)
        public string childFldNme;
    }
    
    @InvocableMethod
    public static void createCaseRelations(List<vars> vars){
        list<Client_Case_Relation__c> ccrs = new list<Client_Case_Relation__c>();
        for (vars var : vars){
            list<SObject> records = database.query('select id from ' + var.objNme + ' where ' + var.soqlWhere);
            for(SObject rec : records){
                Client_Case_Relation__c ccr = new Client_Case_Relation__c();
                ccr.Client_Case__c = var.cseId;
                
                sObject sObjCCR = ccr;
                sObjCCR.put(var.childFldNme, rec.get('id'));
                
                ccr = (Client_Case_Relation__c)sObjCCR;
                ccrs.add(ccr);
            }
        }
        
        if (ccrs.size() > 0){
            try{
                insert ccrs;
            } catch (DMLexception er){
                system.debug(er.getMessage());
            }
        }
    }
}