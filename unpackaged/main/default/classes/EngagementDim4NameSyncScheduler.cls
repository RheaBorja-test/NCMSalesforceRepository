global class EngagementDim4NameSyncScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new EngagementDim4NameSyncBatch());
    }
}