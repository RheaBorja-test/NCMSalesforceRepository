public class InvocableBatchSendInvoices {
    @InvocableMethod(label='Send Invoices to Payment Processor')
    public static void InvocableBatchSendInvoices(List<List<Id>> ids) {
        SendInvoicesToCZBatch b = New SendInvoicesToCZBatch(ids[0]);
        database.executebatch(b, 1);
    }
}