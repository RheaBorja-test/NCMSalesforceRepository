@isTest (SeeAllData = true)
public class batchCollectionActivityTest {
    public static testMethod void TestbatchCollectionActivity() {
		test.startTest();
        
        batchCollectionActivity batch = new batchCollectionActivity();
        database.executebatch(batch,1);
        
        test.stopTest();
    }
}