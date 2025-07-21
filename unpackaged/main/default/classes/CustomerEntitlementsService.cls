@RestResource(urlMapping='/CustomerEntitlements/*')
global class CustomerEntitlementsService {
    
    @HttpGet
    global static CustomerSubscriptionModel.CustomerEntitlementsResponse getCustomerEntitlements(){

        // Response from this method
        CustomerSubscriptionModel.CustomerEntitlementsResponse resp = new CustomerSubscriptionModel.CustomerEntitlementsResponse();

        // Accounts that meet the criteria and need to be returned from this method.
        Set<Id> acctIdSet = new Set<Id>();
        
        // Get the Accounts whose NCMi or aXcessa checkboxes have changed in the past day.
        List<AccountHistory> ahList = [SELECT AccountId FROM AccountHistory where Field IN ('NCMI_Client_Code__c','aXcessa_Client_Code__c') and CreatedDate = LAST_N_DAYS:31];
        System.debug(ahList.size() + ' accounts have had either the NCMi or aXcessa checkbox changed today.');
        for(AccountHistory ah:ahList){
            acctIdSet.add(ah.AccountId);
        }

        // Get New 20 Group Members whose Account has either (or both) the NCMI Client Code or the aXcessa Client Code field popuated.
        List<X20_Groups_Member__c> newTwentyGroupMembers = [SELECT Account__c, Id FROM X20_Groups_Member__c where CreatedDate = last_n_days:31 and (Account__r.NCMi_Client_Code__c != null OR Account__r.Axcessa_Client_Code__c != null)];
        for(X20_Groups_Member__c mem:newTwentyGroupMembers){
            acctIdSet.add(mem.Account__c);
        }

        // Get New Proprietary Group Members whose Account has either (or both) the NCMI Client Code or the aXcessa Client Code field popuated.
        List<Proprietary_Account__c> newPropAccounts = [SELECT Account__c,Id FROM Proprietary_Account__c where CreatedDate = last_n_days:31 and (Account__r.NCMi_Client_Code__c != null OR Account__r.Axcessa_Client_Code__c != null)];
        for(Proprietary_Account__c mem:newPropAccounts){
            acctIdSet.add(mem.Account__c);
        }

        // Get any 20 Group Members whose status has changed from Disconnected to Active in the past 31 days
        Set<Id> x20MembersToProcess = new Set<Id>();
        for(X20_Groups_Member__History hist : [SELECT Field,Id,NewValue,OldValue,ParentId FROM X20_Groups_Member__History WHERE Field = 'Status__c' and CreatedDate = LAST_N_DAYS:31]){
            if(hist.NewValue == 'Active' && hist.OldValue == 'Disconnected'){
                x20MembersToProcess.add(hist.ParentId);
                System.debug('Added 20 Group Member ' + hist.ParentId + ' to x20MembersToProcess.');
            }
        }
        for(X20_Groups_Member__c mem:[select Account__c from X20_Groups_Member__c where Id IN :x20MembersToProcess]){
            acctIdSet.add(mem.Account__c);
            System.debug('Added ' + mem.Account__c + ' from 20 Group Member whose update has been changed to Active.');
        }

        
        // Get any Proprietary Accounts whose status has changed from Disconnected to Active in the past 31 days
        Set<Id> propAcctsToProcess = new Set<Id>();
        for(Proprietary_Account__History hist : [SELECT Field,Id,NewValue,OldValue,ParentId FROM Proprietary_Account__History WHERE Field = 'Status__c' and CreatedDate = LAST_N_DAYS:31]){
            if(hist.NewValue == 'Active' && hist.OldValue == 'Disconnected'){
                propAcctsToProcess.add(hist.ParentId);
                System.debug('Added Prop Account ' + hist.ParentId + ' to propAcctsToProcess.');
            }
        }
        for(Proprietary_Account__c mem:[select Account__c from Proprietary_Account__c where Id IN :propAcctsToProcess]){
            acctIdSet.add(mem.Account__c);
            System.debug('Added ' + mem.Account__c + ' from Prop Account whose update has been changed to Active.');
        }



        if(acctIdSet.isEmpty()){
            if(Test.isRunningTest()){
                System.debug('Test execution mode. Retrieving 5 sample accounts for test purposes.');
                for(Account a:[select id from Account limit 5]){
                    acctIdSet.add(a.Id);
                }
            } else {
                 System.debug('No account changes detected for this time period.');
                 resp.status = '200';
                 resp.message = 'No accounts have been updated in the past month to match the NCMi or aXcessa criteria.';
                 return resp;
            }
        } 

        List<Account> updatedAccounts = [SELECT Id, Name, aXcessa_Client_Code__c, NCMI_Client_Code__c, ShippingPostalCode FROM Account WHERE ID IN :acctIdSet];
        System.debug(updatedAccounts.size() + ' accounts have changed either the ncmi client code or the axcessa client code.');
        
        

        if(updatedAccounts.isEmpty()){
            resp.status = '200';
            resp.message = 'No accounts to process today.';
        } else {
            
            // Active 20 group membership for each account.
            Map<Id, List<X20_Groups_Member__c>> acct20GMemberMap = get20GroupMembership(acctIdSet);

            // Active Prop group membership for each account.
            Map<Id, List<Proprietary_Account__c>> acctPropMemberMap = getPropGroupMembership(acctIdSet);

            List<CustomerSubscriptionModel.AccountInfo> acctInfoList = new List<CustomerSubscriptionModel.AccountInfo>();
            
            
            for(Account acct : updatedAccounts){
                CustomerSubscriptionModel.AccountInfo a = new CustomerSubscriptionModel.AccountInfo();
                a.Name = acct.Name;
                a.accountId = acct.Id;
                a.axcessaClient = acct.aXcessa_Client_Code__c;
                a.ncmiClient = acct.NCMI_Client_Code__c;
                a.groups = new List<CustomerSubscriptionModel.GroupMembership>();
                
                // Add 20 Group Members for this account.
                if(acct20GMemberMap.containsKey(acct.Id)){
                    for(X20_Groups_Member__c mbr:acct20GMemberMap.get(acct.Id)){
                        CustomerSubscriptionModel.GroupMembership mem = new CustomerSubscriptionModel.GroupMembership();
                        mem.groupType = '20 Group';
                        mem.groupNumber = mbr.Group_ID__r.Name;
                        mem.memberNumber = String.valueOf(mbr.Member_Number__c);
                        mem.zipCodePrefix = acct.ShippingPostalCode != null ? acct.ShippingPostalCode.left(3) : '';
                        a.groups.add(mem);
                    }
                }

                // Add Proprietary Accounts for this account.
                if(acctPropMemberMap.containsKey(acct.Id)){
                    for(Proprietary_Account__c mbr:acctPropMemberMap.get(acct.Id)){
                        CustomerSubscriptionModel.GroupMembership mem = new CustomerSubscriptionModel.GroupMembership();
                        mem.groupType = 'Proprietary';
                        mem.groupNumber = mbr.Group_Number__c;
                        mem.memberNumber = mbr.Member_Number__c;
                        mem.zipCodePrefix = acct.ShippingPostalCode != null ? acct.ShippingPostalCode.left(3) : '';
                        a.groups.add(mem);
                    }
                }

                // If the account doesn't have any 20G or Prop group memberships, don't include them in the results.
                if( !a.groups.isEmpty() ){
                    acctInfoList.add(a);
                    
                } else {
                    System.debug('Account ' + a.Name + ' has no active group memberships, this account will not be included in the results.');
                }
            }
            resp.accounts = acctInfoList;
        }
        
        // Set the status and message for our response.
        resp.status = '200';
        resp.message = resp.accounts.size() + ' accounts have changed.';


        return resp;
    }




    private static Map<Id, List<X20_Groups_Member__c>> get20GroupMembership(Set<Id> acctIdSet){
        List<X20_Groups_Member__c> twentyGroupMembers = [SELECT Id, Name, Account__c,Group_Member_Number__c, Group_ID__r.Name, Member_Name__c,Member_Number__c 
                                                        FROM X20_Groups_Member__c 
                                                        WHERE Account__c IN :acctIdSet 
                                                            AND Status__c IN ('Active','Approved') // MD 1/16/25: Added "Approved" so that Candidate members would be included in the results.
                                                        ];
        Map<Id, List<X20_Groups_Member__c>> acctMemberMap = new Map<Id, List<X20_Groups_Member__c>>();
        for(X20_Groups_Member__c mem:twentyGroupMembers){

            // Create a list to hold x20_groups_member__c records for each account.
            List<X20_Groups_Member__c> memList = new List<X20_Groups_Member__c>();

            // Check if we already have this Account in the map (and if so, use it instead of the empty list we created above).
            if(acctMemberMap.containsKey(mem.Account__c)){
                memList = acctMemberMap.get(mem.Account__c);
            }

            // Add this 20 Group Member to the list for this account
            memList.add(mem);
            
            // Update the map for this account with the updated list of 20 group members under it.
            acctMemberMap.put(mem.Account__c, memList);
        }

        return acctMemberMap;
    }

    private static Map<Id,List<Proprietary_Account__c>> getPropGroupMembership(Set<Id> acctIdSet){
        List<Proprietary_Account__c> propAcctResults = [SELECT Account__c,Group_Number__c,Member_Number__c,Name 
                                                        FROM Proprietary_Account__c 
                                                        WHERE Account__c IN :acctIdSet 
                                                            AND Status__c IN ('Active','Approved') // MD 1/16/25: Added "Approved" so that Candidate members would be included in the results.
                                                        ];
        Map<Id, List<Proprietary_Account__c>> acctMemberMap = new Map<Id, List<Proprietary_Account__c>>();
        for(Proprietary_Account__c mem:propAcctResults){

            // Create a list to hold x20_groups_member__c records for each account.
            List<Proprietary_Account__c> memList = new List<Proprietary_Account__c>();

            // Check if we already have this Account in the map (and if so, use it instead of the empty list we created above).
            if(acctMemberMap.containsKey(mem.Account__c)){
                memList = acctMemberMap.get(mem.Account__c);
            }

            // Add this 20 Group Member to the list for this account
            memList.add(mem);
            
            // Update the map for this account with the updated list of 20 group members under it.
            acctMemberMap.put(mem.Account__c, memList);
        }

        return acctMemberMap;
    }
    
}