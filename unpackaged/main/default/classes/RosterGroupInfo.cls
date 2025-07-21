public with sharing class RosterGroupInfo {
    public String groupNumber { get; set; }
    public String groupName { get; set; }
    public Integer memberCount {get;set;}
    public String errorMessages {get;set;}
    public Integer candidateCount {get;set;}
    public String moderatorName { get; set; }
    public String moderatorEmail { get; set; }
    public String moderatorMobile { get; set; }
    public String coordinatorName { get; set; }
    public String coordinatorEmail { get; set; }
    public String meetingSupportName { get; set; }
    public String meetingSupportEmail { get; set; }
    public String listserv { get; set; }
    public List<Map<String, String>> members { get; set; }
    public List<Map<String, String>> candidates { get; set; }
    public List<Engagement__c> engagements { get; set; }

    public RosterGroupInfo(ApexPages.StandardController sc) {
        groupNumber = Apexpages.currentPage().getParameters().get('group').escapeHtml4();
		
        // Determine if group is 20G or Prop
        if (
            Database.countQuery(
                'SELECT COUNT() FROM Twenty_Groups__c WHERE Status__c IN (\'Active\', \'New Group - Prospecting\') AND Name = :groupNumber '
            ) > 0
        ) {
            // 20G query not empty, trying 20G
            twentyGroupInfo(this);
        } else {
            // 20G query empty, trying prop
            propGroupInfo(this);
        }
    }

    @testVisible
    private static void twentyGroupInfo(RosterGroupInfo rgi) {
        List<Map<String, String>> groupMembers = new List<Map<String, String>>();
        List<Map<String, String>> groupCandidates = new List<Map<String, String>>();
        List<Twenty_Groups__c> twentyGroupResults = [SELECT Id, 
                                                            Name,
                                                            Group_Name__c,
                                                            Group_Email_Address_Members__c,
                                                            NCM_Proprietor__r.Name,
                                                            NCM_Proprietor__r.Email,
                                                            NCM_proprietor__r.User_ID__r.MobilePhone,
                                                            NCM_Support_Staff__r.Name,
                                                            NCM_Support_Staff__r.Email, 
                                                            Meeting_Support_Contact__r.Name,
                                                            Meeting_Support_Contact__r.Email
                                                    FROM  Twenty_Groups__c
                                                    WHERE Status__c IN ('Active', 'New Group - Prospecting') 
                                                    AND   Name = :rgi.groupNumber  
                                                    ORDER BY Start_Date__c LIMIT 1                                              
                                                    ];
		
        if(!twentyGroupResults.isEmpty()){
            Twenty_Groups__c groupInfo = twentyGroupResults[0];
            rgi.groupName = groupInfo.Group_Name__c;
            rgi.moderatorName = groupInfo.NCM_Proprietor__r.Name;
            rgi.moderatorEmail = groupInfo.NCM_Proprietor__r.Email;
            rgi.moderatorMobile = groupInfo.NCM_proprietor__r.User_ID__r.MobilePhone;
            rgi.coordinatorName = groupInfo.NCM_Support_Staff__r.Name;
            rgi.coordinatorEmail = groupInfo.NCM_Support_Staff__r.Email;
            rgi.listserv = groupInfo.Group_Email_Address_Members__c;
            rgi.meetingSupportName = groupInfo.Meeting_Support_Contact__r.Name;
            rgi.meetingSupportEmail = groupInfo.Meeting_Support_Contact__r.Email;
        
            List<X20_Group_Member_Contact__c> contacts = [SELECT Contact__r.Name,
                                                                 Member_Nickname__c,
                                                                 Member_Email__c,
                                                                 X20_Groups_Member__r.Member_Number__c,
                                                                 X20_Groups_Member__r.Account__r.Name, 
                                                                 X20_Groups_Member__r.Account__r.ShippingStreet,
                                                                 X20_Groups_Member__r.Account__r.ShippingCity,
                                                                 X20_Groups_Member__r.Account__r.ShippingStateCode,
                                                                 X20_Groups_Member__r.Account__r.ShippingPostalCode,
                                                                 X20_Groups_Member__r.Member_Phone__c,
                                                                 X20_Groups_Member__r.Account__r.Website,
                                                                 X20_Groups_Member__r.Type__c
                                                            FROM X20_Group_Member_Contact__c
                                                            WHERE Contact_Type__c = 'Member' 
                                                                AND Contact_Status__c = 'Active'
                                                                AND X20_Groups_Member__r.Status__c NOT IN ('Rejected', 'Disconnected', 'On Hold')
                                                                AND X20_Groups_Member__r.Type__c IN ('Full Member', 'Candidate', 'Additional_Store')
                                                                AND X20_Group__c = :groupInfo.Id
                                                            ORDER BY X20_Groups_Member__r.Member_Number__c, Display_Order__c
                                                            ];
            Decimal member = 9999.0;
            integer i = 0;
            String name = '';
            String email = '';
            String type = '';
            //Integer members = 0;
            //Integer candidates = 0;
        	Map<String, String> mem = new Map<String, String>();
            for (X20_Group_Member_Contact__c contact : contacts) {
                if (member != contact.X20_Groups_Member__r.Member_Number__c) {
                    if (member != 9999.0) {
                        mem.put('contactNames', name);
                        mem.put('contactEmails', email);
                        if (type == 'Candidate') {
                            groupCandidates.add(mem);
                        } else {
                            groupMembers.add(mem);
                        }
                    }
                    mem = new Map<String, String>();
                    name = '';
                    email = '';
                    type = '';
                    i = 0;
                    member = contact.X20_Groups_Member__r.Member_Number__c;
                    mem.put(
                        'number',
                        String.valueOf(contact.X20_Groups_Member__r.Member_Number__c)
                        .leftPad(2, '0')
                    );
                    mem.put('name', nullCheck(contact.X20_Groups_Member__r.Account__r.Name));
                    mem.put('street',nullCheck(contact.X20_Groups_Member__r.Account__r.ShippingStreet));
                    mem.put('city',nullCheck(contact.X20_Groups_Member__r.Account__r.ShippingCity));
                    mem.put('state',nullCheck(contact.X20_Groups_Member__r.Account__r.ShippingStateCode));
                    mem.put('zip',nullCheck(contact.X20_Groups_Member__r.Account__r.ShippingPostalCode));
                    mem.put('phone','<b>' + nullCheck(contact.X20_Groups_Member__r.Member_Phone__c) + '</b><br /><br />' + nullCheck(contact.X20_Groups_Member__r.Account__r.Website));
                }
                name +=
                    (i == 0 ? '' : '<br />') +
                    (contact.Contact__r.Name == null ? '--' : contact.Contact__r.Name) +
                    (contact.Member_Nickname__c == null
                     ? ''
                     : ' <b>(' + contact.Member_Nickname__c + ')</b>');
                email += (i == 0 ? '' : '<br />') + nullcheck(contact.Member_Email__c);
                type = nullcheck(contact.X20_Groups_Member__r.Type__c);
                i++;
            }
            mem.put('contactNames', name);
            mem.put('contactEmails', email);
            if (type == 'Candidate') {
                groupCandidates.add(mem);
            } else {
                groupMembers.add(mem);
            }
            rgi.members = groupMembers;
            rgi.candidates = groupCandidates;
            rgi.memberCount = rgi.members.size();
            rgi.candidateCount = rgi.candidates.size();
        
            List<Engagement__c> groupEngagements = [SELECT
                                                         Id,
                                                         Confirmed_Hotel__r.Name,
                                                         Engagement_Start_Date__c,
                                                         Engagement_End_Date__c,
                                                         Status__c,
                                                         Confirmed_Hotel__r.ShippingCity,
                                                         Confirmed_Hotel__r.ShippingStateCode,
                                                         City__c,
                                                         State_pl__c
                                                    FROM Engagement__c
                                                    WHERE X20_Group__r.Name = :rgi.groupNumber
                                                    AND  Status__c IN ('Firm', 'Tentative')
                                                    ORDER BY Engagement_Start_Date__c LIMIT 3
                                                   ];
                                                   rgi.engagements = groupEngagements;
        } else {
            rgi.errorMessages = 'No 20 Group found with that number.';
        }
    }

    private static void propGroupInfo(RosterGroupInfo rgi) {
        List<Map<String, String>> groupMembers = new List<Map<String, String>>();
        List<Proprietary_Group__c> propGroupResults = [ SELECT
                                                             Group_Number__c,
                                                             Group_Name__c,
                                                             Group_Owner__r.Name,
                                                             Group_Owner__r.Email,
                                                             Group_Owner__r.User_ID__r.MobilePhone,
                                                             Support_Staff__r.Name,
                                                             Support_Staff__r.Email,
                                                             Group_List_Serv__c,
                                                             Meeting_Support_Contact__r.Name,
                                                             Meeting_Support_Contact__r.Email,
                                                       		 Group_Email_Address_Members__c
                                                        FROM Proprietary_Group__c
                                                        WHERE Status__c = 'Active' AND Name = :rgi.groupNumber
                                                        ORDER BY Start_Date__c
                                                        LIMIT 1
                                                    ];
        if(!propGroupResults.isEmpty()){
             Proprietary_Group__c propGroupInfo = propGroupResults[0];
            rgi.groupName = propGroupInfo.Group_Name__c;
            rgi.moderatorName = propGroupInfo.Group_Owner__r.Name;
            rgi.moderatorEmail = propGroupInfo.Group_Owner__r.Email;
            rgi.moderatorMobile = propGroupInfo.Group_Owner__r.User_ID__r.MobilePhone;
            rgi.coordinatorName = propGroupInfo.Support_Staff__r.Name;
            rgi.coordinatorEmail = propGroupInfo.Support_Staff__r.Email;
            rgi.meetingSupportName = propGroupInfo.Meeting_Support_Contact__r.Name;
            rgi.meetingSupportEmail = propGroupInfo.Meeting_Support_Contact__r.Email;

            if (propGroupInfo.Group_List_Serv__c == true) {
                rgi.listserv = propGroupInfo.Group_Email_Address_Members__c;
            }
            List<Proprietary_Account_Contact__c> contacts = [SELECT
                                                                Contact__r.Name,
                                                                Member_Nickname__c,
                                                                Member_Email__c,
                                                                Proprietary_Account__r.Member_Number__c,
                                                                Proprietary_Account__r.Member_Number_2_Code__c,
                                                                Proprietary_Account__r.Account__r.Name,
                                                                Proprietary_Account__r.Account__r.ShippingStreet,
                                                                Proprietary_Account__r.Account__r.ShippingCity,
                                                                Proprietary_Account__r.Account__r.ShippingStateCode,
                                                                Proprietary_Account__r.Account__r.ShippingPostalCode,
                                                                Proprietary_Account__r.Member_Phone__c,
                                                                Proprietary_Account__r.Account__r.Website
                                                            FROM Proprietary_Account_Contact__c
                                                            WHERE
                                                                Contact_Type__c = 'Member'
                                                                AND Status__c = 'Active'
                                                                AND Proprietary_Account__r.Status__c NOT IN ('Disconnected', 'On Hold')
                                                                AND Proprietary_Group__c = :propGroupInfo.Id
                                                            ORDER BY Proprietary_Account__r.Member_Number_2_Code__c, Display_Order__c
                                                        ];
            String member = 'X';
            integer i = 0;
            String name = '';
            String email = '';
            Map<String, String> mem = new Map<String, String>();
            for (Proprietary_Account_Contact__c contact : contacts) {
                if (member != contact.Proprietary_Account__r.Member_Number__c) {
                    if (member != 'X') {
                        mem.put('contactNames', name);
                        mem.put('contactEmails', email);
                        groupMembers.add(mem);
                    }
                    mem = new Map<String, String>();
                    name = '';
                    email = '';
                    i = 0;
                    member = contact.Proprietary_Account__r.Member_Number__c;
                    mem.put(
                        'number',
                        String.valueOf(contact.Proprietary_Account__r.Member_Number__c)
                        .leftPad(2, '0')
                    );
                    mem.put('name',nullCheck(contact.Proprietary_Account__r.Account__r.Name));
                    mem.put('street',nullCheck(contact.Proprietary_Account__r.Account__r.ShippingStreet));
                    mem.put('city',nullCheck(contact.Proprietary_Account__r.Account__r.ShippingCity));
                    mem.put('state',nullCheck(contact.Proprietary_Account__r.Account__r.ShippingStateCode));
                    mem.put('zip',nullCheck(contact.Proprietary_Account__r.Account__r.ShippingPostalCode));
                    mem.put(
                        'phone',
                        '<b>' +
                        nullCheck(contact.Proprietary_Account__r.Member_Phone__c) +
                        '</b><br /><br />' +
                        nullCheck(contact.Proprietary_Account__r.Account__r.Website));
                }
                name +=
                    (i == 0 ? '' : '<br />') +
                    (contact.Contact__r.Name == null ? '--' : contact.Contact__r.Name) +
                    (contact.Member_Nickname__c == null
                     ? ''
                     : ' <b>(' + contact.Member_Nickname__c + ')</b>');
                email +=
                    (i == 0 ? '' : '<br />') +
                    nullCheck(contact.Member_Email__c);
                i++;
            }
            mem.put('contactNames', name);
            mem.put('contactEmails', email);
            groupMembers.add(mem);
            rgi.members = groupMembers;
            rgi.candidates = new List<Map<String, String>>();
            rgi.memberCount = rgi.members.size();
            rgi.candidateCount = rgi.candidates.size();
        
            List<Engagement__c> groupEngagements = [SELECT
                                                        Confirmed_Hotel__r.Name,
                                                        Engagement_Start_Date__c,
                                                        Engagement_End_Date__c,
                                                        Status__c,
                                                        Confirmed_Hotel__r.ShippingCity,
                                                        Confirmed_Hotel__r.ShippingStateCode,
                                                        City__c,
                                                        State_pl__c
                                                    FROM Engagement__c
                                                    WHERE
                                                        Proprietary_Group__r.Group_Number__c = :rgi.groupNumber
                                                        AND Status__c IN ('Firm', 'Tentative')
                                                        ORDER BY Engagement_Start_Date__c
                                                        LIMIT 3
                                                    ];
            rgi.engagements = groupEngagements;
        } else {
            rgi.errorMessages = 'No proprietary group found.';
        }
        
    }

    
    @TestVisible private static String nullCheck(String value) {
        return value == null ? '' : value;
    }
}