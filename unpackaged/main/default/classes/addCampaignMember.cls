public class addCampaignMember {
    public class vars {
        @InvocableVariable(label='Lead / Contact Id' Required=true)
        public id recId;
        @InvocableVariable(label='Parent Campaign Name' Required=true)
        public string parCmpName;
        @InvocableVariable(label='Campaign Name' Required=true)
        public string cmpName;
        @InvocableVariable(label='Member Status' Required=false)
        public string cmpStatus;
    }
    
    @InvocableMethod
    public static void addMember(List<vars> vars){
        list<CampaignMember> cmpMems = new list<CampaignMember>();
        for (vars var : vars){
            CampaignMember cmpMem = new CampaignMember();
            
            string cmpNme = '%' + var.cmpName + '%';
            string parCmpNme = var.parCmpName;
            list<campaign> cmp = [select id from Campaign where name like :cmpNme and Parent.Name = :parCmpNme];
            if (cmp.size() == 0){
                cmp = [select id from Campaign where name like :parCmpNme];
            }
            cmpMem.CampaignId = cmp.get(0).id;
            
            String sobjectName = var.recId.getSObjectType().getDescribe().getName();
            if (sobjectName == 'Contact'){
                cmpMem.ContactId = var.recId;
            } else {
                cmpMem.LeadId = var.recId;
            }
            
            if (var.cmpStatus == null || var.cmpStatus == ''){
                cmpMem.Status = 'Open';
            } else {
                cmpMem.Status = var.cmpStatus;
            }
            
            cmpMems.add(cmpMem);
        }
        
        database.SaveResult[] sResult = database.insert(cmpMems, false);
        for(Database.saveResult sr: sResult){
            if(sr.isSuccess()){
                system.debug('Successfully inserted! ID: ' + sr.getId());
            } else{
                for(Database.Error err : sr.getErrors()){
                    system.debug('The following error has occurred - ' + err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
    }
}