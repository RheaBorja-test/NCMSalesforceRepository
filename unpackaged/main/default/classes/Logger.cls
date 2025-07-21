/*
Author: Derrick Chavez
Date:   9.29.2023
Description: This class will contain several methods to log exceptions to the custom object Error_Logger__c.
*/
global class Logger {


    
    // Simple overload that provides a cleaner method name. We're making this Invocable from Flows as well: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_InvocableMethod.htm
    @InvocableMethod(label='Log Errror' description='Log information to the Error Logger object.')
    public static void logErrorInvocable(List<InvocableLogParams> loggingParams){
        
        InvocableLogParams param = loggingParams[0]; 
        
        // Call the logError() method and pass our invocableVariables to it from the flow.
        logError(
        	param.source,
            param.severity,
            param.userName,
            param.errorType,
            param.errorMessage,
            param.stackTrace
        );
    }
    
    global class InvocableLogParams{
        @InvocableVariable(required=true)
        global String source;
        @InvocableVariable(required=true)
        global String errorMessage;
        @InvocableVariable(required=true)
        global String severity;
        @InvocableVariable
        global String userName;
        @InvocableVariable
        global String errorType;
        @InvocableVariable
        global String stackTrace;
    }
        
    
    public static void logError(String source, String severity, String userName, String errorType, String errorMessage, String stackTrace){
        logErrorEvent(source, severity, userName, errorType, errorMessage, stackTrace);
    }

    /*
    * Generates a Exceptions Log Platform Event , which will cause the asynchronous 
    * creation of a Exceptin Log Platform Event record. (ExceptionLogEvent__e)
    * Publish Events Messaging using APEX.
    */

    //Adding an overload so passing Record Id is available, but not required
    public static void logErrorEvent(String source, String severity, String userName, String errorType, String errorMessage, String stackTrace) {
        logErrorEvent(source, severity, userName, errorType, errorMessage, stackTrace, null);
    }


    public static void logErrorEvent(String source, String severity, String userName, String errorType, String errorMessage, String stackTrace, String recordid) {

        System.debug('Logger.logErrorEvent method is firing.....');
        /*
        System.debug('Logger.logErrorEvent method: Source: ' + source);
        System.debug('Logger.logErrorEvent method: Severity: ' + severity);
        System.debug('Logger.logErrorEvent method: UserName: ' + userName);  
        System.debug('Logger.logErrorEvent method: Error Type: ' + errorType);  
        System.debug('Logger.logErrorEvent method: Error Message: ' + errorMessage); 
        System.debug('Logger.logErrorEvent method: Stack Trace: ' + stackTrace);
        */

        // List to hold event objects to be published.
        List<ExceptionLogEvent__e> eventList = new List<ExceptionLogEvent__e>();

        // Create and publish Exception Log Event.
        ExceptionLogEvent__e logEvent = new ExceptionLogEvent__e();
            logEvent.Source__c = source;
            logEvent.Severity__c = severity;
            logEvent.User_Name__c = userName;
            logEvent.Error_Type__c = errorType;
            logEvent.Error_Message__c = errorMessage;
            logEvent.Stack_Trace__c = stackTrace;
            logEvent.Date_Time__c = DateTime.Now();
            logEvent.Record_ID__c = recordId; 
        eventList.add(logEvent);
        ebPublish(eventList);
    }

    public static void ebPublish(List<ExceptionLogEvent__e> eventList) {

        // Call method to publish events.
        List<Database.SaveResult> results = EventBus.publish(eventList);
        
        // Inspect publishing result for each event. 
        for(Database.SaveResult sr : results) {

            if (sr.isSuccess()) {

                System.debug('SUCCESSFULLY PUBLISHED EVENT'); 

            } else {  

                for(Database.Error err : sr.getErrors()) {
                    System.debug('ERROR RETURNED: ' + err.getStatusCode() + ' - ' + err.getMessage());                
                }
            }
        } 
    } 

    public static void logErrorList(String source, List<Database.SaveResult> dsrList, List<SObject> obList) {
        List<ExceptionLogEvent__e> eventList = new List<ExceptionLogEvent__e>();
        for(Integer i = 0; i < dsrList.size(); i++) {

            if(!dsrList[i].isSuccess()) {

                // Create and publish Exception Log Event.
                ExceptionLogEvent__e logEvent = new ExceptionLogEvent__e();
                    logEvent.Source__c = source;
                    logEvent.Severity__c = null;
                    logEvent.User_Name__c = UserInfo.getName();
                    logEvent.Error_Type__c = dsrList[i].getErrors()[0].getStatusCode().Name();
                    logEvent.Error_Message__c = dsrList[i].getErrors()[0].getMessage();
                    logEvent.Stack_Trace__c = JSON.serializePretty(obList[i]);
                    logEvent.Date_Time__c = DateTime.Now();
                    logEvent.Record_ID__c = obList[i].Id; 
                eventList.add(logEvent);
                System.debug('~~~Error Message: ' + logEvent.Error_Message__c);
            }
        }
        if(eventList.size() > 0) {
            ebPublish(eventList);
        }
    }

    public static void logDeleteErrorList(String source, List<Database.DeleteResult> dsrList, List<SObject> obList) {
        List<ExceptionLogEvent__e> eventList = new List<ExceptionLogEvent__e>();
        for(Integer i = 0; i < dsrList.size(); i++) {

            if(!dsrList[i].isSuccess()) {

                // Create and publish Exception Log Event.
                ExceptionLogEvent__e logEvent = new ExceptionLogEvent__e();
                    logEvent.Source__c = source;
                    logEvent.Severity__c = null;
                    logEvent.User_Name__c = UserInfo.getName();
                    logEvent.Error_Type__c = dsrList[i].getErrors()[0].getStatusCode().Name();
                    logEvent.Error_Message__c = dsrList[i].getErrors()[0].getMessage();
                    logEvent.Stack_Trace__c = JSON.serializePretty(obList[i]);
                    logEvent.Date_Time__c = DateTime.Now();
                    logEvent.Record_ID__c = obList[i].Id; 
                eventList.add(logEvent);
                System.debug('~~~Error Message: ' + logEvent.Error_Message__c);
            }
        }
        if(eventList.size() > 0) {
            ebPublish(eventList);
        }
    }

    public static void logException(String source, Id objId, Exception ex) {
        ExceptionLogEvent__e logEvent = new ExceptionLogEvent__e();
                    logEvent.Source__c = source;
                    logEvent.Severity__c = null;
                    logEvent.User_Name__c = UserInfo.getName();
                    logEvent.Error_Type__c = ex.getTypeName();
                    logEvent.Error_Message__c = ex.getMessage();
                    logEvent.Stack_Trace__c = ex.getStackTraceString();
                    logEvent.Date_Time__c = DateTime.Now();
                    logEvent.Record_ID__c = objId; 
                    logEvent.Description__c = 'Line #: ' + String.valueOf(ex.getLineNumber());
        ebPublish(new List<ExceptionLogEvent__e>{logEvent});           
    }
   
    /* // Convert the value of the Enum (Severity) to String
    public static String convertEnumToString(ErrorSeverityEnum enumValue) {

        System.debug('Logger.convertEnumToString method is firing.....');
        return enumValue.name();

    } */

    /* Takes the APEX or Flow exception messages and passes the message as a parameter to throwCustomException method.
       This still needs a little work and it was working with Flows, but since we are not working with Flow Logging at the 
       moment, I decided to comment this out for a later time. - Derrick 9.19.2023
    public class CustomException extends Exception { }
     
        @invocableMethod(label = 'Invoke Logger')
        public static void throwCustomException(List<String> exMessage) {

            throw new CustomException( 'An internal exception happended during the current operation.' + 
                                       'Please contact System Administrator with these Exception Details: ' + exMessage[0] );
    } 
    */

} // End of Logger class