global class Product2ChargeZoomSync_Schedule implements Schedulable {

	global void execute(SchedulableContext context){
		
		Product2ChargeZoomSync job = new Product2ChargeZoomSync();
		Database.executeBatch(job);
        
	}
}