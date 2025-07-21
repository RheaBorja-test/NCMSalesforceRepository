@IsTest
public class InvocableBatchSendInvoicesTest {
    @IsTest
    static void methodName(){
        Id z;
        List<Id> y = new List<Id>{z};
        List<List<Id>> x = new List<List<Id>>{y};
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());
        Test.startTest();
        InvocableBatchSendInvoices.InvocableBatchSendInvoices(x);
        Test.stopTest();
        
    }
}