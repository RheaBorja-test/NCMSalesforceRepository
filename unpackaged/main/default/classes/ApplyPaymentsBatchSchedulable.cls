global class ApplyPaymentsBatchSchedulable implements Schedulable {
    global void execute(SchedulableContext sc) {
       ApplyPaymentsBatch b = new ApplyPaymentsBatch(); 
       Database.executeBatch(b,25);
    }
 }