@isTest (seeAllData = true)
public class experientAPITriggerTest {
    static testMethod void TestexperientAPITrigger(){
        test.startTest();
        
        Experient_API__c usrSett = Experient_API__c.getInstance(UserInfo.getUserId());
        Experient_API__c orgDef = Experient_API__c.getOrgDefaults();
        
        orgDef.Active__c = true;
        orgDef.Test_Mode__c = true;
        
        orgDef.BadgeId__c = '0';
        orgDef.actcode__c = '0000000000000000';
        orgDef.apiKey__c = 'CP-kigOXnoIco6Zl3BKQ53-lnWfToRuoDxUzDkap7pSWnPT5JZ7QR5sxiIYhBQ__';
        orgDef.End_Point__c = 'https://developer.experientswap.com/APIv1/LeadInfo';
        
        usrSett.BadgeId__c = '0';
        usrSett.actcode__c = '0000000000000000';
        usrSett.apiKey__c = 'CP-kigOXnoIco6Zl3BKQ53-lnWfToRuoDxUzDkap7pSWnPT5JZ7QR5sxiIYhBQ__';
        usrSett.End_Point__c = 'https://developer.experientswap.com/APIv1/LeadInfo';
        
        upsert orgDef;
        upsert usrSett;
        
        eContacts__Queue_Item__c scnItm = new eContacts__Queue_Item__c();
        scnItm.eContacts__Notes__c = '<a href="#" onclick="window.open(\'HTTPS://L4E.US/589/1001/ATTENDEE-1001/DEMO-1001/DEMOCOMPANY\', \'_system\', \'location=yes\'); return false;" contenteditable="false" title="HTTPS://L4E.US/589/1001/ATTENDEE-1001/DEMO-1001/DEMOCOMPANY">HTTPS://L4E.US/589/1001/ATTENDEE-1001/DEMO-1001/DEMOCOMPANY</a> Created in Test Class';
        
        insert scnItm;
        
        test.stopTest();
    }
}