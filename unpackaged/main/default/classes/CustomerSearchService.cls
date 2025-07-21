@RestResource(urlMapping='/CustomerSearch/*') 
global class CustomerSearchService {

    @HttpPost 
    global static CustomerSearchResponse search(CustomerSearchContext ctx) {

        final String logTag = '[CustomerSearchService.search()]';
        CustomerSearchResponse csr = new CustomerSearchResponse();
        
        if(ctx.isValid){
            String qry = 'SELECT ID, Name, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, Website, Phone FROM Account ';
            
            if( !String.isBlank(ctx.memberNumber) ){
                String cleanMemberNumber = String.escapeSingleQuotes(ctx.memberNumber);
                qry += 'WHERE ID IN (SELECT Account__c FROM X20_Groups_Member__c WHERE Group_Member_Number__c = :cleanMemberNumber)';
            } else if (!String.isBlank(ctx.customerId)){
                String cleancustomerId = String.escapeSingleQuotes(ctx.customerId);
                qry += 'WHERE Id = :cleancustomerId';
            } else if (!String.isBlank(ctx.customerName) && !String.isBlank(ctx.postalCode)){
                String cleanName = String.escapeSingleQuotes(ctx.customerName);
                String cleanPostalCode = String.escapeSingleQuotes(ctx.postalCode).left(5);
                cleanName = cleanName.substring(0,5); // (We only care about 5 digits);
                qry += 'WHERE Name LIKE \'%' + cleanName + '%\' AND ShippingPostalCode LIKE \'' + cleanPostalCode + '%\'';
           
				// Did they pass in a Building Number?
                if(!String.isBlank(ctx.buildingNumber)){
                    
                    String cleanBuildingNumber = String.escapeSingleQuotes(ctx.buildingNumber);
                    System.debug('DERRICK: CUSTOMER SEARCH RESPONSE: Clean Building Number: ' + cleanBuildingNumber);
                    
                    qry += ' AND ShippingStreet LIKE \'%' + cleanBuildingNumber + '%\' ';
                    
                    System.debug('Name/Postal/Building query: ' + qry);
                    // Here's what the query SHOULD end up looking like 
                    // select id, name, shippingstreet, shippingpostalcode from account where Name LIKE '%Derri%' and ShippingPostalCode = '76039' and ShippingStreet LIKE '%2215%'
                }  
           
            } else {
                System.debug('DERRICK: CUSTOMER SEARCH RESPONSE: INSIDE: ELSE STATEMENT!' );
                csr.statusCode = '500';
                csr.statusMessage = 'Invalid search (invalid search parameters).';
                csr.numberOfResults = 0;
            } 

            // Add one more filter to all the queries: filter out Parent accounts (those Account's where the ParentId field is non-null).
            //qry += ' AND ParentId != null ';
            
            System.debug(logTag + 'Query: ' + qry);
        
            List<Account> acctResults = Database.query(qry);
            if(acctResults.isEmpty()){
                System.debug(logTag + 'No results for Account query.');
                csr.statusCode = '500';
                csr.statusMessage = 'No results found for ' + ctx.customerName;
                csr.numberOfResults = 0;
            } else {
                System.debug(logTag + acctResults.size() + ' results for Account query.');
                String searchVal = !String.isBlank(ctx.memberNumber) ? ctx.memberNumber : ctx.customerName + ' (' + ctx.postalCode + ')';
                csr.statusCode = '200';
                
                // Map of AccountID => 20 Group Accounts (with contacts)
                Map<Id,List<GroupMember>> twentyGroupMap = getTwentyGroupMembership(acctResults);

                List<CustomerSearchResult> customerResults = new List<CustomerSearchResult>();
                for(Account acct:acctResults){
                    CustomerSearchResult acctResult = new CustomerSearchResult();

                     // Get 20 Group Membership(s) and related Member Contacts
                    if(twentyGroupMap.containsKey(acct.Id)){
                        acctResult.twentyGroupMembers = twentyGroupMap.get(acct.Id);
                    } else {
                        // If they don't have any Full Member 20 Group Accounts, don't include them in the search results.
                        System.debug('No Full-Member 20 Group Members were found for ' + acct.Name + ' so they will not be included in the search results.');
                        continue;
                    }
                    
                    acctResult.customerName = acct.Name;
                    acctResult.customerId = acct.Id;
                    acctResult.street = acct.ShippingStreet;
                    acctResult.city = acct.ShippingCity;
                    acctResult.state = acct.ShippingState;
                    acctResult.postalCode = acct.ShippingPostalCode;
                    acctResult.website = acct.Website;
                    acctResult.phone = acct.Phone;

                    // Add the account result to the collection we'll return to the client.
                    customerResults.add(acctResult);
                }


                csr.results = customerResults;
                csr.statusMessage = customerResults.size() + ' results found for search \'' + searchVal + '\'';
                csr.numberOfResults = customerResults.size();

            }
        } else {
            System.debug(logTag + 'Search criteria is not valid: ' + ctx.validationMessage);
            csr.statusCode = '500';
            csr.statusMessage = 'Invalid search context. Please provide an account name and postal code or valid member number.';
            csr.numberOfResults = 0;
        }

        return csr;
    }


    // Search for any active 20 Group Memberships for each account passed into the acctList parameter.
    private static Map<Id,List<GroupMember>> getTwentyGroupMembership(List<Account> acctList){
        
        Map<Id,List<GroupMember>> resultMap = new Map<Id,List<GroupMember>>();

        List<X20_Groups_Member__c> membershipResults = [SELECT 
                                                            Account__c,
                                                            Id, 
                                                            Group_ID__r.Name,
                                                            Member_Number_Code__c,
                                                            Name, 
                                                            Status__c,
                                                        	Type__c,
                                                        	(SELECT Id, Name, Member_Email__c, Preferred_Title__c 
                                                             FROM X20_Group_Member_Contacts__r 
                                                             WHERE Contact_Status__c = 'Active' 
                                                             AND Contact_Type__c = 'Member') // Only Active Members
                                                         FROM X20_Groups_Member__c
                                                         WHERE 
                                                             Account__c IN :acctList 
                                                             AND Type__c IN ('Full Member','Special_Composite','Additional_Store','Candidate')
                                                             AND Status__c IN ('Active','Approved','Submitted')
                                                             
                                                        ];
        System.debug(membershipResults.size() + ' membership results for ' + acctList.size() + ' accounts.');

        for(X20_Groups_Member__c mem:membershipResults){
            
            List<GroupMember> gmList = new List<GroupMember>();
            if(resultMap.containsKey(mem.Account__c)){
                gmList = resultMap.get(mem.Account__c);
            }
            gmList.add(new GroupMember(mem));
            resultMap.put(mem.Account__c, gmList);
            
        }

        return resultMap;
    }


    // MODEL Classes
    global class CustomerSearchContext{
        global String customerId {get;set;}
        global String postalCode {get;set;}
        global String customerName {get;set;}
        global String memberNumber {get;set;}
        global String validationMessage {get; private set;}
        global String buildingNumber {get; set;} 
        global Boolean isValid {
            get{
                // do some checks to make sure the search criteria is valid.

                // Do we have a member number?
                if(!String.isBlank(memberNumber)){
                    // is it the right length: 4 digits, a dash, and 2 digits?
                    if(memberNumber.length() != 7){
                        this.validationMessage = 'Member Number invalid. Member number must be in the form ####-##';
                        return false;
                    }
                    return true;
                } else if (!String.isBlank(customerId)){
                    if(customerId.length() < 15){
                        this.validationMessage = 'Invalid record id length: ' + customerId.length();
                        return false;
                    }
                } else {
                    if(String.isBlank(customerName) || String.isBlank(postalCode)){
                        this.validationMessage = 'Customer Name and Postal Code are both required.';
                        return false;
                    } else {
                        if(customerName.length() < 5){
                            this.validationMessage = 'Please provide at least 5 characters for the customer name.';
                            return false;
                        }

                        if(postalCode.length() < 5){
                            this.validationMessage = 'Postal code must be at least 5 characters in length';
                            return false;
                        }
                        
                        // IN THE FUTURE MAYBE CHECK TO MAKE SURE THE BUILDING NUMBER IS VALID??
                    }
				
                }
                return true;

            }
        }
    }

    global class CustomerSearchResponse{
        global String statusCode {get;set;}
        global String statusMessage {get;set;}
        global Integer numberOfResults {get;set;}
        global List<CustomerSearchResult> results{get;set;}
    }

    global class CustomerSearchResult{
        global String customerName {get;set;}
        global String customerId {get;set;}
        global String street {get;set;}
        global String city {get;set;}
        global String state {get;set;}
        global String postalCode {get;set;}
        global String website {get;set;}
        global String phone {get;set;}
       // global String buildingNumber {get; set;}
        global List<GroupMember> twentyGroupMembers {get;set;}
    }

    global class GroupMember{
        
        global String name{get;set;}
        global String groupNumber{get;set;}
        global String memberNumber{get;set;}
        global String memberType {get; set;} // Derrick: SALES - 1544
        global List<MemberContact> contacts{get;set;} 

        global GroupMember(X20_Groups_Member__c memRecord){

            // Member properties
            this.memberNumber = memRecord.Member_Number_Code__c;
            this.name = memRecord.Name;
            this.groupNumber = memRecord.Group_ID__r.Name;
            this.memberType = memRecord.Type__c;
            
            // Member Contacts
            if(memRecord.X20_Group_Member_Contacts__r != null){
                this.contacts = new List<MemberContact>();
                for(X20_Group_Member_Contact__c contact : memRecord.X20_Group_Member_Contacts__r){
                    MemberContact mc = new MemberContact();
                    mc.name = contact.Name;
                    mc.email = contact.Member_Email__c;
                    mc.title = contact.Preferred_Title__c;
                    contacts.add(mc);
                }
            }

        }
    }

    global class MemberContact{
        global String name{get;set;}
        global String email {get;set;}
        global String title {get;set;}
    }
}