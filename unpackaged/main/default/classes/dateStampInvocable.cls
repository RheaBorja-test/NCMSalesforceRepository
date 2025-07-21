public with sharing class dateStampInvocable
{
	public class var
	{
		@InvocableVariable(label = 
		'Record Id'Required = true)
		public Id recId;

		@InvocableVariable(label = 
		'Field API'Required = true)
		public string fldName;

		@InvocableVariable(label = 
		'Completed DateTime'Required = true)
		public DateTime completedDate;

		@InvocableVariable(label = 
		'Format'Required = true)
		public string formatType;

	}

	@InvocableMethod
	public static void dateStampWhatRecord(List<var> vars)
	{
		List<SObject> sObjs = new List<SObject>();

		for ( var v : vars )
		{
			Schema.SObjectType sobjectType = v.recId.getSObjectType();
			String sobjectName = sobjectType.getDescribe().getName();
			SObject record = Database.query('Select Id, Name,' + v.fldName + ' From ' + sobjectName + ' Where Id = \'' + v.recId + '\'');
			record.Id = v.recId;

			if ( v.formatType == 'DateTime' )
			{
				record.put(v.fldName, v.completedDate);
			}
			else
			{
				record.put(v.fldName, Date.valueOf(v.completedDate));
			}

			sObjs.add(record);
		}

		if ( sObjs.size() > 0 )
		{
			Database.update(sObjs, false);
		}
	}
}