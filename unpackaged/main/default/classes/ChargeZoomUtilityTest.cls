@isTest
public with sharing class ChargeZoomUtilityTest {
    @isTest 
    public static void ChargeZoomUtilityTest() {
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());
        ChargeZoomUtility czu = new ChargeZoomUtility();
        Assert.areEqual('test_token123', czu.theToken);
    }

    @isTest 
    public static void createInvoice_Test() {
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());
        ChargeZoomUtility czu = new ChargeZoomUtility();
        PaymentModel.CZCreateInvoiceModel invModel = new PaymentModel.CZCreateInvoiceModel();
        invModel.customerId = 'TestId';
        invModel.invoiceDate = String.valueOf(Date.today());
        invModel.invoiceTotal = 10;
        PaymentModel.czCreateInvoiceResponse invResp = czu.createInvoice(invModel);
        Assert.areEqual(200,invResp.code);
    } 
}