//This trigger is un-bulkified. The InvoiceCancellationTrigger.platformEventSubscriberConfig-meta.xml file 
//sets this trigger to one event at a time because the event is only published by a flow action on the 
//Opportunity.

trigger InvoiceCancellation on Invoice_Cancellation__e (after insert) {
    Id notificationTypeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName='Desktop_Mobile'].Id;    
    Messaging.CustomNotification notification = new Messaging.CustomNotification();
    notification.setNotificationTypeId(notificationTypeId);
    notification.setTitle('Invoice Cancellation');
    String body;
                 
    Invoice_Cancellation__e ice = trigger.new[0];
    Set<String> recipientsIds = new Set<String>{ice.SalespersonId__c};
    notification.setTargetId(ice.OpportunityId__c);
    Boolean success = false;
    List<c2g__codaInvoice__c> invList = [SELECT Id, Name, c2g__InvoiceStatus__c, c2g__PaymentStatus__c, c2g__Opportunity__c, 
                                                c2g__Opportunity__r.StageName, CZ_InvoiceId__c, c2g__Account__c,
                                                (SELECT Id, c2g__Product__c, c2g__UnitPrice__c, c2g__Quantity__c,
                                                    c2g__Dimension1__c, c2g__Dimension2__c
                                                FROM c2g__InvoiceLineItems__r)
                                        FROM c2g__codaInvoice__c
                                        WHERE c2g__Opportunity__c = :ice.OpportunityId__c
                                        AND c2g__MatchType__c != 'Credited'];
    if(invList.size() == 0) {
        //send 'no invoice' notification
        body = 'There is no invoice associated with this opportunity (' + ice.OpportunityId__c + ') to cancel.';
    } else if(invList.size() > 1) {
        //send 'multiple invoices' notification
        body = 'There are multiple invoices associated with this opportunity (' + ice.OpportunityId__c + '). Please contact the accounting department to make sure they all get cancelled.';
    } else {
        c2g__codaInvoice__c inv = invList[0];
        System.debug('invoiceStatus: ' + inv.c2g__InvoiceStatus__c + 'paymentStatus: ' + inv.c2g__PaymentStatus__c);
        if(inv.c2g__InvoiceStatus__c.equalsIgnoreCase('In Progress')) {
            success = InvoiceCancellationHelper.discardInvoice(inv, ice.Reason__c, ice.CloseOpp__c);
        } else if(inv.c2g__PaymentStatus__c.equalsIgnoreCase('Unpaid')) {
            success = InvoiceCancellationHelper.cancelInvoice(inv, ice.Reason__c, ice.CloseOpp__c);
        } else {
            //send 'invoice paid' notification
            body = 'The invoice associated with this opportunity (' + ice.OpportunityId__c + ') has been paid (or partially paid). Please contact the accounting department to refund the customer and cancel the invoice.';
        }
    }
    if(!success) {
        //send error notification
        body = 'An error was encountered while canceling the invoice associated with this Opportunity (' + ice.OpportunityId__c + '). Please notify the Salesforce Team.';
    }
    if(String.isNotBlank(body)) {
        notification.setBody(body);
        notification.send(recipientsIds);
    }   
}