global class ScheduleCreateInvoiceAndPayment implements Schedulable {
	global void execute(SchedulableContext context){
		
		BatchCreateInvoice bJob = new BatchCreateInvoice();
		Database.executeBatch(bJob,1);
	}
}