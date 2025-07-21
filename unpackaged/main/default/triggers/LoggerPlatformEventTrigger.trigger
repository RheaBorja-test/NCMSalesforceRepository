/*
Author: Derrick Chavez
Date:   9.29.2023
Description: Creates records to Error Logger object after an ExceptionLogEvent record is created. 
*/
trigger LoggerPlatformEventTrigger on ExceptionLogEvent__e (after insert) {

    System.debug('~~~LoggerPlatformEventTrigger is firing....');
    // List to hold all Error Logs to be created. 
    List<Error_Logger__c> errorLogs = new List<Error_Logger__c>();

    // Iteretate through each notification.
    for(ExceptionLogEvent__e event : Trigger.new) {

        Error_Logger__c eLogger = new Error_Logger__c();
            eLogger.Source__c =  event.Source__c;
            eLogger.Severity__c = event.Severity__c;
            eLogger.User_Name__c = event.User_Name__c;
            eLogger.Error_Type__c = event.Error_Type__c;
            eLogger.Error_Message__c = event.Error_Message__c;
            eLogger.Stack_Trace__c = event.Stack_Trace__c;
            eLogger.Date_Time__c = event.Date_Time__c;
            eLogger.Record_ID__c = event.Record_ID__c;
            eLogger.Description__c = event.Description__c;
        errorLogs.add(eLogger);

    }

    // System.debug('LoggerPlatformEventTrigger Error List Size: ' + errorLogs.size());
    // Insert all errors corresponding to the events received.
    if (!errorLogs.isEmpty()) {

        System.debug('~~~LoggerPlatformEventTrigger Error List is NOT EMPTY: ');
        insert errorLogs;

    } else {
        System.debug('~~~LoggerPlatformEventTrigger Error List is Empty.');
    }        
}