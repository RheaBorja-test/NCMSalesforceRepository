global class BatchCreateInvoice implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts
{
    public String query;
    public Boolean hasErrors = false;
    public Boolean queryLimitError = false;
    public String lastRequiredFieldError = '';
    public Boolean errorListTruncated = false;
    public String[] errorList = new String[]{  };
    public Id ffCompanyId;
    public Id companyCurrencyId;
    public Id pmtPeriodId;
    public Id notifyUserId;
    public Boolean debug = false;
    public Boolean chainBatches = false;
    public List<BuildInvoiceResult> results = new List<BuildInvoiceResult>();
    public class BuildInvoiceResult
    {
        public Boolean success;
        public Boolean withWarning;
        public String message;
        public String Id;
        public BuildInvoiceResult(Boolean success, Boolean withWarning, String message, String Id)
        {
            this.success = success;
            this.message = message;
            this.Id = Id;
        }

    }

    global database.Querylocator start(Database.BatchableContext BC)
    {
        this.query = 'SELECT Id, Name, Description, Ready_To_Invoice__c, Recurring_Status__c, AccountId, Billing_Account__c, Account.c2g__CODAFinanceContact__c, Next_Invoice_Date__c, Period__c, Frequency__c, (SELECT Id, Product2Id, Description, Dimension_1__c, Dimension_2__c, Dimension_3__c, Dimension_4__c, Quantity, UnitPrice, Recurring_Payment__c, Ready_To_Invoice__c, Invoiced__c FROM OpportunityLineItems WHERE (Ready_To_Invoice__c = True)) FROM Opportunity WHERE Recurring_Status__c = \'Active\'  AND Next_Invoice_Date__c = TODAY ';
        if ( Test.isRunningTest() )
            query += ' AND Type = \'BatchTestOpp\'';
        Database.QueryLocator result = Database.getQueryLocator(this.query);
        Recurring_Invoice_Settings__c ncm = Recurring_Invoice_Settings__c.getValues( 'NCM Settings' );
        debug = ncm.debug__c;
        notifyUserId = ncm.BatchMonitorUserId__c;
        chainBatches = ncm.Chain_Batches__c;
        return result;
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<Id, Opportunity> scopeMap = new Map<Id, Opportunity>();
        Map<Id, Id> conToOpp = new Map<Id, Id>();
        List<Contact> billingContacts = new List<Contact>();
        List<c2g__codaInvoice__c> ffInvoices = new List<c2g__codaInvoice__c>();
        List<Opportunity> opportunity = new List<Opportunity>();
        List<c2g.codaapicommon.reference> invoiceRefs = new List<c2g.codaapicommon.reference>();
        List<Id> invoiceToPost = new List<Id>();
        //BuildInvoiceResult result;

        // Create a map of opportunities
        scopeMap = createScopeMap(scope);
        System.Debug('scopeMap : ' + scopeMap);
        //Checks if company info has been setup and does so if not.
        getCompanyInfo();
        // Map billing contact Id's to Opportunity Id for bulk processing
        conToOpp = findBillingContacts(scope);

        if (!conToOpp.isEmpty()) {
            // Loop through scope and create invoices
            for(Sobject obj : scope) {
                Opportunity opp = (Opportunity)obj;
                ffInvoices.add(createInvoice(opp));
            }
            if(!ffInvoices.isEmpty()) {
                if(debug) {
                    System.Debug('ffInvoice to insert : ' + ffInvoices);
                }
                Database.SaveResult[] result = Database.Insert(ffInvoices);
                if(debug) {
                    System.Debug('ffInvoices inserted : ' + result);
                }
                // Loop through each DML and record successes and failures
                for(c2g__codaInvoice__c chkInv : ffInvoices) {
                    if(chkInv.Id == null) {
                        results.add(new BuildInvoiceResult(false, false, 'Unable to build FinancialForce Invoice for Opportunity : ' + chkInv.c2g__Opportunity__c, null));
                        hasErrors = true;
                    } else {
                        results.add(new BuildInvoiceResult(true, false, 'FinancialForce Invoice created : ' + chkInv.Id + ' for line items from Opportunity : ' + chkInv.c2g__Opportunity__c, chkInv.Id));
                        invoiceRefs.add(c2g.CODAAPICommon.getRef(chkInv.Id, null));
                        invoiceToPost.add(chkInv.Id);
                        opportunity.add(setNextInvoice(scopeMap.get(chkInv.c2g__Opportunity__c)));
                    }
                }
                if(debug) {
                    System.Debug('Opps to update to next invoice date : ' + opportunity);
                }
                Database.SaveResult[] resultOpp = Database.Update(opportunity);
                for(Database.SaveResult r : resultOpp) {
                    if (!r.isSuccess()) {
                        results.add(new BuildInvoiceResult(false, false, 'Error Unable to update Next Invoice Date on Opportunity : ' + r.getId(), null));
                        hasErrors = true;
                    }
                }
                if(debug) {
                    System.Debug('Invoices being posted: ' + invoiceRefs);
                }

                // Bulk post financial force invoices
                c2g.CODAAPICommon_10_0.Context cntx = new c2g.CODAAPICommon_10_0.Context();
                cntx.CompanyName = 'NCM Associates, Inc.';
                c2g.CODAAPISalesInvoice_10_0.BulkPostInvoice(cntx, invoiceRefs);
                // Because there is no way to know from this method if the post was successful without requerying the invoices just looping through and assuming successful
                // If this becomes a concern then query all Invoices and check if they are complete and then record.

                for ( Id chkPost : invoiceToPost ) {
                    results.add(new BuildInvoiceResult(true, false, 'FinancialForce Invoice posted.', chkPost));
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC) {

        List<Batch_Job__c> container = new List<Batch_Job__c>();
        Batch_Job__c con = new Batch_Job__c(  );
        con.name = 'Batch Invoice Processing ';
        con.Has_Errors__c = hasErrors;
        container.add(con);
        System.Debug('BatchJob Before Insert ' + con + ' Container LIst ' + container);
        Database.SaveResult[] resultBatch = Database.Insert ( container );

        if (hasErrors) {
            List<task> tasks = new List<task>();
            task t = new Task();
            t.Type = 'General Task';
            t.Subject = 'Errors in the last BatchCreateInvoice run ' + container[0].Id;
            t.ActivityDate = Date.today();
            t.Description = 'There were Errors in the last batch run that creates and posts Financial Force Invoices. Please go to the Admin console and review the logs.';
            t.Status = 'Not Started';
            t.WhatId = con.Id;
            t.OwnerId = notifyUserId;
            tasks.add(t);
            Database.SaveResult[] resultTask = Database.Insert (tasks);
        }
    }

    private void getCompanyInfo() {
        //We want the batch to stop if any of these cannot be set therefore no exceptions will be caught here.
        
        if ( ffCompanyId == null )
        {
            List<c2g__codaCompany__c> ffCompanyList = new List<c2g__codaCompany__c>();
            ffCompanyList = [SELECT Name, 
                                    Id, 
                                    CreatedDate
                             FROM c2g__codaCompany__c
                             ORDER BY CreatedDate ASC
                             LIMIT 1];
            ffCompanyId = ffCompanyList[0].Id;
            if ( debug )
                System.Debug('ffCompanyId : ' + ffCompanyId);
        }

        if ( companyCurrencyId == null )
        {
            c2g__codaAccountingCurrency__c[] currencies = [SELECT c2g__OwnerCompany__c, 
                                                                  Name
                                                           FROM c2g__codaAccountingCurrency__c
                                                           WHERE Name = 'USD'];
            companyCurrencyId = currencies[0].id;
            if ( debug )
                System.Debug('companyCurrencyId : ' + companyCurrencyId);
        }

        if ( pmtPeriodId == null )
        {
            c2g__codaPeriod__c[] periods = [SELECT Id, 
                                                   c2g__StartDate__c, 
                                                   c2g__EndDate__c, 
                                                   c2g__PeriodNumber__c
                                            FROM c2g__codaPeriod__c
                                            WHERE c2g__OwnerCompany__c = :ffCompanyId AND c2g__StartDate__c <= :Date.Today(  ) AND c2g__EndDate__c >= :Date.Today(  )
                                            ORDER BY c2g__EndDate__c DESC];
            pmtPeriodId = periods[0].Id;
            if ( debug )
                System.Debug('pmtPeriod : ' + periods[0]);
        }
    }

    private Map<Id, Opportunity> createScopeMap(List<sObject> scope)
    {
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        for ( sObject obj : scope )
        {
            Opportunity opp = ( Opportunity )obj;
            oppMap.put(opp.Id, opp);
        }
        return oppMap;
    }

    private Map<Id, Id> findBillingContacts(List<sObject> scope)
    {
        Map<Id, Id> conToOpp = new Map<Id, Id>();
        // Create a map of contactId to opportunitId called conToOpp
        for ( sObject obj : scope )
        {
            Opportunity opp = ( Opportunity )obj;
            if ( opp.Account.c2g__CODAFinanceContact__c != null )
            {
                conToOpp.put(opp.Account.c2g__CODAFinanceContact__c, opp.Id);
            }
            if ( opp.Account.c2g__CODAFinanceContact__c == null )
            {
                this.hasErrors = true;
                addError('No Billing Contact Assigned to Opportunity: ' + opp.Id + '.Error: No value for Account.c2g__CODAFinanceContact__c on the attached Account: ' + opp.AccountId);
            }
        }
        if ( debug )
            System.Debug('conToOpp : ' + conToOpp);
        return conToOpp;
    }

    private c2g__codaInvoice__c createInvoice(Opportunity opp)
    {
        // Create Invoice
        Id taxCode;
        String ffAccountRef;
        String batchProcessingAction = 'Process using default Payment Method on Contact';

        c2g__codaInvoice__c salesInvoice = new c2g__codaInvoice__c();
        if ( Test.isRunningTest() )
        {
            System.Debug('Opp Name  to set description : ' + opp.Description);
            salesInvoice.c2g__InvoiceDescription__c = 'BatchProcessInvoicePaymentsTest';
            if ( opp.Description == 'BatchTestOppPayError' )
                salesInvoice.c2g__InvoiceDescription__c = 'Error';
        }

        OpportunityLineItem lnItm = [SELECT Dimension_1__c, 
                                            Dimension_2__c
                                     FROM OpportunityLineItem
                                     WHERE OpportunityId = :opp.id AND Ready_to_Invoice__c = true
                                     LIMIT 1];
        salesInvoice.c2g__Dimension1__c = lnitm.Dimension_1__c;
        salesInvoice.c2g__Dimension2__c = lnitm.Dimension_2__c;

        salesInvoice.c2g__Account__c = opp.AccountId;
        salesInvoice.Billing_Account__c = opp.Billing_Account__c;
        salesInvoice.c2g__InvoiceStatus__c = 'In Progress';
        salesInvoice.c2g__Period__c = pmtPeriodId;
        salesInvoice.c2g__TaxCode1__c = taxCode;
        salesInvoice.c2g__OwnerCompany__c = ffCompanyId;
        salesInvoice.c2g__Opportunity__c = opp.Id;
        salesInvoice.c2g__InvoiceCurrency__c = companyCurrencyId;
        salesInvoice.c2g__CopyAccountValues__c = false;  // disable copy of tax code details from account record
        salesInvoice.c2g__CustomerReference__c = ffAccountRef;

        if ( debug )
            System.Debug('sales Invoice to insert : ' + salesInvoice);
        return salesInvoice;
    }

    private Opportunity setNextInvoice(Opportunity currentOpp)
    {

        String period = currentOpp.Period__c;
        Decimal freq = currentOpp.Frequency__c;
        Date invoiceDate = currentOpp.Next_Invoice_Date__c;
        Date nextInvoiceDate;

        if ( period == 'Month' )
        {
            nextInvoiceDate = invoiceDate.addMonths((integer) freq);
        }
        if ( period == 'Quarter' )
        {
            nextInvoiceDate = invoiceDate.addMonths(3 * (Integer) freq);
        }
        if ( period == 'Year' )
        {
            nextInvoiceDate = invoiceDate.addYears((Integer) freq);
        }

        //Integer daysUntilNextInvoice = Date.Today().daysBetween(nextInvoiceDate);
        //Integer daysBetweenInvoices = invoiceDate.daysBetween(nextInvoiceDate);
        Opportunity updatedOpp = new Opportunity();
        updatedOpp.id = currentOpp.Id;
        updatedOpp.Next_Invoice_Date__c = nextInvoiceDate;

        return updatedOpp;
    }

    public void addError(String err)
    {
        errorList.add(err);
    }

    public class LocalException extends Exception
    {
    }

}