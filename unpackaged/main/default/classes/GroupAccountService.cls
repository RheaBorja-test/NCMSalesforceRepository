@RestResource(urlMapping='/GroupAccount/*')
global with sharing class GroupAccountService {
    
    @HttpGet
    global static GroupAccountResponse getAccountInfo() {
        
        // Prepare the response
        GroupAccountResponse resp = new GroupAccountResponse();

        // Parse the group account number
        RestRequest request = RestContext.request;
        String memberNumber = request.requestURI.substring(request.requestURI.lastIndexOf('/')+1);
        System.debug('Member Number: ' + memberNumber);

        // Determine if 20 Group or Proprietary/Benchmarking Group number
        if( String.isNotBlank(memberNumber) ){
            memberNumber = String.escapeSingleQuotes(memberNumber); // SOQL Injection Attack protection.

            String webQuery = 'SELECT id, Name, Account__c, Account__r.Name, Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingState, Account__r.ShippingPostalCode, Account__r.ShippingCountry, Group_Member_Number__c ' + 
                              'FROM X20_Groups_Member__c ' + 
                              'WHERE Status__c = \'Active\' and Group_Member_Number__c = :memberNumber';
            List<X20_Groups_Member__c> twentyGroupResults = Database.query(webQuery);
            /*list<X20_Groups_Member__c> twentyGroupResults = [SELECT id, Name, Account__c, Account__r.Name, Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingState, Account__r.ShippingPostalCode, Account__r.ShippingCountry, Group_Member_Number__c  
                                                             FROM X20_Groups_Member__c 
                                                             WHERE Status__c = 'Active' and Group_Member_Number__c = :memberNumber];
            */
            if( !twentyGroupResults.isEmpty() ){
                System.debug('Member Number [' + memberNumber + '] belongs to a 20 Group Member');
                resp.statusCode = '200';
                resp.message = twentyGroupResults.size() + ' results found for group account number ' + memberNumber;
                resp.status = 'Success';
                X20_Groups_Member__c member = twentyGroupResults[0];
                resp.groupType = '20 Group';
                resp.groupMemberNumber = memberNumber;
                resp.accountName = member.Account__r.Name;
                resp.street = member.Account__r.ShippingStreet;
                resp.city = member.Account__r.ShippingCity;
                resp.state = member.Account__r.ShippingState;
                resp.zipCode = member.Account__r.ShippingPostalCode;
                resp.country = member.Account__r.ShippingCountry;
            } else {
                String propQuery =  'SELECT Id, Name, Account__c, Account__r.Name, Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingState, Account__r.ShippingPostalCode, Account__r.ShippingCountry, Group_Member_Number__c ' + 
                                    'FROM Proprietary_Account__c ' + 
                                    'WHERE Status__c = \'Active\' and Group_Member_Number__c = :memberNumber';
                List<Proprietary_Account__c> propAcctResults = Database.query(propQuery);
                if( !propAcctResults.isEmpty() ){
                    System.debug('Member Number [' + memberNumber + '] is a Proprietary Account.');
                    resp.statusCode = '200';
                    resp.message = propAcctResults.size() + ' results found for group account number ' + memberNumber;
                    resp.status = 'Success';
                    Proprietary_Account__c member = propAcctResults[0];
                    resp.groupType = 'Benchmarking Group';
                    resp.groupMemberNumber = memberNumber;
                    resp.accountName = member.Account__r.Name;
                    resp.street = member.Account__r.ShippingStreet;
                    resp.city = member.Account__r.ShippingCity;
                    resp.state = member.Account__r.ShippingState;
                    resp.zipCode = member.Account__r.ShippingPostalCode;
                    resp.country = member.Account__r.ShippingCountry;
                } else {
                    System.debug('Member Number not found: ' + memberNumber);
                    resp.statusCode = '500';
                    resp.message = 'No results found for group account number ' + memberNumber;
                    resp.status = 'Error';
                }
            }
        }

        


        return resp;

    }
}