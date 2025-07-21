//Test coverage for this class is provided by ApplyPaymentsBatchTest
global class ApplyPaymentsBatch implements Database.Batchable<SObject>,Database.Stateful, Database.AllowsCallouts  {
    global List<PaymentModel.CZTransactionData> theList;
    global List<c2g__codaCashEntry__c> ceInsertedList = new List<c2g__codaCashEntry__c>();
    global List<c2g__codaCashEntry__c> ceForCashMatching = new List<c2g__codaCashEntry__c>();
    global Boolean jLIinserted = false; 
    global Map<String,List<String>> czIdMap;   
    global Map<String,Decimal> surchargeMap = new Map<String,Decimal>();
    global c2g__codaJournal__c journal = new c2g__codaJournal__c();
    String bankName = System.Label.CCCashEntryBank;
    public Id bankAcctId = [SELECT Id FROM c2g__codaBankAccount__c WHERE Name = :bankName LIMIT 1].Id;
    public Id currencyId = [SELECT Id FROM c2g__codaAccountingCurrency__c WHERE Name = 'USD' LIMIT 1].Id;
    public Surcharge_Journal_Entry__c sje = Surcharge_Journal_Entry__c.getInstance();
    public String invoiced = 'Invoiced';
    public String paid = 'Paid';
    global Integer page;
    global Integer qty = (Integer) Payment_Polling_Settings__c.getInstance().Quantity__c;
    global String czTnxId;

    global ApplyPaymentsBatch() {
        this.page = 0;
    }

    global ApplyPaymentsBatch(Integer page) {
        this.page = page;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //poll the CZ api for paid (And partially paid) invoices
        ChargeZoomUtility czu = new ChargeZoomUtility();

        //page will be passed to CZ and incremented for each batch, when a batch returns less than 100,
        // then set page to -1 to stop the batch.
        if(this.theList == null || this.theList.isEmpty()) {
            if(String.isBlank(this.czTnxId)) {
                this.theList = czu.getPaymentList(page);
                System.debug('~~~ApplyPaymentsBatch::theList: ' + this.theList);
                page++;
                if(theList.size() < qty) {
                    page = -1;
                }
            } else {
                this.theList = czu.getPaymentList(page, czTnxId);
            }
        }
        
        
        
        //create a map of the CZ Ids - key is tnxId, value is a list of tnxInvoiceIds 
        //use the map to query the Sales Invoices and a map of surcharges, 
        //key is tnxId, value is the surcharge amount for creating the journal entries.
        czIdMap = new Map<String,List<String>>();
        
        for(PaymentModel.CZTransactionData czPmt : this.theList) {
            if(czPmt.tnxStatus.equalsIgnoreCase('Success') && czPmt.tnxType.equalsIgnoreCase('sale')) {
                //If the tnxInvoiceId is a concatenated list of tnxInvoiceIds separated by a comma,
                //then split them up into a list. Otherwise the list is just the one tnxInvoiceId.
                List<String> invIds = new List<String>();
                if(czPmt.tnxInvoiceId.contains(',')) {
                    invIds = czPmt.tnxInvoiceId.split(',');
                    for(Integer i = 0; i < invIds.size(); i++) {
                        invIds[i] = invIds[i].trim();
                    }
                } else {
                    invIds.add(czPmt.tnxInvoiceId);
                }
                czIdMap.put(czPmt.tnxID, invIds);
                if(czPmt.tnxCustomDataFields?.surcharge_amount_value > 0) {
                    this.surchargeMap.put(czPmt.tnxID, czPmt.tnxCustomDataFields.surcharge_amount_value);
                }
            }
        }
        //filter out payments that have already been used to create a cash entry
        for(c2g__codaCashEntry__c ce : [SELECT Id, CZ_TnxId__c FROM c2g__codaCashEntry__c WHERE CZ_TnxId__c IN :czIdMap.keySet()]) {
            czIdMap.remove(ce.CZ_TnxId__c);
            this.surchargeMap.remove(ce.CZ_TnxId__c);
        }

        //Make a list of tnxInvoiceIds for each payment
        List<String> valuesList = new List<String>();
        for(String x : czIdMap.keySet()) {
            valuesList.addAll(czIdMap.get(x));
        }
        System.debug('~~~valuesList: ' + valuesList);
        return Database.getQueryLocator('SELECT Id, name, CZ_InvoiceId__c, c2g__Transaction__c, c2g__Account__c, c2g__OutstandingValue__c ' +
                'FROM c2g__codaInvoice__c WHERE CZ_Invoicing_Status__c = :invoiced ' +
                'AND CZ_InvoiceId__c IN :valuesList');
    }

    global void execute(Database.BatchableContext BC, List<c2g__codaInvoice__c> scope) {
        try {
            //resest list of cash entries created
            this.ceInsertedList.clear();
            //create a map with key of CZInvoiceId, value of Sales Invoice
            Map<String,c2g__codaInvoice__c> invMap = new Map<String,c2g__codaInvoice__c>();
            for(c2g__codaInvoice__c inv :scope) {
                    invMap.put(inv.CZ_InvoiceId__c, inv);
            }

            //create a map with tnxId as key and the List of SINs as the value
            Map<String,List<c2g__codaInvoice__c>> tnxIdSINMap = new Map<String,List<c2g__codaInvoice__c>>();
            for(String tnxId : czIdMap.keySet()) {
                List<c2g__codaInvoice__c> sinList = new List<c2g__codaInvoice__c>();
                for(String invId : czIdMap.get(tnxId)) {
                    sinList.add(invMap.get(invId));
                }
                if(sinList.size()>0) {
                    tnxIdSINMap.put(tnxId, sinList);
                }
            }


            //match the CZ payment to the Sales Invoice and create the Cash Entries, etc.
            List<c2g__codaCashEntry__c> ceList = new List<c2g__codaCashEntry__c>();
            //looping through the list backwards so that payments that have been processed can be removed from
            //the list so that they don't get processed again if there is more than one SIN per payment.
            for(Integer x = this.theList.size() - 1 ; x >= 0 ; x--) {
                PaymentModel.CZTransactionData czPmt = this.theList[x];
                if(tnxIdSINMap.containskey(czPmt.tnxId)) {
                    System.debug('~~~CZ_InvoiceId__c: ' + czPmt.tnxId);
                    c2g__codaCashEntry__c ce = createCashEntry(tnxIdSINMap.get(czPmt.tnxId), czPmt);
                    //if createCashEntry throws an error and returns null, then don't add it to list
                    if(ce != null) {
                        ceList.add(ce);
                    }
                    this.theList.remove(x);
                }
            }
            List<Database.SaveResult> srList = Database.insert(ceList, false);
            for(Integer x = 0; x < srList.size(); x++) {
                if(srList[x].isSuccess()) {
                    this.ceInsertedList.add(ceList[x]);
                } else {
                    Logger.logErrorEvent('ApplyPaymentsBatch::insert Cash Entries', null, UserInfo.getName(), srList[x].getErrors()[0].getStatusCode().Name(), srList[x].getErrors()[0].getMessage(), JSON.Serialize(ceList[x]), ceList[x].CZ_TnxId__c);
                }
            }

            //create a Cash Entry Line Item for each Cash Entry that was successfully created
            if(this.ceInsertedList.size() > 0) {
                List<c2g__codaCashEntryLineItem__c> celiList = new List<c2g__codaCashEntryLineItem__c>();
                
                for(c2g__codaCashEntry__c ce : this.ceInsertedList) {
                    celiList.addAll(createCELineItem(tnxIdSINMap.get(ce.c2g__Reference__c), ce));
                }

                List<Database.SaveResult> srList2 = Database.insert(celiList, false);
                for(Integer x = srList2.size() - 1; x >= 0; x--) {
                    if(srList2[x].isSuccess()) {
                        System.debug('~~~' + x + ' CE Line Item was a success.');
                    } else {
                        System.debug('~~~cash entry line item:' + celiList[x]);
                        System.debug('~~~SaveResult:' + srList2[x].getErrors()[0].getMessage());
                        c2g__codaCashEntry__c ce = this.ceInsertedList.remove(x);
                        Logger.logErrorEvent('ApplyPaymentsBatch::insert CE Line Items', null, UserInfo.getName(), srList2[x].getErrors()[0].getStatusCode().Name(), srList2[x].getErrors()[0].getMessage(), JSON.Serialize(celiList[x]), celiList[x].c2g__CashEntry__c);
                    }
                }            
                
                if(this.ceInsertedList.size() > 0) {
                    //Post cash entries that were inserted successfully with their Line Item.
                    postCashEntries(); 
                    
                    //Create Journal Entry for surcharge on all sucessfully created Cash Entries
                    if(this.surchargeMap.size() > 0) {
                        if(this.journal.Id == null) {
                            insert this.journal;
                        }
                        List<c2g__codaJournalLineItem__c> journalLineItems = createJournalEntries();
                        if(journalLineItems.size() > 0){                        
                            List<Database.SaveResult> srList3 = Database.insert(journalLineItems, false);
                            for(Integer i = 0; i < srList3.size(); i++) {
                                if(srList3[i].isSuccess()) {
                                    this.jLIinserted = true;
                                } else {
                                    Logger.logErrorEvent('ApplyPaymentsBatch::insert Journal Line Items', null, UserInfo.getName(), srList3[i].getErrors()[0].getStatusCode().Name(), srList3[i].getErrors()[0].getMessage(), JSON.serializePretty(journalLineItems[i]), journalLineItems[i].c2g__LineDescription__c.abbreviate(13));
                                }
                            }
                            //if all journal line items were inserted they will be posted in the finish method 
                            
                        }
                    }
                    //add sucessfully created cash entries to list for matching.
                    this.ceForCashMatching.addAll(this.ceInsertedList);
                }
            }
        } catch (Exception ex) {
            Logger.logErrorEvent('ApplyPaymentsBatch::execute', null, UserInfo.getName(), ex.getTypeName(), ex.getMessage(), ex.getStackTraceString(), String.valueOf(ex.getLineNumber()));
        }           
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('~~~ApplyPaymentsBatch::finish');
        //Cash matching
        if(this.ceForCashMatching != null && this.ceForCashMatching.size() > 0) {
            System.enqueueJob(new CashMatching(this.ceForCashMatching));
            //Post the journal entries made if all were inserted successfully.
            if(this.jLIinserted) {
                postJournal();
            }
        } else {
            System.debug('~~~No Cash Entries inserted.');
        }  
        
        if(page >= 0) {
            System.debug('~~~Starting next page');
            Database.executeBatch(new ApplyPaymentsBatch(page), 25);
        }
    }

    public c2g__codaCashEntry__c createCashEntry(List<c2g__codaInvoice__c> sInvList, PaymentModel.CZTransactionData czPmt) {
        try {
            System.debug('~~~sInvList[0]: ' + sInvList[0]);
            c2g__codaCashEntry__c ce = new c2g__codaCashEntry__c(
                c2g__BankAccount__c = this.bankAcctId,
                c2g__Reference__c = czPmt.tnxID,
                CZ_TnxId__c = czPmt.tnxID,
                c2g__PaymentMethod__c = 'Electronic',
                c2g__Account__c = sInvList[0].c2g__Account__c,
                CZ_TransactionAmount__c = czPmt.tnxCustomDataFields.amount_with_out_surcharge ?? Decimal.valueOf(czPmt.tnxAmount)
            );
            ce.c2g__Description__c = '';
            for(c2g__codaInvoice__c sin : sInvList) {
                ce.c2g__Description__c += sin.Name + ' ';
            } 
            ce.c2g__Description__c = ce.c2g__Description__c.trim();
            System.debug('~~~ce.c2g__Account__c: ' + ce.c2g__Account__c);
            return ce;
        } catch(Exception ex) {
            Logger.logException('ApplyPaymentsBatch::createCashEntry', czPmt.tnxID, ex);
            return null;
        }
    }

    public List<c2g__codaCashEntryLineItem__c> createCELineItem(List<c2g__codaInvoice__c> sInvList, c2g__codaCashEntry__c ce) {
        List<c2g__codaCashEntryLineItem__c> returnList = new List<c2g__codaCashEntryLineItem__c>();
        for(c2g__codaInvoice__c inv : sInvList) {
            c2g__codaCashEntryLineItem__c li = new c2g__codaCashEntryLineItem__c(
                c2g__CashEntry__c = ce.Id, 
                c2g__Account__c = ce.c2g__Account__c, 
                c2g__AccountReference__c = inv.Name,
                c2g__CashEntryValue__c = ce.CZ_TransactionAmount__c > inv.c2g__OutstandingValue__c ? inv.c2g__OutstandingValue__c : ce.CZ_TransactionAmount__c
            );
            returnList.add(li);
        }
        return returnList;
    }

    public void postCashEntries() {
        List<c2g.codaapicommon.reference> cashEntryRefs = new List<c2g.codaapicommon.reference>();
        for(c2g__codaCashEntry__c newCE : this.ceInsertedList) {
            cashEntryRefs.add(c2g.CODAAPICommon.getRef(newCE.Id, null));
        }
        c2g.CODAAPICommon_7_0.Context cntx = new c2g.CODAAPICommon_7_0.Context();
        cntx.CompanyName = 'NCM Associates, Inc.';
        c2g.CODAAPICashEntry_7_0.BulkPostCashEntry(cntx, cashEntryRefs);
    }

    public List<c2g__codaJournalLineItem__c> createJournalEntries() {
        //create the 2 journal line items for each surcharge that balance each other out
        List<c2g__codaJournalLineItem__c> jliList = new List<c2g__codaJournalLineItem__c>();
        for(c2g__codaCashEntry__c ce : this.ceInsertedList) {
            if(surchargeMap.containsKey(ce.CZ_TnxId__c)) {
                c2g__codaJournalLineItem__c jli1 =  new c2g__codaJournalLineItem__c(
                    c2g__Journal__c = this.journal.Id, 
                    c2g__LineType__c = 'General Ledger Account',
                    c2g__GeneralLedgerAccount__c = this.sje.GLA_Surcharge__c,
                    c2g__LineDescription__c = ce.c2g__Description__c +' Surcharge',
                    c2g__Dimension1__c = this.sje.Dim1_Bank_Account__c,
                    c2g__Value__c = -surchargeMap.get(ce.CZ_TnxId__c)
                );
                jliList.add(jli1);

                c2g__codaJournalLineItem__c jli2 = new c2g__codaJournalLineItem__c(
                    c2g__Journal__c = this.journal.Id, 
                    c2g__LineType__c = 'Bank Account',
                    c2g__GeneralLedgerAccount__c = this.sje.GLA_Bank_Account__c,
                    c2g__LineDescription__c = ce.c2g__Description__c +' Surcharge',
                    c2g__Dimension1__c = this.sje.Dim1_Bank_Account__c,
                    c2g__BankAccount__c = this.bankAcctId,
                    c2g__Value__c = surchargeMap.get(ce.CZ_TnxId__c)
                );
                jliList.add(jli2);
            }
        }
        return jliList;
    }

    public void postJournal() {
        c2g.codaapicommon.Reference journalRef = c2g.CODAAPICommon.getRef(this.journal.Id, null);
        c2g.CODAAPICommon_10_0.Context cntx = new c2g.CODAAPICommon_10_0.Context();
        cntx.CompanyName = 'NCM Associates, Inc.';
        if(!Test.isRunningTest()) {
            c2g.CODAAPIJournal_12_0.PostJournal(cntx, journalRef);
        }
    }
}