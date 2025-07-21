@isTest (SeeAllData = true)
public class batchSINarReconcileTest {
    public static testMethod void TestbatchSINarReconcile() {
		test.startTest();

        user usr = [select id from User where alias = 'sfadmin' limit 1];

        system.runAs(usr){
            Finance_Accounts_Receivable__c AR = [select id, Sales_Invoice__c 
                                                 from Finance_Accounts_Receivable__c 
                                                 where Sales_Invoice__r.c2g__InvoiceStatus__c = 'Complete' and Sales_Invoice__r.c2g__PaymentStatus__c <> 'Paid' 
                                                 limit 1];

            AR.Outstanding_Value__c = 0;
            update AR;

            batchSINarReconcile batchBrd = new batchSINarReconcile();
            database.executebatch(batchBrd,1);
        }
    }
}