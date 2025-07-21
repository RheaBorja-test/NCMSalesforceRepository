@isTest (SeeAllData=false)
public class autoConvLdTest{
    static testMethod void autoConvLdTest() {

        String acctRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NCM Client').getRecordTypeId();
        String contactRecType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId();
        
        Account acct = new Account(
            RecordTypeId = acctRecType,
            Name = 'Sample Auto Group',
            BillingStreet = '1 Auto Way',
            BillingCity = 'Sampleton',
            BillingState = 'North Carolina',
            BillingPostalCode = '28461',
            BillingCountry = 'United States',
            Validated_Account_Name__c = 'Sample Auto Group',
            Accounting_Invoice_Name__c = 'Sample Auto Group, Inc',
            Legal_Entity_Name__c = 'Sample Auto Group, Inc',
            AccountSource = 'Marketing', // required
            Industry = 'Auto Retail New', // required
            Franchise_s__c = 'Chevrolet;Dodge;Ford;Jeep',
            NumberOfEmployees = 400,
            AnnualRevenue = 30000000.00
        );
        insert(acct);

        Contact con = new Contact(
            RecordTypeId = contactRecType,
            FirstName = 'Marv',
            LastName = 'Sampleton',
            Title = 'CEO',
            NCM_Department__c = 'Executive',
            NCM_Title__c = 'Owner',
            AccountId = acct.Id,
            Email = 'marv.sampleton@ncmassociates.com',
            MailingStreet = '100 Automotive Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        insert con;

        Opportunity opp = new Opportunity(
            AccountId = acct.Id,
            CloseDate = Date.today(),
            StageName = 'Closed Won',
            Contract_Signed__c = 'Yes',
            Name = 'Test Opp'
        );
        insert opp;

        NCM_Lead_Entry__c nle = new NCM_Lead_Entry__c(Account__c = acct.Id, Contact__c = con.Id);
        
        List<Lead> lds = new List<Lead>();
        //[select id from Lead where Status != 'Qualified' limit 6];
        for(Integer i = 1; i <= 6; i++) {
            Lead l = new Lead(FirstName = 'First' + i, LastName = 'Last' + i, Company = 'Test Co. ' + i, NCM_Lead_Entry__c = nle.Id);
            lds.add(l);
        }
        insert lds;        
        
        List<AutoConvertLeads.vars> vars = new List<AutoConvertLeads.vars>();
        List<NCM_Lead_Entry__c> ncmLeads = new List<NCM_Lead_Entry__c>();
        
        for(Lead ld : lds) {
            AutoConvertLeads.vars var = new AutoConvertLeads.vars();
            var.ldId = ld.Id;
            vars.add(var);
            NCM_Lead_Entry__c ncmLead = new NCM_Lead_Entry__c(
                Account__c = acct.Id,
                Contact__c = con.Id,
                First_Name__c = ld.FirstName,
                Last_Name__c = ld.LastName,
                Lead__c = ld.Id
            );
            ncmLeads.add(ncmLead);
        }
        ncmLeads[0].Opportunity__c = opp.Id;
        insert ncmLeads;

        Lead ld1 = new Lead(
            Id = ncmLeads[0].Lead__c,
            NCM_Lead_Entry__c = ncmLeads[0].Id
        );
        update ld1;

        Test.startTest();
        try{
            AutoConvertLeads.LeadConvert(vars);
        } catch(DMLException er){
            system.debug(er);
        }
        
        Test.stopTest();

        Integer oppCount = [SELECT Id FROM Opportunity WHERE StageName = 'Closed Won'].Size();
        Assert.areEqual(1, oppCount);
    }
}