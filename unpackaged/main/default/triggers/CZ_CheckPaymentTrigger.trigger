trigger CZ_CheckPaymentTrigger on CZ_Check_Payment__e (after insert) {
    System.enqueueJob(new CZ_CheckPaymentQueueable(trigger.new));
}