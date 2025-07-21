/* customValidation and onChange methods were written as part of the NCMi Paid Seats
   project. The intention is to keep anyone from changing or deleting the opportunity 
   line items after the invoice has been created.
*/
public with sharing class OpportunityProductController {
    public class OpportunityProductException extends Exception {}

    //checks to see if the opportunity is in a stage that should be locked and has
    //NCMi Paid Seat products. If these are true it throws a custom exception.
    public static void customValidation(List<OpportunityLineItem> olis) {
        if(UserInfo.getName() != 'SF Admin') {
            List<OpportunityLineItem> oliList = [
                SELECT Id, Name, Opportunity.StageName, Opportunity.NCMi_Paid_Seat__c
                FROM OpportunityLineItem
                WHERE Id IN :olis
            ];
            List<String> stgs = new List<String>{'Waitlist', 'Invoice Sent', 'Invoice Paid', 'Closed Won'};
            
            for(OpportunityLineItem oli : oliList) {
                if(oli.Opportunity.NCMi_Paid_Seat__c > 0 && stgs.contains(oli.Opportunity.StageName)) {
                    Throw new OpportunityProductException('Products cannot be edited or deleted while there is an active invoice on the opportunity. To make product changes, please cancel the invoice first.');
                }
            }
        }
    }

    //if the quantity or unitprice have been changed, then send the oli to custom validation
    public static void onChange(List<OpportunityLineItem> newList, Map<Id,OpportunityLineItem> oldMap) {
        List<OpportunityLineItem> changedList = new List<OpportunityLineItem>();
        for(OpportunityLineItem oli : newList) {
            if(oli.Quantity != oldMap.get(oli.Id).Quantity
                || oli.UnitPrice != oldMap.get(oli.Id).UnitPrice
            ) {
                changedList.add(oli);
            }
        }
        customValidation(changedList);
    }
}