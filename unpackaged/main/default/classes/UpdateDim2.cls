public with sharing class UpdateDim2 {
    @invocablemethod(label='Update Dim 2') 
    public static void UpdateDim2(List<String> ids) {
        UpdateDim2Asynch updateDimTwo = new UpdateDim2Asynch(ids);
        Id jobId = System.enqueueJob(updateDimTwo);
        System.debug('~~~jobId: ' + jobId);
    }
}