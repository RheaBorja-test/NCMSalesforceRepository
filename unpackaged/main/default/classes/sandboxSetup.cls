global class sandboxSetup implements SandboxPostCopy {
    global void runApexClass(SandboxContext context) {
        
        list<Account> accs = [select id from Account where name = 'NCM Associates'];
        id accId;
        if (accs.size() == 0){
            account acc = new Account();
            acc.name = 'NCM Associates';
            acc.BillingStreet = '4717 Grand Ave';
            acc.BillingCity = 'Kansas City';
            acc.BillingState = 'MO';
            acc.BillingPostalCode = '64112';
            acc.Industry = 'Other';
            
            try{
                insert acc;
            } catch (exception er){
                system.debug(er);
            }
            accId = acc.Id;
        } else{
            accId = accs.get(0).id;
        }
        
        list<User> usrs = [select id, Profile.Name, Email, NCM_Associates_Contact_ID__c, FirstName, LastName 
                           from User 
                           where isActive = true and Profile.Name = 'System Administrator'];
        list<User> resetUsrs = new list<User>();
        list<id> conIds = new list<id>();
        
        for(User usr : usrs){
            resetUsrs.add(usr);
            conIds.add(usr.NCM_Associates_Contact_ID__c);
        }
        
        if(resetUsrs.size()> 0){
            for(User usr : resetUsrs){
                string email = usr.Email;
                email = email.replaceAll('.invalid', '');
                usr.Email = email;
            }
            try{
                update resetUsrs;
            } catch (exception er){
                system.debug(er);
            }
            
            list<contact> cons = [select id, User_ID__c from Contact where id in :conIds];
            for(contact con : cons){
                integer i = 0;
                for (User usr: resetUsrs){
                    if (usr.id == con.User_ID__c){
                        break;
                    }
                    i++;
                }
                resetUsrs.remove(i);
            }
            
            if (resetUsrs.size() > 0){
                list<contact> addCons = new list<contact>();
                for (User usr: resetUsrs){
                    addCons.add(crtCon(usr, accId));
                }
                
                try{
                    insert addCons;
                } catch (exception er){
                    system.debug(er);
                }
            }
        }
        
        
    }
    
    private Contact crtCon(User usr, id accId){
        contact con = new Contact();
        con.RecordTypeId = Schema.SObjectType.contact.getRecordTypeInfosByName().get('NCM Associates').getRecordTypeId();
        con.AccountId = accId;
        con.FirstName = usr.FirstName;
        con.LastName = usr.LastName;
        con.Email = usr.Email;
        con.User_ID__c = usr.Id;
        
        return con;
    }
}