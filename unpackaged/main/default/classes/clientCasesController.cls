public class clientCasesController {
    
    @AuraEnabled
    public static list<Client_Support_Ticket__c> getClientCases(id recId){
        list<Client_Support_Ticket__c> clientCases;
        
        DescribeSObjectResult describeResult = Client_Support_Ticket__c.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );
        
        String query =
            ' SELECT ' +
            String.join( fieldNames, ', ' ) +
            ' FROM ' +
            describeResult.getName();
        
        string objName = string.valueof(recId.getSobjectType());
        list<id> ccrIds;
        if (objName == 'axcessa_Platform_Engagement__c'){
            ccrIds = getCCRId(recId, 'axcessa_Store__c');
            query = query + ' WHERE axcessa_Store__c = \'' + recId + '\' or id IN :ccrIds';
        }
         
        query = query + ' Order By LastModifiedDate desc';
        clientCases = Database.query( query );
        
        return clientCases;
    }
    
    private static list<id> getCCRId(id recId, string fldNme){
        list<id> ccrIds = new list<id>();
        
        String query = ' SELECT Client_Case__c from Client_Case_Relation__c where ' + fldNme + ' = :recId';
        list<Client_Case_Relation__c> ccrs = Database.query( query );
        for (Client_Case_Relation__c ccr : ccrs){
            ccrIds.add(ccr.Client_Case__c);
        }
        
        return ccrIds;
    }
}