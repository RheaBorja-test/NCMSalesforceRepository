@RestResource(urlMapping='/ChargeZoom/*')
global class ChargeZoomWHService {
    
    @HttpPost
    global static void processPayment() {
        String secret = CZWebhook__c.getInstance().Token__c;
        RestRequest req = RestContext.request;
        RestResponse resp = RestContext.response;
        
        //check for correct token 
        if(req.headers.containsKey('Token') && req.headers.get('Token') == secret) {
            System.debug('Authenticated');
            System.debug(req.remoteAddress);
        } else {
            resp.statusCode = 401;
            resp.responseBody = Blob.valueOf('{"status":"error","message":"Not Authorized"}');
            return;
        }

        //log webhook payload
        Webhook_Log__c whl = new Webhook_Log__c();
        try {
            String reqBody = req.requestBody.toString();
            
            whl.source__c = 'ChargeZoomWHService';
            whl.data__c = reqBody;
            
            CZ_WebhookPayload pl = (CZ_WebhookPayload) JSON.deserializeStrict(reqBody, CZ_WebhookPayload.class);
            whl.ChargeZoomId__c = pl.data.tnxID;
            resp.statusCode = 200;
            resp.responseBody = Blob.valueOf('Success');

            //Create list of possible success messages from custom label
            List<String> successes = System.Label.CZSuccesses.toUpperCase().split(',');
            List<String> successes2 = new List<String>();
            for(String s : successes) {
                successes2.add(s.normalizeSpace());
            }

            //check if not a successful payment
            if(!pl.data.tnxType.equalsIgnoreCase('Sale') || !successes2.contains(pl.data.tnxStatus.toUpperCase())) {
                return;
            }
            CZ_WebHook__e whEvent = convertToEvent(pl.data);            

            //check if a webhook with the same txId has been processed or not.            
            String qry = 'SELECT Id FROM Webhook_Log__c WHERE ChargeZoomId__c = \'' + pl.data.tnxID + '\'';
            System.debug('~~~qry: ' + qry);

            List<Webhook_Log__c> existing = Database.query(qry);
            System.debug('~~~existing: ' + existing);

            if(existing.isEmpty()) {
                Database.SaveResult dsr = EventBus.publish(whEvent);
                if(!dsr.isSuccess()) {
                    resp.statusCode = 400;
                    resp.responseBody = Blob.valueOf('{"error": "' + dsr.getErrors()[0].getMessage() + '"}');
                    System.debug(dsr.getErrors()[0].getMessage());
                    whl.source__c ='Bad Webhook';
                }
            }            
        } catch (Exception ex) {
            resp.statusCode = 400;
            resp.responseBody = Blob.valueOf('{"error": "' + ex.getMessage() + '"}');
            System.debug(ex.getMessage());
            whl.source__c ='Bad Webhook';
        }
        insert(whl);
    }

    private static CZ_WebHook__e convertToEvent(CZTransactionData tran) {
        PaymentModel.CZTnxCustFields custFields = new PaymentModel.CZTnxCustFields();
            if(tran.tnxCustomDataFields != null) {
                custFields = (PaymentModel.CZTnxCustFields) JSON.deserialize(tran.tnxCustomDataFields, PaymentModel.CZTnxCustFields.class);            
            } 
            CZ_WebHook__e whEvent = new CZ_WebHook__e();
            whEvent.tnxAmount__c = tran.tnxAmount;
            whEvent.tnxID__c = tran.tnxID;
            //Since we are only sending successful transactions to this method, Change the status to match what ApplyPaymentsBatch is expecting.
            whEvent.tnxStatus__c = 'Success'; 
            whEvent.tnxType__c = tran.tnxType;
            whEvent.tnxInvoiceId__c = String.isNotBlank(custFields.invoice_number) ? custFields.invoice_number : tran.tnxInvoiceId; 
            whEvent.tnxInvoiceRef__c = tran.tnxInvoiceRef;
            whEvent.amount_with_out_surcharge__c = custFields.amount_with_out_surcharge;
            whEvent.surcharge_amount_value__c = custFields.surcharge_amount_value;
            return whEvent;
    }

    global class CZ_WebhookPayload {
        global String type {get;set;}
        global CZTransactionData data {get;set;}
    }

    global class CZTransactionData {
        global String tnxID {get;set;}
        global Decimal tnxAmount {get;set;}
        global String tnxDate {get;set;}
        global String tnxStatus {get;set;}
        global String tnxCustomerId {get;set;}
        global String tnxType {get;set;}
        global String tnxGateway {get;set;}
        global String tnxGatewayId {get;set;}
        global Integer tnxPaymentMethod {get;set;}
        global String tnxInvoiceId {get;set;}
        global String tnxInvoiceRef {get;set;}
        global Integer tnxMerchantId {get;set;}
        global String tnxCustomDataFields {get;set;}
        global String id {get;set;}
    }
    
}