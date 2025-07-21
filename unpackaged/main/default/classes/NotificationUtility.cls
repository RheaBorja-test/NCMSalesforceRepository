//Test Coverage for this class is provided by CreateSINTrigger_Test.cls
public class NotificationUtility {
    public Id notificationTypeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName='Desktop_Mobile'].Id;

    public void errorList(String title, List<Database.SaveResult> results, List<SObject> sObs, Id oppUser) {
        Set<String> recipientsIds = new Set<String>{oppUser};

        //create map of invoice line item ids to invoice.
        Map<Id,c2g__codaInvoice__c> liInvMap = new Map<Id,c2g__codaInvoice__c>();
        
        //loop through results and create an error notification where needed
        for(Integer i = 0; i < results.size(); i++) {
            if(!results[i].isSuccess()) {
                String targId;
                if(sObs[i].getSObjectType().getDescribe().getName() == 'c2g__codaInvoice__c') {
                    c2g__codaInvoice__c inv = (c2g__codaInvoice__c) sObs[i];
                    targId = inv.c2g__Opportunity__c;
                } else {
                    c2g__codaInvoiceLineItem__c ili = (c2g__codaInvoiceLineItem__c) sObs[i];
                    if(ili.Id == null) {
                        continue;
                    }
                    targId = liInvMap.get(ili.Id).c2g__Opportunity__c;
                }
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle(title);
                notification.setBody('An error was encountered while converting this Opportunity to an invoice. Please notify the Salesforce Team.');
                notification.setNotificationTypeId(this.notificationTypeId);
                notification.setTargetId(targId);
                notification.send(recipientsIds); 
            }           
        }
    }
}