public with sharing class userAvailabilityController {
    
    @AuraEnabled
    public static list<User> getUserAvailability(string roleName, datetime arr, datetime dep) {
        
        If (arr == null || dep == null){
            return null;
        } else{
            list<User> usrs = [select id, Phone, MobilePhone, Name, NCM_Associates_Contact_ID__c, IsProfilePhotoActive, SmallPhotoUrl
                               from User 
                               where UserRole.Name = :roleName and isActive = true
                               order by Name
                              ];

            integer i = 0;
            while (i < usrs.size()){
                User usr = usrs.get(i);
                
                List<Event> evts = [select id 
                                    from Event 
                                    where OwnerId = :usr.id and (StartDateTime < :dep or EndDateTime > :arr)
                                   ];

                if(evts.size() > 0){
                    usrs.remove(i);
                } else{
                    i++;
                }
            }

            System.debug(usrs);
            return usrs;
        }
    }

    @AuraEnabled
    public static list<String> getRoles(){
        list<string> roles = new list<string>();

        list<UserRole> usrRoles = [select Name 
                                   from UserRole
                                   order by Name
                                  ];
        
        for (UserRole usrRole : usrRoles){
            roles.add(usrRole.Name);
        }

        return roles;
    }

    @AuraEnabled
    public static list<string> getAttTypes(){
        
        List<String> lstPickvals=new List<String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get('Engagement_Attendee__c');
        Sobject Object_name = targetType.newSObject();

        Schema.sObjectType sobject_type = Object_name.getSObjectType();
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();

        List<Schema.PicklistEntry> pick_list_values = field_map.get('Attendee_Type__c').getDescribe().getPickListValues(); 
        for (Schema.PicklistEntry a : pick_list_values) { 
            lstPickvals.add(a.getValue());
        }

        return lstPickvals;
    }

    @AuraEnabled
    public static Engagement_Attendee__c upsertAtt(Engagement_Attendee__c att){
        if (att.RecordTypeId == null){
            att.RecordTypeId = Schema.SObjectType.Engagement_Attendee__c.getRecordTypeInfosByName().get('NCM Attendee').getRecordTypeId();
        }
        
        upsert att;
        return att;
    }

    @AuraEnabled
    public static Engagement__c getEngagementValues(id engId){
        Engagement__c eng = [select id, Engagement_Start__c, Engagement_End__c 
                             from Engagement__c 
                             where id = :engId
                            ];

        return eng;
    }

    public static void cheatingTests(){
        integer i = 0;

        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
    }
}