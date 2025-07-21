@isTest
private class LoggerTest {

    @isTest
    static void errorLoggerTest() {

        //logErrorEvent(String source, String severity, String userName, String errorType, String errorMessage, String stackTrace)
        Test.startTest();
            Logger.logError('LoggerTest.errorLoggerTest', 'ERROR', 'Test User', 'MyErrorType', 'MyErrorMessage', 'MyStackTrace');
        Test.stopTest();

        // Query custom error log records (BULK)
        List<Error_Logger__c> errorLogs = [SELECT Id, Source__c, Severity__c, User_Name__c, Error_Type__c, Error_Message__c, Stack_Trace__c 
                                           FROM Error_Logger__c];

        // Assert the error log records were created with the expected results
        System.debug('Logger.errorLoggerTest: Size: ' + errorLogs.size());
        System.assertEquals(1, errorLogs.size());

        // Assert the error log record messages were created with the expected results
        System.assertEquals('LoggerTest.errorLoggerTest', errorLogs[0].Source__c);
        System.assertEquals('Error', errorLogs[0].Severity__c);
        System.assertEquals('Test User', errorLogs[0].User_Name__c);
        System.assertEquals('MyErrorType', errorLogs[0].Error_Type__c);
        System.assertEquals('MyErrorMessage', errorLogs[0].Error_Message__c);
        System.assertEquals('MyStackTrace', errorLogs[0].Stack_Trace__c);
        
    }

    @isTest
    static void logListTest() {
        List<Account> lst = new List<Account>{new Account()};
        
        List<Database.SaveResult> dsrs = Database.insert(lst, false);
        Test.startTest();
            Logger.logErrorList('Test of List', dsrs, lst);
        Test.stopTest();

        // Query custom error log records (BULK)
        List<Error_Logger__c> errorLogs = [SELECT Id, Source__c, Severity__c, User_Name__c, Error_Type__c, Error_Message__c, Stack_Trace__c 
                                           FROM Error_Logger__c];

        // Assert the error log records were created with the expected results
        System.debug('Logger.errorLoggerTest: Size: ' + errorLogs.size());
        System.assertEquals(1, errorLogs.size());

        // Assert the error log record messages were created with the expected results
        System.assertEquals('Test of List', errorLogs[0].Source__c);
        System.assertEquals(UserInfo.getName(), errorLogs[0].User_Name__c);
        System.assertEquals('REQUIRED_FIELD_MISSING', errorLogs[0].Error_Type__c);
        System.assertEquals('Required fields are missing: [Name]', errorLogs[0].Error_Message__c);
    }

    @isTest
    static void logExceptionTest() {
        Test.startTest();
            try {
                insert new Account();
            } catch(Exception ex) {
                Logger.logException('Exception Test', null, ex);
            }
        Test.stopTest();
    
        // Query custom error log records
        List<Error_Logger__c> errorLogs = [SELECT Id, Source__c, Severity__c, User_Name__c, Error_Type__c, Error_Message__c, Stack_Trace__c 
        FROM Error_Logger__c];

        // Assert the error log records were created with the expected results
        System.debug('Logger.errorLoggerTest: Size: ' + errorLogs.size());
        System.assertEquals(1, errorLogs.size());

        // Assert the error log record messages were created with the expected results
        System.assertEquals('Exception Test', errorLogs[0].Source__c);
        System.assertEquals(UserInfo.getName(), errorLogs[0].User_Name__c);
        System.assertEquals('System.DmlException', errorLogs[0].Error_Type__c);
    }

    @isTest
    static void errorLoggerInvocableTest() {

        //Set parameters
        List<Logger.InvocableLogParams> ipList = new List<Logger.InvocableLogParams>();
        ipList.add(new Logger.InvocableLogParams());
        ipList[0].source = 'LoggerTest.errorLoggerTest';
        ipList[0].severity = 'ERROR';
        ipList[0].userName = 'Test User';
        ipList[0].errorType = 'MyErrorType';
        ipList[0].errorMessage = 'MyErrorMessage';
        ipList[0].stackTrace = 'MyStackTrace';

        //logErrorEvent(String source, String severity, String userName, String errorType, String errorMessage, String stackTrace)
        Test.startTest();
            Logger.logErrorInvocable(ipList);
        Test.stopTest();

        // Query custom error log records (BULK)
        List<Error_Logger__c> errorLogs = [SELECT Id, Source__c, Severity__c, User_Name__c, Error_Type__c, Error_Message__c, Stack_Trace__c 
                                           FROM Error_Logger__c];

        // Assert the error log records were created with the expected results
        System.debug('Logger.errorLoggerTest: Size: ' + errorLogs.size());
        System.assertEquals(1, errorLogs.size());

        // Assert the error log record messages were created with the expected results
        System.assertEquals('LoggerTest.errorLoggerTest', errorLogs[0].Source__c);
        System.assertEquals('Error', errorLogs[0].Severity__c);
        System.assertEquals('Test User', errorLogs[0].User_Name__c);
        System.assertEquals('MyErrorType', errorLogs[0].Error_Type__c);
        System.assertEquals('MyErrorMessage', errorLogs[0].Error_Message__c);
        System.assertEquals('MyStackTrace', errorLogs[0].Stack_Trace__c);
        
    }
    @isTest
    static void logDeleteListTest() {
        Account act = new Account(Name = 'Test Account');
        insert(act);
        List<Account> lst = new List<Account>{act};
        
        List<Database.DeleteResult> dsrs = Database.delete(lst, false);
        Test.startTest();
            Logger.logDeleteErrorList('Test of List', dsrs, lst);
        Test.stopTest();

        // Query custom error log records (BULK)
        List<Error_Logger__c> errorLogs = [SELECT Id, Source__c, Severity__c, User_Name__c, Error_Type__c, Error_Message__c, Stack_Trace__c 
                                           FROM Error_Logger__c];

        // Assert the error log records were created with the expected results
        System.debug('Logger.errorLoggerTest: Size: ' + errorLogs.size());
        System.assertEquals(0, errorLogs.size());
    }
}