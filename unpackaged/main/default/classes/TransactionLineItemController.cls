public with sharing class TransactionLineItemController {
    public static void checkPayment(List<c2g__codaTransactionLineItem__c> newTLIs, Map<Id, c2g__codaTransactionLineItem__c> oldMap) {
        //find newly matched check payments and send them to CZ.
        //Line Reference is SIN number, Line Description is check #, Document Value is the negative of the check amount
        List<c2g__codaTransactionLineItem__c> checkPayments = new List<c2g__codaTransactionLineItem__c>();
        List<String> sinNumbers = new List<String>();
        for(c2g__codaTransactionLineItem__c tli : newTLIs) {
            if(tli.c2g__MatchingStatus__c == 'Matched' 
            && oldMap.get(tli.Id).c2g__MatchingStatus__c !='Matched'
            && tli.Payment_Method__c != null
            && tli.Payment_Method__c.equalsIgnoreCase('Check')
            && String.isBlank(tli.CZ_OfflinePymtId__c)) {
                checkPayments.add(tli);
                if(String.isNotBlank(tli.c2g__LineReference__c) && tli.c2g__LineReference__c.indexOfIgnoreCase('SIN') == 0) {
                    //this branch adds manually entered checks to the lists
                    sinNumbers.add(tli.c2g__LineReference__c);
                } else if(String.isNotBlank(tli.c2g__LineDescription__c) && tli.c2g__LineDescription__c.indexOfIgnoreCase('SIN') == 0) {
                    //this branch adds 'Lockbox' entered checks to the lists
                    sinNumbers.add(tli.c2g__LineDescription__c);
                }
            } 
        }

        if(sinNumbers.size() > 0) {
            System.debug('~~~sinNumbers: ' + sinNumbers);
            //create a Map where key = SIN Number and Value = CZ InvoiceId
            Map<String,String> sinMap = new Map<String,String>();
            for(c2g__codaInvoice__c inv : [SELECT Id, Name, CZ_InvoiceId__c FROM c2g__codaInvoice__c WHERE Name IN :sinNumbers]) {
                if(!String.isBlank(inv.CZ_InvoiceId__c)) {
                    //if the InvoiceId is blank, then the invoice was not sent to CharggeZoom
                    sinMap.put(inv.Name, inv.CZ_InvoiceId__c);
                }
            }
            
            if(sinMap.size() > 0) {
                CZ_CheckPayment(checkPayments, sinMap);
            }
        }  
    }

    public static void creditNote(List<c2g__codaTransactionLineItem__c> newTLIs, Map<Id, c2g__codaTransactionLineItem__c> oldMap) {
        //find newly matched credit notes and send them to CZ.
        
        List<Id> creditNoteIds = new List<Id>();
        
        for(c2g__codaTransactionLineItem__c tli : newTLIs) {
            System.debug('~~~::creditNote tli.c2g__MatchingStatus__c: ' + tli.c2g__MatchingStatus__c);
            System.debug('~~~::creditNote oldMap.get(tli.Id).c2g__MatchingStatus__c: ' + oldMap.get(tli.Id).c2g__MatchingStatus__c);
            if(tli.c2g__MatchingStatus__c == 'Matched' 
            && oldMap.get(tli.Id).c2g__MatchingStatus__c !='Matched'
            && tli.Payment_Method__c != null
            && tli.Payment_Method__c.equalsIgnoreCase('Credit Note')
            && !tli.CZ_InvoiceUpdated__c) {                
                creditNoteIds.add(tli.Id);
            } 
        }
            
        if(creditNoteIds.size() > 0) {
            System.enqueueJob(new CZ_CreditNoteQueueable(creditNoteIds));
        } 
    }

    public static void CZ_CheckPayment(List<c2g__codaTransactionLineItem__c> tLIs, Map<String, String> sinMap) {
        
        
        final String logTag = '[TransactionLineItemController::CZ_CheckPayment] ';
        List<CZ_Check_Payment__e> cpList = new List<CZ_Check_Payment__e>();

        for(c2g__codaTransactionLineItem__c tli : tLIs) {
            if(sinMap.containsKey(tli.c2g__LineReference__c) || sinMap.containsKey(tli.c2g__LineDescription__c)) {
                CZ_Check_Payment__e cp = new CZ_Check_Payment__e();
                cp.checkNumber__c = tli.Name;
                cp.invoiceId__c = sinMap.get(tli.c2g__LineReference__c) ?? sinMap.get(tli.c2g__LineDescription__c);
                cp.payAmount__c = -tli.c2g__DocumentValue__c;
                cp.paymentDate__c = tli.c2g__TransactionDate__c;
                cp.tliId__c = tli.Id;
                cpList.add(cp);
            }
        }
        if(cpList.size() > 0) {
            List<Database.SaveResult> dsrList = EventBus.publish(cpList);
            Logger.logErrorList(logTag, dsrList, cpList);
        }
    }
}