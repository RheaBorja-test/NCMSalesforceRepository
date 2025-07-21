public with sharing class loadSwitchRecord
{
	public class Var
	{
		@InvocableVariable(label = 
		'Record ID'Required = true)
		public Id recId;

		@InvocableVariable(label = 
		'Load Switch API Name'Required = true)
		public String fieldName;

	}

	@InvocableMethod
	public static void loadSwitchGivenRecord(List<var> vars)
	{
		List<sObject> udpateSObjects = new List<sObject>();
		for ( var v : vars )
		{
			String query = 'SELECT Id,' + v.fieldName + ' FROM ' + v.recId.getSobjectType().getDescribe().name + ' WHERE Id = \'' + v.recId + '\'';
			sObject sObj = Database.query(query).get(0);

			Boolean loadSwitch = ( Boolean )sObj.get(v.fieldName);

			sObj.put(v.fieldName, !loadSwitch);
			udpateSObjects.add(sObj);
		}

		if ( udpateSObjects.size() > 0 )
		{
			Database.update( udpateSObjects, FALSE );
		}
	}
}