@RestResource(urlMapping='/FDAccountUpdate/*') 
global class FoundationDirectAPI {

    @HttpPost 
    global static FoundationDirectModel.FoundationDirectResponse updateAccountWithFDId(String ncmAccountId, String foundationDirectId){
    
        FoundationDirectModel.FoundationDirectResponse resp = new FoundationDirectModel.FoundationDirectResponse();

        String acctId = String.escapeSingleQuotes(ncmAccountId);

        if( String.isBlank(acctId) ){
            resp.message = 'Invalid ncmAccountId';
            resp.status = '500';
            return resp;
        }

        if( String.isBlank(foundationDirectId) ){
            resp.message = 'Invalid foundationDirectId';
            resp.status = '500';
            return resp;
        }

        try{
            // Attempt to find the account id.
            List<Account> acctResults = [select id, name from account where id = :acctId];
            if(acctResults.isEmpty()){
                // No account found.
                resp.message = 'No account found with id ' + acctId;
                resp.status = '500';
            } else {
                // Use the first result from the collection (there should only be one result since we searched by record id).
                Account acct = acctResults[0];
                acct.Foundation_Direct_Id__c = foundationDirectId;
                update(acct);

                resp.message = 'Account ' + acct.Id + ' updated successfully with FoundationDirect ID ' + foundationDirectId;
                resp.status = '200';
            }
        } catch (Exception ex){
            resp.message = 'Error updating account: ' + ex.getMessage();
            resp.status = '500';
        }
        
        return resp;

    }
}