trigger CZ_WebHookTrigger on CZ_WebHook__e (after insert) {
    List<PaymentModel.CZTransactionData> tranList = new List<PaymentModel.CZTransactionData>();
    List<String> czTnxIds = new List<String>();
    
    for(CZ_WebHook__e evt : Trigger.new) {
        if(evt.tnxInvoiceId__c.contains(',') && evt.amount_with_out_surcharge__c == null) {
            czTnxIds.add(evt.tnxId__c);
            continue;
        } else {
            PaymentModel.CZTransactionData tran = new PaymentModel.CZTransactionData();
            tran.tnxAmount = String.valueOf(evt.tnxAmount__c);
            tran.tnxID = evt.tnxID__c;
            tran.tnxStatus = evt.tnxStatus__c;
            tran.tnxType = evt.tnxType__c;
            tran.tnxInvoiceId = evt.tnxInvoiceId__c; 
            tran.tnxInvoiceRef = evt.tnxInvoiceRef__c;
            tran.tnxCustomDataFields = new PaymentModel.CZTnxCustFields();
            tran.tnxCustomDataFields.amount_with_out_surcharge = evt.amount_with_out_surcharge__c;
            tran.tnxCustomDataFields.surcharge_amount_value = evt.surcharge_amount_value__c;
            tranList.add(tran);
        }
    }

    //Instantiate the ApplyPayments batch with a page # of -2 so that it won't trigger the batch to make a callout
    //to CZ. Pass the tranList to the batch, then execute with a max batchsize of 25.
    if(tranList.size() > 0) {
        ApplyPaymentsBatch apb = new ApplyPaymentsBatch(-2);
        apb.theList = tranList;
        Database.executeBatch(apb, 25);
    }
    for(String czTnxId : czTnxIds) {
        ApplyPaymentsBatch apb = new ApplyPaymentsBatch(-2);
        apb.czTnxId = czTnxId;
        Database.executeBatch(apb, 25);
    }
}