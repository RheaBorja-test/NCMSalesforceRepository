public with sharing class GroupMemberUtility {
    @InvocableMethod(Label='Get Also')
    public static List<String> getAlso(List<String> AcctId) {
        String alsos = '';
        Account a = [SELECT Id, Name, 
                        (SELECT Id, Group_Member_Number__c, Statement_Translation_Type__c FROM X20_Groups_Members__r), 
                        (SELECT Id, Group_Member_Number__c, Statement_Translation_Type__c FROM Proprietary_Accounts__r) 
                    FROM Account
                    WHERE Id =  :AcctId[0]];
        for(X20_Groups_Member__c gm : a.X20_Groups_Members__r) {
            alsos += gm.Group_Member_Number__c + ' ' + gm.Statement_Translation_Type__c + '\n';
        }
        for(Proprietary_Account__c pa : a.Proprietary_Accounts__r) {
            alsos += pa.Group_Member_Number__c + ' ' + pa.Statement_Translation_Type__c + '\n';
        }
        alsos = alsos.removeEnd('\n');
        alsos = alsos.abbreviate(255);
        return new List<String>{alsos};
    }
}