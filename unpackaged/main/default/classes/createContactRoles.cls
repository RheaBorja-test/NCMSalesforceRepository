public class createContactRoles {
    public class vars {
        @InvocableVariable(label='Opportunity Id' Required=true)
        public id oppId;
        @InvocableVariable(label='Object API Name' Required=true)
        public string objNme;
        @InvocableVariable(label='SOQL Where Clause' Required=true)
        public string soqlWhere;
        @InvocableVariable(label='Contact Field API Name' Required=true)
        public string conFldNme;
        @InvocableVariable(label='Contact Role Type' Required=false)
        public string roleType;
    }
    
    @InvocableMethod
    public static void createConRoles(List<vars> vars){
        list<OpportunityContactRole> conRoles = new list<OpportunityContactRole>();
        for (vars var : vars){
            list<SObject> records = database.query('select ' + var.conFldNme + ' from ' + var.objNme + ' where ' + var.soqlWhere);
            for(SObject rec : records){
                OpportunityContactRole conRole = new OpportunityContactRole();
                
                conRole.ContactId = id.valueof(string.valueof(rec.get(var.conFldNme)));
                conRole.OpportunityId = var.oppId;
                conRole.Role = var.roleType;
                conRoles.add(conRole);
            }
        }
        
        if(conRoles.size() > 0){
            List<database.SaveResult> srList = database.insert(conRoles);
            for(database.SaveResult sr : srList){
                if(sr.isSuccess()){
                    system.debug('Successfully created Contact Role. ID:' + sr.getId());
                } else{
                    for(database.Error er : sr.getErrors()){
                        system.debug('Issue creating Contact Role:' + er.getMessage());
                    }
                }
            }
        }
        
    }
}