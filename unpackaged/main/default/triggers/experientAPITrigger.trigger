trigger experientAPITrigger on eContacts__Queue_Item__c (after insert) {
    list<eContacts__Queue_Item__c> scnItms = new list<eContacts__Queue_Item__c>();
    Experient_API__c orgDef = Experient_API__c.getOrgDefaults();
    for(eContacts__Queue_Item__c scnItm : trigger.new){
        if (scnItm.eContacts__Notes__c.containsAny('</a>') && orgDef.Active__c){
            string barcode = scnItm.eContacts__Notes__c;
            barcode = barcode.left(barcode.indexOf('</a>'));
            barcode = barcode.right(barcode.length() - (barcode.indexOf('>') + 1));
            experientAPI.callExperient(scnItm.Id, barcode, UserInfo.getUserId());
        }
    }
}