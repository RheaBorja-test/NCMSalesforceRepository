//This test class provides coverage for ChargeZoomWHService and 
//CZ_WebhookTrigger.

@isTest 
public class ChargeZoomWHServiceTest {
    @TestSetup
    public static void makeData() {
        insert(new CZWebhook__c(Token__c = '4esz%RDX'));
        insert(new Payment_Polling_Settings__c(Quantity__c = 100, Days_back__c = 0));
        insert(new Surcharge_Journal_Entry__c());
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        c2g__codaCompany__c co = SetCurrentCompany_TEST_DataFactory.createCurrentCompany(
            'NCM Associates, Inc.',
            u,
            null,
            true,
            '12345'
        );
    }

    @isTest
    static void webHookTest1() {
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/ChargeZoom'; 
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json'); 
        req.addHeader('Token', '4esz%RDX'); 
        req.requestBody = Blob.valueOf('{"type":"PAYMENT","data":{"tnxID":"10054566973","tnxAmount":510,"tnxDate":"2024-10-22 12:54:08","tnxCustomerId":"CUS-1729271238-X4OHQ0-247199986","tnxType":"sale","tnxGateway":"1","tnxGatewayId":"6107","tnxPaymentMethod":1,"tnxInvoiceId":"INV-1729600838-0HBS7A-722510867","tnxInvoiceRef":"SIN332649","tnxMerchantId":6011,"tnxCustomDataFields":"{\\"payment_type\\":\\"American Express - 0002\\",\\"invoice_surcharge\\":2,\\"amount_with_out_surcharge\\":500,\\"surcharge_amount_value\\":10,\\"invoiceSurchargeAmt\\":10}","tnxStatus":"SUCCESS","id":"a5fed583a2771f8d69f98f18ab1f4280"}}');
        
        ChargeZoomWHService.CZ_WebhookPayload pl = (ChargeZoomWHService.CZ_WebhookPayload) JSON.deserializeStrict(req.requestBody.toString(), ChargeZoomWHService.CZ_WebhookPayload.class);
        System.debug(pl.type + pl.data.id + pl.data.tnxDate + pl.data.tnxCustomerId + pl.data.tnxGateway + pl.data.tnxGatewayId + pl.data.tnxPaymentMethod + pl.data.tnxMerchantId);

        RestContext.request = req;
        RestContext.response = res;
        
        ChargeZoomWHService.processPayment();
        res = RestContext.response; //Set the response here

        String actual = res.responseBody.toString(); //Convert Blob to String
        String expected = 'Success'; //Your expected output
        System.assertEquals(actual, expected);
        System.assertEquals(200,res.statusCode); 
        Test.stopTest();
    }

    @isTest
    static void webHookTest2() {
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/ChargeZoom'; 
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json'); 
        req.addHeader('Token', '12345'); 
        req.requestBody = Blob.valueOf('{"type":"PAYMENT"}');
        
        RestContext.request = req;
        RestContext.response = res;
        
        ChargeZoomWHService.processPayment();
        res = RestContext.response; //Set the response here

        System.assertEquals(401,res.statusCode);
        Test.stopTest();
    }

    @isTest
    static void webHookTest3() {
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/ChargeZoom'; 
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json'); 
        req.addHeader('Token', '4esz%RDX'); 
        req.requestBody = Blob.valueOf('not json');
        
        RestContext.request = req;
        RestContext.response = res;
        
        ChargeZoomWHService.processPayment();
        res = RestContext.response; //Set the response here

        System.assertEquals(400,res.statusCode); 
        Test.stopTest();
    }

    @isTest
    static void webHookTest4() {
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/ChargeZoom'; 
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json'); 
        req.addHeader('Token', '4esz%RDX'); 
        req.requestBody = Blob.valueOf('{"type":"PAYMENT","data":{"tnxID":"10397967836","tnxAmount":20,"tnxDate":"2025-02-10 14:14:53","tnxCustomerId":"CUS-1729271238-X4OHQ0-247199986","tnxType":"sale","tnxGateway":"1","tnxGatewayId":"6107","tnxPaymentMethod":1,"tnxInvoiceId":"INV-1739196727-RPKF1W-298897121","tnxInvoiceRef":"SIN332757","tnxMerchantId":6011,"tnxCustomDataFields":"{\\"process_page\\":\\"Customer-Multi-Process-Page\\",\\"payment_type\\":\\"Visa - 1111\\",\\"invoice_number\\":\\"INV-1739196016-91ENH0-608128696,INV-1739196727-RPKF1W-298897121\\"}","tnxStatus":"SUCCESS","id":"9e9e0bcbfc8ef839e296584898b15746"}}');
        
        ChargeZoomWHService.CZ_WebhookPayload pl = (ChargeZoomWHService.CZ_WebhookPayload) JSON.deserializeStrict(req.requestBody.toString(), ChargeZoomWHService.CZ_WebhookPayload.class);
        System.debug(pl.type + pl.data.id + pl.data.tnxDate + pl.data.tnxCustomerId + pl.data.tnxGateway + pl.data.tnxGatewayId + pl.data.tnxPaymentMethod + pl.data.tnxMerchantId);

        RestContext.request = req;
        RestContext.response = res;
        
        ChargeZoomWHService.processPayment();
        res = RestContext.response; //Set the response here

        String actual = res.responseBody.toString(); //Convert Blob to String
        String expected = 'Success'; //Your expected output
        System.assertEquals(actual, expected);
        System.assertEquals(200,res.statusCode); 
        Test.stopTest();
    }

}