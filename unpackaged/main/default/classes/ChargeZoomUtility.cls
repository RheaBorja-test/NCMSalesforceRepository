public with sharing class ChargeZoomUtility {
    @TestVisible private String theToken = '';
    public class MyException extends Exception {}

    public ChargeZoomUtility() {
        if(String.isBlank(this.theToken)) {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:ChargeZoomDev/authentication/token/create');
            req.setHeader('Accept', 'application/json');
            req.setMethod('POST');
            req.setBody('');
            HttpResponse res = http.send(req);
            String JSONstring = res.getBody();
            if(JSONstring.startsWith('\n<')) {
                logResponse(null, JSONstring.stripHtmlTags(), 'CZ::GenerateToken');
                throw new MyException(JSONstring.stripHtmlTags());
            } else {
                Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(JSONstring);            
                if((Integer) resMap.get('code') == 200) {
                    //if successful then save token
                    this.theToken = (String) resMap.get('token');
                } else {
                    //not successful. log response and throw exception
                    logResponse(null, (String) resMap.get('message'), 'CZ::GenerateToken');
                    throw new MyException((String) resMap.get('message'));
                }
            }
        }
    }

    public PaymentModel.CZCreateCustomerResponse createCustomer(PaymentModel.CZCreateCustomer cust) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ChargeZoomDev/customer/create');
        req.setHeader('token', this.theToken);
        req.setHeader('Accept', 'application/json');
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setBody(JSON.serialize(cust));
        HttpResponse res = http.send(req);
        PaymentModel.CZCreateCustomerResponse createCustResp = (PaymentModel.CZCreateCustomerResponse) JSON.deserialize(res.getBody(), PaymentModel.CZCreateCustomerResponse.class);
        //logResponse(createCustResp.data.customerId, res.getBody(), 'CZ::createCustomer');

        return createCustResp;
    }

    public PaymentModel.CZCreateCustomerResponse editCustomer(PaymentModel.CZCreateCustomer cust, String czCustomerID) {
        String logTag = '[ChargeZoomUtility::editCustomer]';
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        //System.debug(logTag + 'customerID: ' + czCustomerID);
        req.setEndpoint('callout:ChargeZoomDev/customer/edit/' + czCustomerID);
        //System.debug(logTag + 'Endpoint: ' + req.getEndpoint());
        req.setHeader('token', this.theToken);
        req.setHeader('Accept', 'application/json');
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setBody(JSON.serialize(cust));
        //System.debug(logTag + 'Body: ' + req.getBody());
        HttpResponse res = http.send(req);
        PaymentModel.CZCreateCustomerResponse createCustResp = (PaymentModel.CZCreateCustomerResponse) JSON.deserialize(res.getBody(), PaymentModel.CZCreateCustomerResponse.class);
        if(createCustResp.code == 200) logResponse(createCustResp.data.customerId, res.getBody(), 'CZ::editCustomer');
        return createCustResp;
    }

    public PaymentModel.CZCreateCustomerResponse updateCustomerStatus(String czCustomerId, String statusCode){
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ChargeZoomDev/customer/status/'+czCustomerId);
        req.setHeader('token', this.theToken);
        req.setHeader('Accept', 'application/json');
        req.setMethod('POST');
        req.setTimeout(120000);
        //String requestBody = '{"customerActiveStatus":"'+statusCode+'"}';
        PaymentModel.CustomerStatus cust = new PaymentModel.CustomerStatus();
        cust.customerActiveStatus = '1';
        req.setBody(JSON.serialize(cust));
        HttpResponse res = http.send(req);
        PaymentModel.CZCreateCustomerResponse resp = (PaymentModel.CZCreateCustomerResponse) JSON.deserialize(res.getBody(), PaymentModel.CZCreateCustomerResponse.class);
        return resp;
    }
    
    public PaymentModel.czCreateInvoiceResponse createInvoice(PaymentModel.CZCreateInvoiceModel inv) {
        //Make callout to ChargeZoom api, log result(JSON) and return PaymentModel.czCreateInvoiceResponse
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ChargeZoomDev/invoice/create');
        req.setHeader('token', this.theToken);
        req.setHeader('Accept', 'application/json');
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setBody(JSON.serialize(inv, true));
        System.debug('~~~ChargeZoomUtility::createCZInvoice req.body: ' + req.getBody());
        HttpResponse res = http.send(req);
        PaymentModel.czCreateInvoiceResponse invResponse = (PaymentModel.czCreateInvoiceResponse) JSON.deserialize(res.getBody(), PaymentModel.czCreateInvoiceResponse.class);
        /*if(invResponse.code != 200) {
            logResponse(inv.customerId + ' ' + inv.invoiceDate + ' $' + inv.invoiceTotal, res.getBody(), 'CZ::createInvoice');
        } else {
            logResponse(invResponse.data.invoiceId, res.getBody(), 'CZ::createInvoice');
        }*/
        return invResponse;
    }

    Public PaymentModel.CZCreateItemResponse createItem(PaymentModel.CZCreateItem itm) {
        //This method will also update an item
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        if(String.isBlank(itm.itemId)) {
            req.setEndpoint('callout:ChargeZoomDev/products/create');
        } else {
            req.setEndpoint('callout:ChargeZoomDev/products/edit');
        }        
        req.setHeader('token', this.theToken);
        req.setHeader('Accept', 'application/json');
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setBody(JSON.serialize(itm));
        System.debug('~~~endpoint: ' + req.getEndpoint());
        System.debug('~~~body: ' + req.getBody());
        HttpResponse res = http.send(req);
        if(res.getStatusCode() != 200) {
            Logger.logErrorEvent('ChargeZoomUtility::createItem', null, UserInfo.getName(), String.valueOf(res.getStatusCode()), res.getStatus(), req.getBody(), itm.itemId);
        }
        PaymentModel.CZCreateItemResponse rspns = (PaymentModel.CZCreateItemResponse) JSON.deserialize(res.getBody(), PaymentModel.CZCreateItemResponse.class);
        return rspns;
    }

    public static void logResponse(String Id, String jsonString, String source) {
        Webhook_Log__c whl = new Webhook_Log__c(
            ChargeZoomId__c = Id,
            data__c = jsonString,
            Source__c = source
        );
        try {
            insert whl;
        } catch (Exception e) {
            //TODO: Error logging needs to be inserted here.
            System.debug('Error while logging response: ' + jsonString);
        } 
    }

    /* Not used, switched to polling for Transactions(Payments)
    public List<PaymentModel.InvoiceRetrieved> getInvoiceList() {
        //
        //TODO: modify this so it gets paid and partially paid invoices.
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ChargeZoomDev/invoice/all');
        req.setHeader('token', this.theToken);
        req.setHeader('Accept', 'application/json');
        req.setMethod('POST');
        req.setBody('{"page": 0, "limit": 0, "includeItems": 1, "invoiceStatus": "Paid"}');
        HttpResponse res = http.send(req);
        PaymentModel.CZGetInvoicesResponse GetInvResp = (PaymentModel.CZGetInvoicesResponse) JSON.deserialize(res.getBody(), PaymentModel.CZGetInvoicesResponse.class);
        logResponse('List of Invoices', res.getBody(), 'CZ::getInvoiceList');
        return GetInvResp.data;
    }
    */

    //this method creates the invoice model from the Sales Invoice
    public static PaymentModel.CZCreateInvoiceModel generateCZInvoice(c2g__codaInvoice__c sInv) {
        PaymentModel.CZCreateInvoiceModel im = new PaymentModel.CZCreateInvoiceModel();
        im.customerId = sInv.Billing_Account__r.CZ_CustomerId__c;
        im.invoiceDate = String.valueOf(sInv.c2g__InvoiceDate__c);
        im.invoicePaytermDays = (Integer) CZInvoiceTerms__c.getInstance().Days__c;
        //im.invoiceTotal = sInv.c2g__InvoiceTotal__c;
        if(CZProd__c.getInstance().isProd__c) {
            im.invoiceRefNo = sInv.Name;
        }
        im.bAddress1 = sInv.c2g__Account__r.BillingStreet;
        im.bCity = sInv.c2g__Account__r.BillingCity;
        im.bState = sInv.c2g__Account__r.BillingState;
        im.bZipcode = sInv.c2g__Account__r.BillingPostalCode;
        List<PaymentModel.CreateInvoiceLineItemDetail> illist = new List<PaymentModel.CreateInvoiceLineItemDetail>();
        for(c2g__codaInvoiceLineItem__c il : [SELECT Id, c2g__LineDescription__c, c2g__Quantity__c, c2g__UnitPrice__c, c2g__Product__r.CZ_ItemId__c 
                                            FROM c2g__codaInvoiceLineItem__c 
                                            WHERE c2g__Invoice__c = :sInv.Id]) {
            PaymentModel.CreateInvoiceLineItemDetail invLineItem = new PaymentModel.CreateInvoiceLineItemDetail();
            invLineItem.itemRate = il.c2g__UnitPrice__c;
            invLineItem.itemQuantity = il.c2g__Quantity__c;
            invLineItem.itemDescription = il.c2g__LineDescription__c;
            invLineItem.itemListID = il.c2g__Product__r.CZ_ItemId__c;
            illist.add(invLineItem);
        }
        im.invoiceLineItem = illist;
        return im;
    }

    public List<PaymentModel.CZTransactionData> getPaymentList(Integer page) {
        return getPaymentList(page, null);
    }

    public List<PaymentModel.CZTransactionData> getPaymentList(Integer page, String tnxId) {
        try{
            //retrieve custom settings and validate
            Payment_Polling_Settings__c pps = Payment_Polling_Settings__c.getInstance();
            if(pps.Days_back__c < 0 || pps.Quantity__c < 1) {
                throw new MyException('Invalid values for Payment Polling Settings');
            }
            Integer daysBack = (Integer) pps.Days_back__c;
            List<PaymentModel.CZTransactionDataPolled> transactionList = new List<PaymentModel.CZTransactionDataPolled>();
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:ChargeZoomDev/payments/list/transactions');
            req.setHeader('token', this.theToken);
            req.setHeader('Accept', 'application/json');
            req.setMethod('POST');
            req.setTimeout(120000);
            //use custom settings to modify request body
            if(String.isBlank(tnxId)) {
                req.setBody('{"limit": ' + pps.Quantity__c + ',"page": ' + page + ',"dateFrom": "' + String.valueOf(Date.today()- daysBack) + '"}' );
            } else {
                req.setBody('{"limit": 1,"transactionId": "'+ tnxId + '"}');
            }
            System.debug('~~~req body: ' + req.getBody());
            HttpResponse res = http.send(req);
            //deserialize response and check for errors
            PaymentModel.CZPolledTransactions response = (PaymentModel.CZPolledTransactions) JSON.deserialize(res.getBody(), PaymentModel.CZPolledTransactions.class);
            if(response.code == 200) {
                //success
                logResponse('List of Payments', res.getBody(), 'CZ::getPaymentList');
                transactionList = response.data;
            } else {
                //not successful. log response and throw exception
                logResponse(response.message, res.getBody(), 'CZ::getPaymentList');
                return new List<PaymentModel.CZTransactionData>();
            }
 
            //convert object type for consistency and return
            return convertToCZTransactionData(transactionList);
        } catch(Exception e) {
            Logger.logError('ChargeZoomUtility::getPaymentList', null, UserInfo.getName(), e.getTypeName(), e.getMessage(), e.getStackTraceString());
            return new List<PaymentModel.CZTransactionData>();
        }
    }

    public static List<PaymentModel.CZTransactionData> convertToCZTransactionData(List<PaymentModel.CZTransactionDataPolled> polledList) {
        List<PaymentModel.CZTransactionData> returnList = new List<PaymentModel.CZTransactionData>();
        for(PaymentModel.CZTransactionDataPolled polled : polledList) {
            System.debug('~~~polled.tnxDate: ' + polled.tnxDate);
            PaymentModel.CZTnxCustFields custFields = new PaymentModel.CZTnxCustFields();
            if(polled.tnxCustomDataFields != null) {
                custFields = (PaymentModel.CZTnxCustFields) JSON.deserialize(polled.tnxCustomDataFields, PaymentModel.CZTnxCustFields.class);            
            } 
            PaymentModel.CZTransactionData pmt = new PaymentModel.CZTransactionData();
            pmt.tnxAmount = polled.tnxAmount;
            pmt.tnxCode = polled.tnxCode;
            pmt.tnxCustomDataFields = custFields;
            pmt.tnxCustomerId = polled.tnxCustomerId;
            pmt.tnxDate = polled.tnxDate;
            pmt.tnxGateway = polled.tnxGateway;
            pmt.tnxGatewayId = polled.tnxGatewayId;
            pmt.tnxID = polled.tnxID;
            pmt.tnxPaymentMethod = polled.tnxPaymentMethod;
            pmt.tnxReferenceMemo = polled.tnxReferenceMemo;
            pmt.tnxStatus = polled.tnxStatus;
            pmt.tnxType = polled.tnxType;
            pmt.tnxInvoiceId = polled.tnxInvoiceId;
            pmt.tnxInvoiceRef = polled.tnxInvoiceRef;
            returnList.add(pmt);
        }
        return returnList;
    }

    public PaymentModel.CZCheckPaymentResponse createOfflinePayment(PaymentModel.CZCheckPayment pmt) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ChargeZoomDev/invoice/process_payment_offline');
        req.setHeader('token', this.theToken);
        req.setHeader('Accept', 'application/json');
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setBody(JSON.serialize(pmt));
        System.debug('~~~req body: ' + req.getBody());
        HttpResponse res = http.send(req);
        System.debug('~~~response: ' + res.getBody());
        //deserialize response and check for errors
        PaymentModel.CZCheckPaymentResponse response = (PaymentModel.CZCheckPaymentResponse) JSON.deserialize(res.getBody(), PaymentModel.CZCheckPaymentResponse.class);
        if(response.code == 200) {
            //success
            return response;
        } else {
            //not successful. 
            PaymentModel.CZCheckPaymentResponse cpr = new PaymentModel.CZCheckPaymentResponse();
            cpr.code = response.code;
            cpr.message = response.message;
            return cpr;
        }
    }

    public PaymentModel.czCreateInvoiceResponse sendCreditNote(PaymentModel.CZCreateInvoiceModel cm) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ChargeZoomDev/v1/invoice/update');
        req.setHeader('token', this.theToken);
        req.setHeader('Accept', 'application/json');
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setBody(JSON.serialize(cm, true));
        System.debug('~~~ChargeZoomUtility::sendCreditNote req.body: ' + req.getBody());
        HttpResponse res = http.send(req);
        if(res.getStatusCode() != 200) {
            System.debug('~~~statusCode: ' + res.getStatusCode() + ' status: ' + res.getStatus());
            throw new MyException(res.getStatus());
        }
        System.debug('~~~CZU::sendCreditNote res.getBody: ' + res.getBody());
        return (PaymentModel.czCreateInvoiceResponse) JSON.deserialize(res.getBody(), PaymentModel.czCreateInvoiceResponse.class);
    }

    public String refundPayment(String body) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ChargeZoomDev/payments/refund');
        req.setHeader('token', this.theToken);
        req.setHeader('Accept', 'application/json');
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setBody(body);
        System.debug('~~~ChargeZoomUtility::refundPayment req.body: ' + req.getBody());
        HttpResponse res = http.send(req);
        return  res.getBody();
    }

    public PaymentModel.CZInvoicesDetail getInvoice(String CZId) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ChargeZoomDev/invoice/' + CZId);
        req.setHeader('token', this.theToken);
        req.setHeader('Accept', 'application/json');
        req.setMethod('GET');
        req.setTimeout(120000);
        HttpResponse res = http.send(req);
        if(res.getStatusCode() != 200) {
            System.debug('~~~statusCode: ' + res.getStatusCode() + ' status: ' + res.getStatus());
            throw new MyException(res.getStatus());
        }
        System.debug('~~~CZU::getInvoice res.getBody: ' + res.getBody());
        return (PaymentModel.CZInvoicesDetail) JSON.deserialize(res.getBody(), PaymentModel.CZInvoicesDetail.class);
    }

    public Boolean voidInvoice(String cZInvId) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ChargeZoomDev/invoice/void');
        req.setHeader('token', this.theToken);
        req.setHeader('Accept', 'application/json');
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setBody('{"invoiceID" : "' + cZInvId + '"}');
        System.debug('~~~ChargeZoomUtility::voidInvoice req.body: ' + req.getBody());
        HttpResponse res = http.send(req);
        if(res.getStatusCode() != 200) {
            System.debug('~~~statusCode: ' + res.getStatusCode() + ' status: ' + res.getStatus());
            throw new MyException(res.getStatus());
        }
        System.debug('~~~CZU::voidInvoice res.getBody: ' + res.getBody());
        return true;
    }
}