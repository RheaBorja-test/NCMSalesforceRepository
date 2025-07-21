global with sharing class BillingAccountChargeZoomSync_Schedulable implements Schedulable{
    global void execute(SchedulableContext SC) {
        BillingAccountChargeZoomSync b = new BillingAccountChargeZoomSync();
        Database.executeBatch(b, 1);
    }
}