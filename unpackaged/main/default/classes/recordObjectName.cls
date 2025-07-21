public with sharing class recordObjectName {
    
    @InvocableMethod
    public static list<string> getObjectAPIName(list<id> recordId){

        List<String> objectNames = new List<String>();
        for(id recId : recordId){
            Schema.SObjectType sobjectType = recId.getSObjectType();
            string objectAPIname = sobjectType.getDescribe().getLabel();
            objectNames.add(objectAPIname);
        }

        return objectNames;
    }
}