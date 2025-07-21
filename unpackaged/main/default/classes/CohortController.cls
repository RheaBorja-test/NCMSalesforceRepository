public with sharing class CohortController {
    
    @AuraEnabled
    public static List<Cohort__c> getOpenCohorts(String recType){
        
        List<Cohort__c> results = new List<Cohort__c>();
        try {
            results = [SELECT 
                        Id,
                        Name,
                        Start_Date__c,
                        End_Date__c,
                        Available_Seats__c,
                        Cancelled_Students__c,
                        Capacity__c,
                        Graduated_Students__c,
                        Learning_Plan__c,
                        Number_of_Students__c
                        FROM Cohort__c
                        WHERE (Start_Date__c = THIS_MONTH OR Start_Date__c > TODAY) 
                            AND Available_Seats__c > 0
                       		AND RecordTypeId = :recType
                        ORDER BY Start_Date__c];
            return results;
        } catch (Exception e) {
            //Logger.logError('CohortController', 'Error', UserInfo.getUserName(), 'Apex', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
}