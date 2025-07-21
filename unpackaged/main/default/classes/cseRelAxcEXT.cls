public class cseRelAxcEXT {
    private ApexPages.StandardController stdController;
    public id cseId;
    public Client_Support_Ticket__c cse;
    public list<wRel> wRels;
    
    public cseRelAxcEXT(apexpages.standardcontroller stdController){
        this.stdController = stdController;
        cseId = ApexPages.currentPage().getParameters().get('id');
        getcse();
    }
    
    public Client_Support_Ticket__c getcse(){
        if (cse == null){            
            DescribeSObjectResult describeResult = Client_Support_Ticket__c.getSObjectType().getDescribe();
            List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );
            String query =
                ' SELECT ' +
                String.join( fieldNames, ',' ) +
                ' FROM ' +
                describeResult.getName() +
                ' where id = \'' + cseId + '\'';
            cse = Database.query( query );
        }
        return cse;
    }
    
    public list<wRel> getwRels(){
        if (wRels == null){
            wRels = new list<wRel>();
            list<axcessa_Platform_Engagement__c> strs;
            
            DescribeSObjectResult describeResult = axcessa_Platform_Engagement__c.getSObjectType().getDescribe();
            List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );
            String query =
                ' SELECT ' +
                String.join( fieldNames, ',' ) +
                ' FROM ' +
                describeResult.getName() +
                ' where axcessa_Group__c = \'' + cse.axcessa_Group__c + '\' and Store_Status__c <> \'Inactive\' order by Name';
            
            Try{
                strs = Database.query( query );
            } catch (exception er){
                system.debug(er);
                strs = new list<axcessa_Platform_Engagement__c>();
            }
            
            for (axcessa_Platform_Engagement__c str : strs){
                wRels.add(new wRel(cse, str));
            }
        }
        return wRels;
    }
    
    public PageReference slctAll(){
        for (wRel rel : wRels){
            rel.selected = true;
        }
        return null;
    }
    
    public PageReference unslctAll(){
        for (wRel rel : wRels){
            rel.selected = false;
        }
        return null;
    }
    
    public PageReference updRel() {
        list<Client_Case_Relation__c> addRels = new list<Client_Case_Relation__c>();
        list<Client_Case_Relation__c> delRels = new list<Client_Case_Relation__c>();
        
        for (wRel rel : wRels) {
            List<Client_Case_Relation__c> rels = [select id 
                                                  from Client_Case_Relation__c 
                                                  where Client_Case__c = :rel.cse.id and axcessa_Store__c = :rel.str.id];
            
            if (rel.selected == true && rels.size() == 0) {
                Client_Case_Relation__c nRel = new Client_Case_Relation__c();
                nRel.Client_Case__c = cseId;
                nRel.axcessa_Group__c = rel.str.axcessa_Group__c;
                nRel.axcessa_Store__c = rel.str.id;
                
                addRels.add(nRel);
            } else if (rel.selected == false && rels.size() != 0) {
                for (Client_Case_Relation__c delRel : rels){
                    delRels.add(delRel);
                }
            }
        }
        
        boolean isSuccess = true;
        if (addRels.size() > 0){
            try {
                insert addRels;
            } catch(Exception er){
                isSuccess = false;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,string.valueof(er)));
            }
        }
        if (delRels.size() > 0){
            try {
                delete delRels;
            } catch(Exception er){
                isSuccess = false;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,string.valueof(er)));
            }
        }
        
        if (isSuccess){
            PageReference pgRef = new PageReference('/' + cseId);   
            pgRef.setRedirect(true);
            return pgRef;
        } else {
            return null;
        }
    }
    
    public class wRel{
        public boolean selected {get; set;}
        public Client_Support_Ticket__c cse {get; set;}
        public axcessa_Platform_Engagement__c str {get; set;}
        
        public wRel(Client_Support_Ticket__c cse, axcessa_Platform_Engagement__c str) {
            this.cse = cse;
            this.str = str;
            List<Client_Case_Relation__c> rels = [select id 
                                                  from Client_Case_Relation__c 
                                                  where Client_Case__c = :cse.Id and axcessa_Store__c = :str.id];
            if (rels.size() > 0) {
                selected = true;
            } else {
                selected = false;
            }
            
        }
    }
}