Public class AutoConvertLeads{
    
    public class vars {
        @InvocableVariable(label='Lead Id' Required=true)
        public id ldId;
    }
    
    @InvocableMethod
    public static void LeadConvert(List<vars> vars){
        
        list<id> LeadIds = new list<id>();
        for (vars var : vars){
            LeadIds.add(var.ldId);
        }
        list<Lead> lds = [select id, Name, NCM_Lead_Entry__r.Account__c, NCM_Lead_Entry__r.Contact__c, NCM_Lead_Entry__r.Opportunity__c 
                          from Lead 
                          where id in :LeadIds
                         ];
        
        LeadStatus CLeadStatus = [select Id, MasterLabel FROM LeadStatus WHERE IsConverted=true Limit 1];
        List<Database.LeadConvert> MassLeadconvert = new List<Database.LeadConvert>();
        
        for(Lead ld: lds){
            Database.LeadConvert Leadconvert = new Database.LeadConvert();
            Leadconvert.setLeadId(ld.id);                
            Leadconvert.setConvertedStatus(CLeadStatus.MasterLabel);
            
            if(ld.NCM_Lead_Entry__r.Account__c != null){
                LeadConvert.accountid = ld.NCM_Lead_Entry__r.Account__c;
            }
            
            if(ld.NCM_Lead_Entry__r.Contact__c != null){
                LeadConvert.contactid = ld.NCM_Lead_Entry__r.Contact__c;
            }
            
            if(ld.NCM_Lead_Entry__r.Opportunity__c != null){
                LeadConvert.opportunityid = ld.NCM_Lead_Entry__r.Opportunity__c;
            } else{
                Leadconvert.setOpportunityName('Auto Converted Lead');
            }
            
            Leadconvert.bypassaccountdedupecheck = true;
            Leadconvert.bypasscontactdedupecheck = true;
            MassLeadconvert.add(Leadconvert);
        }
        
        List<Database.LeadConvertResult> lcrs = new List<Database.LeadConvertResult>();
        if (!MassLeadconvert.isEmpty()) {
            lcrs = Database.convertLead(MassLeadconvert, false);
        }
        
        id NCMiRecId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('NCM Institute').getRecordTypeId();
        list<Opportunity> opps = new list<Opportunity>();
        
        for (Database.LeadConvertResult lcr : lcrs){
            if(lcr.isSuccess()){
                id oppId = lcr.getOpportunityId();
                id conId = lcr.getContactId();
                
                Opportunity opp = [select id, OwnerId, NCM_Lead_Entry__c, NCM_Lead_Entry__r.OwnerId, AccountId, Campaign.Name, Contract_Signed__c, RecordType.Name 
                                   from Opportunity 
                                   where id = :oppId];
                Contact con = [select id, Name from Contact where id = :conId];
                
                if(opp.Contract_Signed__c == 'Yes'){
                    opp.DocuSign_Sent__c = date.today();
                    opp.DocuSign_Signed__c = date.today();
                    if(opp.RecordType.Name == 'NCM Institute'){
                        opp.StageName = 'Validating Dates';
                    } else if (opp.RecordType.Name == '20 Groups' || opp.RecordType.Name == 'Proprietary'){
                        opp.StageName = 'Application Sent';
                    } else if (opp.RecordType.Name == 'axcessa' || opp.RecordType.Name == 'Healthcheck' || opp.RecordType.Name == 'LiveAudit'){
                        opp.StageName = 'Contract Received';
                    }
                } else if (opp.RecordType.Name == 'NCM Institute'){
                    opp.StageName = 'Validating Benefits';
                }
                
                opps.add(opp);
            }
        }
        
        if (!opps.isEmpty()) {
            update opps;
        }
    }
}