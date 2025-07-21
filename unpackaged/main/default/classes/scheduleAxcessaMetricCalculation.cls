public class scheduleAxcessaMetricCalculation implements Schedulable
{
	public void execute(SchedulableContext sc)
	{
		batchAxcessaMetricCalculation batchable = new batchAxcessaMetricCalculation(  );
		Integer batchSize = 25;

		if ( Test.isRunningTest() )
		{
			batchSize = 1;
		}

		Database.executeBatch(batchable, batchSize);
	}
}