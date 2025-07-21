@isTest
public with sharing class CheckRunning_Tests {
    static testMethod void runTest(){
        checkRunning.callingMethod = 'ContactTriggerHandler.copyToUserProfile';
        checkRunning.isFirstRun();
    }
}