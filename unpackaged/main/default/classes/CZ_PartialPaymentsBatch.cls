public class CZ_PartialPaymentsBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    private final String logTag = '[CZ_PartialPaymentsBatch]';
    public List<String> invoicesUpdated;
    public List<String> invoiceErrors;
    
    public CZ_PartialPaymentsBatch() {
        invoicesUpdated = new List<String>();
        invoiceErrors = new List<String>();
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String qry = 'SELECT Id, Name, CZ_InvoiceId__c, c2g__InvoiceTotal__c, c2g__OutstandingValue__c, c2g__InvoiceDate__c' 
        + ' FROM c2g__codaInvoice__c WHERE c2g__PaymentStatus__c = \'Part Paid\' AND CZ_InvoiceId__c != null';
        System.debug('~~~qry: ' + qry);
        return Database.getQueryLocator(qry);
    }

    public void execute(Database.BatchableContext BC, List<c2g__codaInvoice__c> scope) {
        ChargeZoomUtility czu = new ChargeZoomUtility();

        for(c2g__codaInvoice__c inv : scope) {
            PaymentModel.CZCheckPayment olp = new PaymentModel.CZCheckPayment();
            olp.invoiceId = inv.CZ_InvoiceId__c;
            olp.checkNumber = inv.Id;
            olp.payAmount = (Decimal) inv.c2g__InvoiceTotal__c - inv.c2g__OutstandingValue__c;
            olp.paymentDate = String.valueOf(inv.c2g__InvoiceDate__c);
            PaymentModel.CZCheckPaymentResponse resp = czu.createOfflinePayment(olp);
            if(resp.data != null) {
                invoicesUpdated.add(inv.Name);
            } else {
                invoiceErrors.add(inv.Name);
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        if(invoicesUpdated.size() > 0 || invoiceErrors.size() > 0) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(UserInfo.getUserId());
            mail.setSaveAsActivity(false);
            mail.setSubject(this.logtag + ' had errors');
            String bodyText = 'Partial Payment to CZ Report. \n';
            if(invoicesUpdated.size() > 0) {
                bodyText += 'The following Sales Invoices had partial payments added to them in ChargeZoom: \n' 
                + invoicesUpdated;
            }
            if(invoiceErrors.size() > 0) {
                bodyText+= '\n The following Sales Invoices encountered errors and need to be dealt with manually: \n' + invoiceErrors ;
            }
            System.debug('~~~bodyText');
            mail.setPlainTextBody(bodyText);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}