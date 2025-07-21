public without sharing class GetRecordName
{
    @InvocableMethod
    public static List<String> getRecordNameById(List<Id> recIds)
    {
        List<String> returnNames = new List<String>();
        for ( Id recordId : recIds )
        {
            Schema.SObjectType sobjectType = recordId.getSObjectType();
            string objectAPIname = sobjectType.getDescribe().getLabel();
            String query = 'SELECT Id, Name FROM ' + objectAPIname + ' WHERE Id = \'' + recordId + '\'';

            SObject sObj = Database.query(query);
            String recName = (String) sObj.get('Name');
            returnNames.add(recName);
        }
        return returnNames;
    }

}