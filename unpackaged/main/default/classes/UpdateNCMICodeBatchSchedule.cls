global class UpdateNCMICodeBatchSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new UpdateNCMICodeBatch());
    }
}