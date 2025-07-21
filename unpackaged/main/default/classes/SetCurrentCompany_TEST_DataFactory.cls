@isTest
public class SetCurrentCompany_TEST_DataFactory {
    //this list of SObjectType to add to the queue might need to be updated when upgrading FFA – verify, in existing data, user queue's definition after upgrade
    public static final List<String> SOBJECT_TYPES_API_NAMES = new List<String>{'c2g__AsOfAging__c',
                                                                                'c2g__CancelPayment__c',
                                                                                'c2g__ReportingBalance__c',
                                                                                'c2g__codaAccountingCurrency__c',
                                                                                'c2g__codaBankAccount__c',
                                                                                'c2g__codaBankReconciliation__c',
                                                                                'c2g__codaBankStatement__c',
                                                                                'c2g__codaBudget__c',
                                                                                'c2g__codaCashEntry__c',
                                                                                'c2g__codaCashMatchingHistory__c',
                                                                                'c2g__codaCompany__c',
                                                                                'c2g__codaCreditNote__c',
                                                                                'c2g__codaCurrencyRevaluationGroup__c',
                                                                                'c2g__codaCurrencyRevaluation__c',
                                                                                'c2g__codaGroupingReference__c',
                                                                                'c2g__codaIntercompanyDefinition__c',
                                                                                'c2g__codaIntercompanyTransfer__c',
                                                                                'c2g__codaInvoice__c',
                                                                                'c2g__codaJournal__c',
                                                                                'c2g__codaMatchingReference__c',
                                                                                'c2g__codaPaymentMediaControl__c',
                                                                                'c2g__codaPaymentMediaSummary__c',
                                                                                'c2g__codaPaymentTemplate__c',
                                                                                'c2g__codaPayment__c',
                                                                                'c2g__codaPurchaseCreditNote__c',
                                                                                'c2g__codaPurchaseInvoice__c',
                                                                                'c2g__codaTextDefinition__c',
                                                                                'c2g__codaTransaction__c',
                                                                                'c2g__codaYear__c'};
    
    public static c2g__codaCompany__c createCurrentCompany(String CompanyName, 
                                                            User SomeUser, 
                                                            String recordType, 
                                                            Boolean selectAsCurrent, 
                                                            String taxRegistrationNumber) {
        //create the company user queue
        Group companyOwnerQueue = new Group(Type='Queue', Name=CompanyName);
        System.runAs(SomeUser) { 
            //to avoid mixed dml error
            insert companyOwnerQueue;
            //add SObjectType to be owned by the company user queue instead of its individual queue members (users)
            List<QueueSObject> queueSObjectList=new List<QueueSObject>();
            for(String sobjectTypeAPIName: SOBJECT_TYPES_API_NAMES) {
                QueueSObject queuesObjectTypeToAdd = new QueueSObject(SobjectType=sobjectTypeAPIName, QueueId=companyOwnerQueue.Id);
                queueSObjectList.add(queuesObjectTypeToAdd);
            }
            insert queueSObjectList;
            //Have the user select this queue as his current company
            if(selectAsCurrent) {
                insert new GroupMember(GroupId=companyOwnerQueue.Id, UserOrGroupId=someUser.ID);
            }
        }
        //create the company
        c2g__codaCompany__c company=new c2g__codaCompany__c(Name = companyName, 
                                                            c2g__VATRegistrationNumber__c = taxRegistrationNumber,
                                                            OwnerId = companyOwnerQueue.Id,
                                                            c2g__CashMatchingCurrencyMode__c = 'Account');
        if(recordType != null) {
            company.RecordTypeId = recordType;
        }
        System.runAs(SomeUser) {
            insert company;
            //give the user access to this company (optional…)
            c2g__codaUserCompany__c userCompany=new c2g__codaUserCompany__c(c2g__Company__c=company.Id, c2g__User__c=SomeUser.Id);
            insert userCompany;
            createOtherObjects(company.Id);
        }
        return company;
    }

    private static void createOtherObjects(Id companyId) {

        c2g__codaAccountingCurrency__c cur = new c2g__codaAccountingCurrency__c(Name = 'USD', c2g__DecimalPlaces__c = 2, 
                                                c2g__OwnerCompany__c = companyId, 
                                                c2g__Home__c = true,
                                                c2g__Dual__c = true);
        insert cur;
        c2g__codaGeneralLedgerAccount__c gla = new c2g__codaGeneralLedgerAccount__c(Name = 'TEST' , c2g__ReportingCode__c = 'TEST', c2g__Type__c = 'Profit and Loss');
        insert gla;
        Integer thisYear = Date.today().year();
        Date startOfYear = Date.newInstance(thisYear, 1, 1);
        Date endOfYear = Date.newInstance(thisYear, 12, 31);
        c2g__codaYear__c yr = new c2g__codaYear__c(c2g__NumberOfPeriods__c = 12, c2g__StartDate__c = startOfYear/*, c2g__EndDate__c =  endOfYear*/);
        insert yr;
        c2g.CODAYearWebService.calculatePeriods(yr.Id);  
        String bankName = System.Label.CCCashEntryBank;
        insert new c2g__codaBankAccount__c(Name = bankName,
                                            c2g__BankName__c = bankName,
                                            c2g__ReportingCode__c = '10101',
                                            c2g__AccountName__c = 'Test',
                                            c2g__AccountNumber__c = '123456',
                                            c2g__BankAccountCurrency__c =  cur.Id,
                                            c2g__GeneralLedgerAccount__c = gla.Id);      
    }
}