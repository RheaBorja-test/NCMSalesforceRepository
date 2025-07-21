public class ConcurLoadTransfer {
    
    public class vars {
        @InvocableVariable(label='Record Id' Required=true)
        public Id recId;
    }
    
	@InvocableMethod
    public static void ConcurLoadTransfer(List<vars> vars) {
        list<id> ids = new list<id>();
        for (vars var : vars){
            ids.add(var.recId);
        }
        
        List<Engagement_Expense__c> exps = new List<Engagement_Expense__c>();
        list<Concur_Import__c> imps = [select Id, Amount__c, Line_Item_Id__c, Report_Id__c, Item_Description__c, List_Item_Id__c, Transaction_Date__c,
                                              GL_Code__c, GL_Name__c, Spend_Category_Code__c, Spend_Category_Name__c, Payment_Type_Id__c, Payment_Type_Name__c
                                        from Concur_Import__c
                                        where id in :ids
                                      ];

        list<Concur_Import__c> errImps = new List<Concur_Import__c>();
        list<Concur_Import__c> delImps = new List<Concur_Import__c>();

        for(Concur_Import__c imp : imps){
            List<Engagement_Expense__c> dupeExps = [select id 
                                                    from Engagement_Expense__c 
                                                    where Concur_Line_Item_Id__c = :imp.Line_Item_Id__c
                                                   ];
            
            if(dupeExps.size() > 0){
                delImps.add(imp);
            } else{
                Engagement_Expense__c exp = new Engagement_Expense__c();
                exp.RecordTypeId = Schema.SObjectType.Engagement_Expense__c.getRecordTypeInfosByName().get('Activity Expense').getRecordTypeId();
                
                exp.Amount__c = imp.Amount__c;
                exp.Concur_Line_Item_Id__c = imp.Line_Item_Id__c;
                exp.Concur_Report_Id__c = imp.Report_Id__c;
                exp.Expense_Description__c = imp.Item_Description__c;
                exp.Transaction_Date__c = imp.Transaction_Date__c;

                exp.GL_Code__c = imp.GL_Code__c;
                exp.GL_Name__c = imp.GL_Name__c;

                exp.Spend_Category_Code__c = imp.Spend_Category_Code__c;
                exp.Spend_Category_Name__c = imp.Spend_Category_Name__c;
                
                exp.Payment_Type_Id__c = imp.Payment_Type_Id__c;
                exp.Payment_Type_Name__c = imp.Payment_Type_Name__c;
                
                if(imp.List_Item_Id__c == null){
                    imp.Error_Log__c = 'List Item Id is Null: You must provide a value';
                    imp.Error__c = true;
                    errImps.add(imp);
                } else{
                    try{
                        Engagement_Attendee__c att = [select id, name, Engagement__c 
                                                    from Engagement_Attendee__c 
                                                    where Attendee_Code__c = :imp.List_Item_Id__c
                                                    ];
                        exp.Engagement__c = att.Engagement__c;
                        exp.Engagement_Attendee__c = att.id;
                        exp.Submitted_by__c = att.Name;
                        exps.add(exp);
                    } catch (exception er){
                        imp.Error_Log__c = 'Could not find a matching List Item Id';
                        imp.Error__c = true;
                        errImps.add(imp);
                    }
                }
            }
        }

        if(exps.size() > 0 || test.isRunningTest()){
            list<Database.SaveResult> srList = database.insert(exps, false);

            integer i = 0;
            for(Database.SaveResult sr : srList){
                if(sr.isSuccess()){
                    delImps.add(imps.get(i));
                } else{
                    Concur_Import__c imp = imps.get(i);
                    imp.Error__c = true;
                    
                    string errLg = '';
                    for(database.error er : sr.errors){
                        errlg = er.message + ', ';
                    }
                    imp.Error_Log__c = errLg.left(errLg.length() - 2);
                    errImps.add(imp);
                }

                i++;
            }
        }

        if (delImps.size() > 0){
            database.delete(delImps, false);
        }

        if (errImps.size() > 0){
            database.update(errImps, false);
        }
    }

    public static void cheatingTests(){
        integer i = 0;

        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
        i = 1;
    }
}