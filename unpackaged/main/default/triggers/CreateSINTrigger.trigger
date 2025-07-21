trigger CreateSINTrigger on Create_SIN__e (after insert) {
    String logTag = 'CreateSINTrigger';
    Id dim1Id = [SELECT Id FROM c2g__codaDimension1__c WHERE c2g__ReportingCode__c = '7000'].Id;
    String NCMiDim2Code = System.Label.NCMiDim2Name;
    Id dim2Id = [SELECT Id FROM c2g__codaDimension2__c WHERE c2g__ReportingCode__c = :NCMiDim2Code].Id;
    Id ffCompanyId = [SELECT Id FROM c2g__codaCompany__c ORDER BY CreatedDate ASC LIMIT 1].Id;
    Id currencyId = [SELECT Id FROM c2g__codaAccountingCurrency__c WHERE Name = 'USD' LIMIT 1].Id;
    Id standardInvoiceRTId = Schema.SObjectType.c2g__codaInvoice__c.getRecordTypeInfosByName().get('Standard Invoice').getRecordTypeId();
    String ffAccountRef;

    List<SObject> sObs = new List<SObject>();
    List<Billing_Product__c> bProds = new List<Billing_Product__c>();
    List<Engagement_Attendee__c> engAttendees = new List<Engagement_Attendee__c>();
    List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
    for(Create_SIN__e evt : Trigger.new) {
        Opportunity opp = [SELECT Id, AccountId,
                                (SELECT Id, Product2Id, Quantity, UnitPrice, Description, Pending_Price__c,
                                    Product2.Type__c
                                FROM OpportunityLineItems
                                WHERE NCMi_Paid_Seat__c = true
                                AND Invoiced__c = false),
                                (SELECT Id FROM Billing_Products__r),
                                (SELECT Id FROM Engagement_Attendees__r)
                            FROM Opportunity
                            WHERE Id = :evt.OpportunityId__c];

        //Use the opportunity Is as the external Id on the invoice
        String extId = opp.Id.to15() + (String) Datetime.now().format('yyyyMMddHHmmssSSS');

        //Create an invoice from the opportunity.
        c2g__codaInvoice__c inv = new c2g__codaInvoice__c(
            c2g__Account__c = opp.AccountId,
            Billing_Account__c = evt.BillingAccountId__c,
            c2g__InvoiceStatus__c = 'In Progress',
            c2g__OwnerCompany__c = ffCompanyId,
            c2g__InvoiceCurrency__c = currencyId,
            c2g__CopyAccountValues__c = false,
            c2g__CustomerReference__c = ffAccountRef,
            c2g__InvoiceDate__c = Date.today(),
            c2g__Opportunity__c = opp.Id,
            AutoBillExtId__c = extId
        );
        sObs.add(inv);

        for(OpportunityLineItem oli : opp.OpportunityLineItems) {
            //make a SIN Line Item for each Opportunity LIne Item
            String description = oli.Description;
            if(oli.Product2.Type__c == 'GMEP') {
                description += ' - ' + System.Label.GMEP_Line_Description;
            } else if(oli.Product2.Type__c == 'Training Credits') {
                description += ' - ' + System.Label.TC_LIne_Description;
            }

            c2g__codaInvoiceLineItem__c ili = new c2g__codaInvoiceLineItem__c(
                c2g__Invoice__r = new c2g__codaInvoice__c(AutoBillExtId__c = extId),
                c2g__Product__c = oli.Product2Id,
                c2g__Quantity__c = oli.Quantity,
                c2g__UnitPrice__c = oli.UnitPrice,
                c2g__LineDescription__c = description,
                c2g__Dimension1__c = dim1Id,
                c2g__Dimension2__c = dim2Id,
                c2g__DeriveUnitPriceFromProduct__c = false,
                c2g__TaxValue1__c = 0,
                c2g__DeriveTaxRate1FromCode__c = false,
                c2g__CalculateTaxValue1FromRate__c = false
            );
            sObs.add(ili);
            //update Opportunity Product to Invoiced
            oliList.add(new OpportunityLineItem(Id = oli.Id, Invoiced__c = true));
        }  
        if(opp.OpportunityLineItems[0].Pending_Price__c) {
            if(!opp.Billing_Products__r.isEmpty()) {
                Billing_Product__c bp = new Billing_Product__c(
                    Id = opp.Billing_Products__r[0].Id,
                    Billing_Product_Status__c = 'Inactive'
                );
                if(String.isNotBlank(evt.BillingAccountId__c)) {
                    bp.Billing_Account__c = evt.BillingAccountId__c;
                }
                bProds.add(bp);
            }
            if(!opp.Engagement_Attendees__r.isEmpty()) {
                for(Engagement_Attendee__c ea : opp.Engagement_Attendees__r)
                engAttendees.add(new Engagement_Attendee__c(Id = ea.Id, Billing_Account__c = evt.BillingAccountId__c));
            }
        }              
    
        List<Database.SaveResult> results1 = Database.update(oliList, false);
        Logger.logErrorList(logTag, results1, oliList);

        //Insert Invoices and Line Items and log any errors
        List<Database.SaveResult> results = Database.insert(sObs, false);
        Logger.logErrorList(logTag, results, sObs);
        NotificationUtility nu = new NotificationUtility();
        nu.errorList('Error Creating Invoice', results, sObs, evt.SalespersonId__c);

        //find successful invoice inserts to post
        String p = c2g__codaInvoice__c.SObjectType.getDescribe().getKeyPrefix();
        List<Id> invIdList = new List<Id>();
        for(Integer i = 0; i < results.size(); i++) {
            if(results[i].isSuccess() && String.valueOf(sObs[i].Id).left(3).equals(p)) { 
                c2g__codaInvoice__c invoice = (c2g__codaInvoice__c) sObs[i];
                invIdList.add(invoice.Id);
            }
        }

        //post the invoices by setting the c2g__TriggerPosting__c = 'Synchronous' or 'Asynchronous'
        List<c2g__codaInvoice__c> invPostList = new List<c2g__codaInvoice__c>();
        for(Id invId : invIdList) {
            invPostList.add(new c2g__codaInvoice__c(Id = invId, c2g__TriggerPosting__c = 'Synchronous'));
        }
        List<Database.SaveResult> dsrList = Database.update(invPostList, false);
        Logger.logErrorList(logTag, dsrList, invPostList);
        nu.errorList('Error Posting Invoice', dsrList, sObs, evt.SalespersonId__c);

        //call batch to send invoice to CZ
        SendInvoicesToCZBatch bat = new SendInvoicesToCZBatch(invIdList);
        if(!Test.isRunningTest()) {
            Database.executeBatch(bat, 1);
        }
        
        //if it was a waitlist, then update the billing product and engagement attendee that was created 
        //before with the Billing Account.
        if(!bProds.isEmpty()) {
            List<Database.SaveResult> dsrList2 = Database.update(bProds, false);
            Logger.logErrorList(logTag, dsrList2, bProds);
        }
        if(!engAttendees.isEmpty()) {
            List<Database.SaveResult> dsrList3 = Database.update(engAttendees, false);
            Logger.logErrorList(logTag, dsrList3, engAttendees);
        }
    }
}