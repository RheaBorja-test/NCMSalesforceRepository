public with sharing class InvoiceCancellationHelper {
    public class InvoiceCancellationException extends Exception {}

    public static boolean discardInvoice(c2g__codaInvoice__c inv, String discardMessage, Boolean closeOpp) {
        try {
            c2g.CODAAPICommon_10_0.Context context = new c2g.CODAAPICommon_10_0.Context();
            context.CompanyName = 'NCM Associates, Inc.';
            if(!Test.isRunningTest()) {
                c2g.CODAAPISalesInvoice_10_0.DiscardInvoice(context, c2g.CODAAPICommon.getRef(inv.Id, null), discardMessage);
            }
            
            regressOppStage(inv, closeOpp);
            
        } catch (Exception ex) {
            Logger.logException('InvoiceCancellationHelper::discardInvoice', inv.Id, ex);
            return false;
        }
        return true;
    }

    public static Boolean cancelInvoice(c2g__codaInvoice__c inv, String discardMessage, Boolean closeOpp) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<SObject> sobjs = new List<SObject>();
            c2g__codaCreditNote__c cn = new c2g__codaCreditNote__c(
                c2g__ExternalId__c = inv.Id,
                c2g__Account__c = inv.c2g__Account__c,
                c2g__CreditNoteDate__c = Date.today(),
                c2g__CreditNoteDescription__c = discardMessage,
                c2g__Invoice__c = inv.Id
            );
            sobjs.add(cn);
            for(c2g__codaInvoiceLineItem__c li : inv.c2g__InvoiceLineItems__r) {
                c2g__codaCreditNoteLineItem__c cnli = new c2g__codaCreditNoteLineItem__c(
                    c2g__CreditNote__r = new c2g__codaCreditNote__c(c2g__ExternalId__c = inv.Id),
                    c2g__Product__c = li.c2g__Product__c,
                    c2g__UnitPrice__c = li.c2g__UnitPrice__c,
                    c2g__Quantity__c = li.c2g__Quantity__c,
                    c2g__Dimension1__c = li.c2g__Dimension1__c,
                    c2g__Dimension2__c = li.c2g__Dimension2__c,
                    c2g__LineDescription__c = inv.Name
                );
                sobjs.add(cnli);
            }
            Database.insert(sobjs,true);
            cn.c2g__TriggerPosting__c = 'Synchronous';
            update(cn);

            creditNoteMatching(cn, inv);

            regressOppStage(inv, closeOpp);          

        } catch (Exception ex) {
            Database.rollback(sp);
            Logger.logException('InvoiceCancellationHelper::cancelInvoice', inv.Id, ex);
            return false;
        }
        return true;
    }

    public static void creditNoteMatching(c2g__codaCreditNote__c cn, c2g__codaInvoice__c inv) {
        try {
            List<c2g__codaTransactionLineItem__c> transList = [SELECT Id, SystemModstamp, c2g__DocumentValue__c
                                                        FROM c2g__codaTransactionLineItem__c
                                                        WHERE (c2g__Transaction__r.c2g__SalesInvoice__c = :inv.Id
                                                            OR c2g__Transaction__r.c2g__SalesCreditNote__c = :cn.Id)
                                                        AND c2g__MatchingStatus__c = 'Available'];

            //Setup the match operation
            Id periodId = cn.c2g__Period__c;
            Id acctId = cn.c2g__Account__c;
            c2g.CODAAPICashMatchingTypes_8_0.Configuration configuration = new c2g.CODAAPICashMatchingTypes_8_0.Configuration();
            configuration.Account = c2g.CODAAPICommon.getRef(acctId, null);
            //Choose Document or Account depending on the Currency Mode you would choose if you were doing this from the UI.
            configuration.MatchingCurrencyMode = c2g.CODAAPICashMatchingTypes_8_0.enumMatchingCurrencyMode.Document;
            configuration.MatchingDate = System.Today();
            configuration.DiscountDate = System.today();
            configuration.MatchingPeriod = c2g.CODAAPICommon.getRef(periodId, null);
            
            //Make thelist of cash entries to post
            List<c2g.CODAAPICashMatchingTypes_8_0.Item> items = new List<c2g.CODAAPICashMatchingTypes_8_0.Item>();
        
            for(c2g__codaTransactionLineItem__c trans : transList) {                
                c2g.CODAAPICashMatchingTypes_8_0.Item item1 = new c2g.CODAAPICashMatchingTypes_8_0.Item();
                items.add(item1);
                item1.TransactionLineItem = c2g.CODAAPICommon.getRef(trans.Id, null);
                item1.TransactionLineItemSystemModStamp = trans.SystemModstamp;
                item1.Paid = trans.c2g__DocumentValue__c;
                item1.Discount = 0;
                item1.WriteOff = 0;
            }

            //create the context
            c2g.CODAAPICommon_8_0.Context cntx = new c2g.CODAAPICommon_8_0.Context();
            cntx.CompanyName = 'NCM Associates, Inc.';
            
            //create a null analysis object, since there are no discounts or write-offs
            c2g.CODAAPICashMatchingTypes_8_0.Analysis analysisInfoAPI = new c2g.CODAAPICashMatchingTypes_8_0.Analysis();
            
            // Finally, perform the match
            c2g.CODAAPICommon.Reference matchReference = c2g.CODAAPICashMatching_8_0.Match(cntx, configuration, items, analysisInfoAPI);
        } catch(Exception ex) {
            Logger.logException('InvoiceCancellationHelper::creditNoteMatching', inv.Id, ex);
            throw new InvoiceCancellationException();
        }
    }

    public static void regressOppStage(c2g__codaInvoice__c inv, Boolean closeOpp) {
        try {
            if(closeOpp) {
                update(new Opportunity(Id = inv.c2g__Opportunity__c, StageName = 'Closed Lost'));
            } else {
                update(new Opportunity(Id = inv.c2g__Opportunity__c, StageName = 'Validating Dates'));
            }
            List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
            for(OpportunityLineItem oli : [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :inv.c2g__Opportunity__c]) {
                oli.Invoiced__c = false;
                oliList.add(oli);
            }
            if(oliList.size() > 0) {
                update(oliList);
            }
        } catch(Exception ex) {
            Logger.logException('InvoiceCancellationHelper::regressOppStage', inv.Id, ex);
            throw new InvoiceCancellationException();
        }
    }
}