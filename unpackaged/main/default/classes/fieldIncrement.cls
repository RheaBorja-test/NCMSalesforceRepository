public class fieldIncrement {
    
    public class vars {
        @InvocableVariable(label='Record Id' Required=true)
        public Id recId;
        @InvocableVariable(label='Field API' Required=true)
        public string fldNm;
        @InvocableVariable(label='Decrement?' Required=false)
        public boolean decrement ;
    }
    
    @InvocableMethod
    public static void incrementField(List<vars> vars){
        list<SObject> records = new list<SObject>();
        for (vars var : vars){
            Schema.SObjectType sobjectType = var.recId.getSObjectType();
            String sobjectName = sobjectType.getDescribe().getName();
            SObject record = Database.query('Select Id, Name,' + var.fldNm + ' From ' + sobjectName + ' Where Id = \'' + var.recId + '\'');
            integer i;
            if (record.get(var.fldNm) == null){
                i = 0;
            }
            else{
                i = integer.valueof(record.get(var.fldNm));
            }
            
            if (var.decrement == true){
                i--;
            } else {
                i++;
            }
            record.put(var.fldNm, i);
            
            records.add(record);
        }
        
        if (records.size()> 0){
            Database.SaveResult[] results = Database.update(records, false);
        }
    }
    
}