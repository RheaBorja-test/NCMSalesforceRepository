public with sharing class CZ_CreditNoteQueueable implements Queueable, Database.AllowsCallouts {

    public List<Id> ids;

    public CZ_CreditNoteQueueable(List<Id> itemList) {
        this.ids = itemList;
    }

    public void execute(QueueableContext context) {
        
        final String logTag = '[CZ_CreditNoteQueueable] ';
        ChargeZoomUtility czu = new ChargeZoomUtility();

        Id tLIId = this.ids.remove(0);

        c2g__codaTransactionLineItem__c tli = [
            SELECT Id,
                c2g__DocumentValue__c,
                c2g__Transaction__r.c2g__SalesCreditNote__c,
                c2g__Transaction__r.c2g__SalesCreditNote__r.Name,
                c2g__Transaction__r.c2g__SalesCreditNote__r.c2g__Invoice__r.Name,
                c2g__Transaction__r.c2g__SalesCreditNote__r.c2g__Invoice__r.CZ_InvoiceId__c
            FROM c2g__codaTransactionLineItem__c 
            WHERE Id = :tLIId 
        ];

        PaymentModel.CZInvoicesDetail invDet = czu.getInvoice(tli.c2g__Transaction__r.c2g__SalesCreditNote__r.c2g__Invoice__r.CZ_InvoiceId__c);
        Decimal invBal = Decimal.valueOf(invDet.data.invoiceBalance.remove(','));
        Decimal invTotal = Decimal.valueOf(invDet.data.invoiceTotal.remove(','));

        PaymentModel.CZCreateInvoiceModel newCM = new PaymentModel.CZCreateInvoiceModel();
        if(invBal == 0) {
            if(tli.c2g__DocumentValue__c == invTotal) {
                System.debug('~~~Invoice is fully paid in CZ. Refund manually in CZ portal');
                Logger.logErrorEvent(logTag, 'INFO', UserInfo.getName(), 'Credit Note', 'Invoice is fully paid in CZ. Refund manually in CZ portal', tli.c2g__Transaction__r.c2g__SalesCreditNote__r.Name, tli.c2g__Transaction__r.c2g__SalesCreditNote__c);
            } else {
                System.debug('~~~Invoice is fully paid in CZ. Partial refund should be made in CZ Portal.');
                Logger.logErrorEvent(logTag, 'INFO', UserInfo.getName(), 'Credit Note', 'Invoice is fully paid in CZ. Partial refund should be made in CZ Portal.', tli.c2g__Transaction__r.c2g__SalesCreditNote__r.Name, tli.c2g__Transaction__r.c2g__SalesCreditNote__c);
            }
        } else if(invBal + tli.c2g__DocumentValue__c < 0) {
            System.debug('~~~Credit is for greater than balance owed on Invoice. Partial refund should be made in CZ Portal for the difference.');
            Logger.logErrorEvent(logTag, 'INFO', UserInfo.getName(), 'Credit Note', 'Credit is for greater than balance owed on Invoice. Partial refund should be made in CZ Portal for the difference.', tli.c2g__Transaction__r.c2g__SalesCreditNote__r.Name, tli.c2g__Transaction__r.c2g__SalesCreditNote__c);
        } else if(invBal + tli.c2g__DocumentValue__c == 0) {
            System.debug('~~~Credit is for full amount of invoice. Invoice will be voided in CZ.');
            Boolean b = czu.voidInvoice(tli.c2g__Transaction__r.c2g__SalesCreditNote__r.c2g__Invoice__r.CZ_InvoiceId__c);
            if(!b) {
                throw new ChargeZoomUtility.MyException('Invoice ' + tli.c2g__Transaction__r.c2g__SalesCreditNote__r.c2g__Invoice__r.Name + 'not voided in CZ.');
            }
        } else {
            //create invoice model
            newCM.invoiceId = invDet.data.invoiceId;
            
            List<PaymentModel.CreateInvoiceLineItemDetail> creditItemList = new List<PaymentModel.CreateInvoiceLineItemDetail>();
            
            //create credit invoice line items from credit note line items
            for(c2g__codaCreditNoteLineItem__c cli : [SELECT Id, c2g__Quantity__c, c2g__UnitPrice__c, c2g__Product__r.Name, c2g__Product__r.CZ_ItemId__c
                                                            FROM c2g__codaCreditNoteLineItem__c
                                                            WHERE c2g__CreditNote__c = :tli.c2g__Transaction__r.c2g__SalesCreditNote__c]) {
                //generate and add credit line to invoice
                PaymentModel.CreateInvoiceLineItemDetail ili = new PaymentModel.CreateInvoiceLineItemDetail();
                ili.itemListID = cli.c2g__Product__r.CZ_ItemId__c;
                ili.itemRate = -cli.c2g__UnitPrice__c;
                ili.itemQuantity = cli.c2g__Quantity__c;
                ili.itemDescription = 'Credit';
                creditItemList.add(ili);
            }

            newCM.invoiceLineItem = creditItemList;

            System.debug(logTag + ' is ready to send updated invoice to CZ');
            System.debug('newCM: ' + JSON.serialize(newCM));

            try {
                PaymentModel.czCreateInvoiceResponse resp = czu.sendCreditNote(newCM);
                if(resp.code == null || resp.code != 200) {
                    throw new ChargeZoomUtility.MyException('Bad response from CZ.');
                }
                //update Transaction Line Item so that it shows it's been sent to CZ and won't fire the trigger again
                update new c2g__codaTransactionLineItem__c(Id = tLIId, CZ_InvoiceUpdated__c = true);
            } catch (Exception e) {
                Logger.logErrorEvent(logTag, null, UserInfo.getName(), e.getTypeName(), e.getMessage(), e.getStackTraceString(), tLIId);
            }
        }
        
        
        if(this.ids.size() > 0) {
            System.enqueueJob(new CZ_CreditNoteQueueable(ids));
        }
    }
}