global class SendInvoicesToCZBatch implements Database.Batchable<SObject>,Database.Stateful, Database.AllowsCallouts  {
    public class CZException extends Exception {}
    public String logtag = 'SendInvoicesToCZBatch';
    public String query;
    public List<Id> invoiceIdList;
    public List<String> failedInvoices = new List<String>();
    public Map<Id,Billing_Account__c> bAUpdateMap = new Map<Id,Billing_Account__c>();

    global SendInvoicesToCZBatch(List<Id> invoiceIdList) {
        this.invoiceIdList = invoiceIdList; 
    } 

    
    global List<c2g__codaInvoice__c> start(Database.BatchableContext BC){
        List<Id> lIds = this.invoiceIdList;
        System.debug('~~~lIds: ' + lIds + ' Size: ' + lids.size());
        this.query = 'SELECT Id, Name, Billing_Account__r.CZ_CustomerId__c, Billing_Account__r.Manual_Invoice_Required__c, c2g__InvoiceTotal__c, c2g__InvoiceDate__c, ' +
                    'c2g__Account__r.Name, c2g__Account__r.BillingStreet, c2g__Account__r.BillingCity, c2g__Account__r.BillingState, c2g__Account__r.BillingPostalCode, ' +
                    'Billing_Account__c FROM c2g__codaInvoice__c WHERE c2g__InvoiceStatus__c = \'Complete\' AND c2g__OutstandingValue__c > 0 ' +
                    'AND CZ_Invoicing_Status__c = \'None\'  AND c2g__InvoiceDate__c <= TODAY'; 
                    
        if(lIds != null && !lids.isEmpty()) {
            System.debug('~~~lIds is not null.');
            this.query += ' AND Id IN :lIds' ;
        }
        this.query += ' FOR UPDATE';
        System.debug('~~~query: ' + query);


        List<c2g__codaInvoice__c> result = Database.Query(this.query);

        List<c2g__codaInvoice__c> returnList = new List<c2g__codaInvoice__c>(result);
        for(Integer i = result.size()-1; i >= 0; i--) {
            if(result[i].Billing_Account__r.Manual_Invoice_Required__c) {
                result[i].CZ_Invoicing_Status__c = 'Manual Invoicing Required';
                returnList.remove(i);
            } else {
                result[i].CZ_Invoicing_Status__c = 'In Progress';
            }
        }

        //update invoices
        List<Database.SaveResult> srList = Database.update(result);

        //log any errors
        for(Integer x = 0; x < srList.size(); x++) {
            if(!srList[x].isSuccess()) {
                Logger.logErrorEvent(logtag + '::start', null, UserInfo.getName(), srList[x].getErrors()[0].getStatusCode().Name(), srList[x].getErrors()[0].getMessage(), JSON.Serialize(result[x]), result[x].Id);
                this.failedInvoices.add(result[x].Name);
            }
        }

        return returnList;      
    }
    
    global void execute(Database.BatchableContext BC,List<c2g__codaInvoice__c> scope) {      
        //Boolean invokeTestError = false;
        Boolean recordChanged = false; 
        
        for(c2g__codaInvoice__c invoice : scope){
            System.Debug('Invoice Name : ' + invoice.Name);
            ChargeZoomUtility czu = new ChargeZoomUtility();
            //if Billing Account is not in CZ, then create and activate unless it's already been created in this batch.
            if(String.isBlank(invoice.Billing_Account__r.CZ_CustomerId__c) && !invoice.Billing_Account__r.Manual_Invoice_Required__c) {
                if(bAUpdateMap.containsKey(invoice.Billing_Account__c)) {
                    invoice.Billing_Account__r.CZ_CustomerId__c = bAUpdateMap.get(invoice.Billing_Account__c).CZ_CustomerId__c;
                } else {                
                    invoice.Billing_Account__r.CZ_CustomerId__c = createCZCustomer(invoice.Billing_Account__c, czu);
                    bAUpdateMap.put(invoice.Billing_Account__c, new Billing_Account__c(Id = invoice.Billing_Account__c, CZ_CustomerId__c = invoice.Billing_Account__r.CZ_CustomerId__c));
                }
            }
            
            //Send Invoice to ChargeZoom
            try {
                PaymentModel.CZCreateInvoiceModel im = ChargeZoomUtility.generateCZInvoice(invoice);
                PaymentModel.czCreateInvoiceResponse result = czu.createInvoice(im);

                // Update invoice record.
                if(result.code == 200 && !String.isBlank(result.data.invoiceId)) {
                    invoice.CZ_Invoicing_Status__c = 'Invoiced';
                    invoice.CZ_InvoiceId__c = result.data.invoiceId;
                    invoice.CZ_Payment_Link__c = result.data.paylink;
                    invoice.Invoice_Email_Date__c = Date.today();
                } else {
                    invoice.CZ_Invoicing_Status__c = 'Error';
                    this.failedInvoices.add(invoice.Name);
                }
                update invoice;
            } catch(Exception e) {
                Logger.logErrorEvent(logtag + '::execute', null, UserInfo.getName(), e.getTypeName(), e.getMessage(), e.getStackTraceString(), invoice.Id);
                this.failedInvoices.add(invoice.Name);
                invoice.CZ_Invoicing_Status__c = 'Error';
                update invoice;
            }  
        }   
    }
     
    global void finish(Database.BatchableContext BC) {
        System.debug( logtag + '::finish'); 
        System.debug('~~~current user: ' + UserInfo.getName()); 
        if(this.failedInvoices.size() > 0) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(UserInfo.getUserId());
            mail.setSaveAsActivity(false);
            mail.setSubject(this.logtag + ' had errors');
            mail.setPlainTextBody('The following Sales Invoices encountered an error while updating and were not sent to ChargeZoom: ' 
                + this.failedInvoices);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }  
        
        if(bAUpdateMap.size() > 0) {
            List<Billing_Account__c> baList = bAUpdateMap.values();
            List<Database.SaveResult> srList = Database.update(baList, false);
            for(Integer i = 0; i < srList.size(); i++) {
                if(!srList[i].isSuccess()) {
                    Database.Error er = srList[i].getErrors()[0];
                    Logger.logErrorEvent(logtag + '::finish', null, UserInfo.getName(), String.valueOf(er.getStatusCode()), er.getMessage(), String.join(er.getFields(), ','), bAList[i].Id);
                }
            }
        }
    }

    public static String createCZCustomer(Id bAId, ChargeZoomUtility czu) {
        String logtagx = 'SendInvoicesToCZBatch::createCZCustomer';
        String czCustId = '';

        //query for billing account details and send to CZ.
        try{
            Billing_Account__c ba = [SELECT Id, Account__r.Name, Primary_Contact__r.FirstName, Primary_Contact__r.LastName,
                Primary_Contact__r.Phone, Primary_Contact__r.Email, Billing_Street__c, Billing_City__c, Billing_State_Province__c, 
                Billing_Zip_Postal_Code__c, Billing_Country__c FROM Billing_Account__c WHERE Id = :bAId];
            PaymentModel.CZCreateCustomer cust = new PaymentModel.CZCreateCustomer();
            cust.customerCompanyName = ba.Account__r.Name;
            cust.customerFullName = ba.Account__r.Name;
            cust.customerFirstName = ba.Primary_Contact__r.FirstName;
            cust.customerLastName = ba.Primary_Contact__r.LastName;
            cust.customerContact = ba.Primary_Contact__r.Phone;
            cust.customerEmail = ba.Primary_Contact__r.Email;
            cust.bAddress1 = ba.Billing_Street__c;
            cust.bCity = ba.Billing_City__c;
            cust.bState = ba.Billing_State_Province__c;
            cust.bZipcode = ba.Billing_Zip_Postal_Code__c;
            cust.bCountry = ba.Billing_Country__c;
        
            PaymentModel.CZCreateCustomerResponse resp = czu.createCustomer(cust);
            System.debug(logtagx + 'CZ createCustomer response: ' + resp);
            //ChargeZoomUtility.logResponse(resp.data.customerId, resp.data, 'CZ_LoadCustomerBatch');
            
            // Check if successful
            if(resp.code == 200){
                System.debug(logtagx + ' CZ create customer response: ' + resp.message + ' (' + resp.code + ')');
                czCustId = resp.data.customerId;

                // Activate the customer in cz.
                PaymentModel.CZCreateCustomerResponse statusResp = czu.updateCustomerStatus(czCustId, '1');
                if(statusResp.code == 200){
                    System.debug(logtagx+ czCustId + ' has been activated in ChargeZoom.');
                } else {
                    System.debug(logTagx + ' ERROR activating customer ' + czCustId + ' in ChargeZoom.' + statusResp.message);
                    throw new CZException('ERROR activating customer ' + czCustId + ' in ChargeZoom.' + statusResp.message);
                }
            } else {
                System.debug(logTagx + ' ERROR creating customer ' + czCustId + ' in ChargeZoom.' + resp.message);
                throw new CZException('ERROR creating customer ' + bAId + ' in ChargeZoom.' + resp.message);
            }
        } catch(Exception e) {
            Logger.logErrorEvent(logtagx, null, UserInfo.getName(), e.getTypeName(), e.getMessage(), e.getStackTraceString(), bAId);
        }
        return czCustId;
    }
}