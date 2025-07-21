// This is to mock api callouts to ChargeZoom for testing purposes.
// Use this next line at the begining of your test method.
// Test.setMock(HttpCalloutMock.class, new CZCalloutMock());

@isTest
global class CZCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse();
        if(req.getEndpoint().contains('/token/create')) {
            resp.setBody('{"code": 200,"token": "test_token123","message": "Token generated successfully."}');
        } else if(req.getEndpoint().contains('/invoice/create')) {
            resp.setBody('{"message": "Invoice details saved succcessfully","data": {"invoiceId": "INV-1234567-A9DSYR"},"code": 200}');
        } else if(req.getEndpoint().contains('/payments/list/transactions')) {
            resp.setBody('{"message": "Invoice details saved succcessfully","data": [{ "tnxID": "123456789012","tnxAmount": "1333.85","tnxDate": "2024-02-08 12:14:14","tnxStatus": "Success","tnxCustomerId": "CUS-1706712064-9BZKN5","tnxType": "sale","tnxGateway": "Auth","tnxGatewayId": "1717","tnxCode": "1","tnxUserStatus": "1","tnxPaymentMethod": "1","tnxCustomDataFields": "{\\"invoice_surcharge\\":\\"3.00\\",\\"amount_with_out_surcharge\\":1295,\\"surcharge_amount_value\\":38.85,\\"invoiceSurchargeAmt\\":38.85,\\"payment_type\\":\\"Visa - 8888\\"}","tnxReferenceMemo": null,"tnxInvoiceId": "INV-99999999999-ABCDEF","tnxInvoiceRef": "CHZ10005"}],"code": 200}');
        } else if(req.getEndpoint().contains('/invoice/process_payment_offline')) {
            resp.setBody('{"data": {"transactionID": "1234567896","invoiceData": {"invoiceID": "INV-1234567-Z9YEK4","refNumber": "CZs10095","BalanceRemaining": "420.00","DueDate": "2022-02-22","IsPaid": "false","AppliedAmount": "-85.00","taxID": "1","totalTax": "40.40","taxRate": "8.00","TimeCreated": "2022-02-07 07:27:28","fullName": "John Doe","firstName": "Doe","lastName": "John","userEmail": "john.doe@cztester.com","phoneNumber": "","companyName": "John Doe","CustomerListID": "CUS-1234567-D01VWE","ship_address1": "10 Street","ship_address2": "","ship_city": "Tucson","ship_state": "AZ","ship_country": "US","ship_zipcode": "85023","address1": "10 Street","address2": "","City": "Tucson","State": "AZ","Country": "US","zipCode": "85023","invoiceItem": [{"itemDescription": " aaa    ","itemQty": "1","itemPrice": "505","Name": "PP2","itemTax": "0"}]}},"message": "Payment Successful","code": 200}');
        } else if(req.getEndpoint().contains('/customer/create')) {
            resp.setBody('{"data": {"customerId": "CUS-1234"},"message": "Customer Created Successfully","code": 200}');
        } else if(req.getEndpoint().contains('/customer/edit')) {
            resp.setBody('{"data": {"customerId": "CUS-1234"},"message": "Customer Updated Successfully","code": 200}');
        } else if(req.getEndpoint().contains('/customer/status/')) {
            resp.setBody('{"data": {"customerId": "CUS-1234"},"message": "Customer Detail","code": 200}');
        } else if(req.getEndpoint().contains('/products/create')) {
            resp.setBody('{"data": {"ListId": "PRO-1234567899"},"message": "Product Created Successfully","code": 200}');
        } else if(req.getEndpoint().contains('/products/edit')) {
            resp.setBody('{"data": {"ListId": "PRO-123456789-edited"},"message": "Product Updated Successfully","code": 200}');
        } else if(req.getEndpoint().contains('/invoice/INV-99999999999-ABCDEF')) {
            System.debug('~~~Mock getInvoice endpoint called');
            resp.setBody('{"data": {"invoiceId": "INV-99999999999-ABCDEF", "customerId": "CUS-1717706866-IWZ0QJ-193660264", "invoiceRefrence": "SIN335575", "invoiceBalance": "1,295.00","invoiceTotal": "1,295.00", "invoiceItem": [{"itemID": "PRO-12345", "itemQty": "1", "itemDescription": "test item description", "itemPrice": "273.18"}]},"message": "Invoice Detail","code": 200}');
        } else if(req.getEndpoint().contains('/invoice/INV-99999999999-PAID')) {
            System.debug('~~~Mock getInvoice endpoint called');
            resp.setBody('{"data": {"invoiceId": "INV-99999999999-PAID", "customerId": "CUS-1717706866-IWZ0QJ-193660264", "invoiceRefrence": "SIN335575", "invoiceBalance": "0.00","invoiceTotal": "1,295.00", "invoiceItem": [{"itemID": "PRO-12345", "itemQty": "1", "itemDescription": "test item description", "itemPrice": "273.18"}]},"message": "Invoice Detail","code": 200}');
        } else if(req.getEndpoint().contains('/invoice/INV-99999999999-UNDER')) {
            System.debug('~~~Mock getInvoice endpoint called');
            resp.setBody('{"data": {"invoiceId": "INV-99999999999-UNDER", "customerId": "CUS-1717706866-IWZ0QJ-193660264", "invoiceRefrence": "SIN335575", "invoiceBalance": "100.00","invoiceTotal": "1,295.00", "invoiceItem": [{"itemID": "PRO-12345", "itemQty": "1", "itemDescription": "test item description", "itemPrice": "273.18"}]},"message": "Invoice Detail","code": 200}');
        } else if(req.getEndpoint().contains('/invoice/INV-99999999999-OVER')) {
            System.debug('~~~Mock getInvoice endpoint called');
            resp.setBody('{"data": {"invoiceId": "INV-99999999999-OVER", "customerId": "CUS-1717706866-IWZ0QJ-193660264", "invoiceRefrence": "SIN335575", "invoiceBalance": "-100.00","invoiceTotal": "1,295.00", "invoiceItem": [{"itemID": "PRO-12345", "itemQty": "1", "itemDescription": "test item description", "itemPrice": "273.18"}]},"message": "Invoice Detail","code": 200}');
        } else if(req.getEndpoint().contains('/invoice/void')) {
            System.debug('~~~Mock /invoice/void endpoint called');
            if(req.getBody().contains('INV-good')) {
                resp.setStatusCode(200);
            } else if(req.getBody().contains('INV-bad')) {
                resp.setStatusCode(400);
            }
            resp.setBody('{"data": {"invoiceId": "INV-99999999999-PAID", "customerId": "CUS-1717706866-IWZ0QJ-193660264", "invoiceRefrence": "SIN335575", "invoiceBalance": "0.00","invoiceTotal": "1,295.00", "invoiceItem": [{"itemID": "PRO-12345", "itemQty": "1", "itemDescription": "test item description", "itemPrice": "273.18"}]},"message": "Invoice Detail","code": 200}');
        } else {
            resp.setBody('{"code": 400,"message": "Error!!"}');
        }
        resp.setStatusCode(200);
        return resp;
    }
}