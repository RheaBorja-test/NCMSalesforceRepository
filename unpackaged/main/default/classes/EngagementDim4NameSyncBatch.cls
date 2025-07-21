global without sharing class EngagementDim4NameSyncBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private String logTag = 'EngagementDim4NameSyncBatch';
    private List<c2g__codaDimension4__c> dim4Updates;

    global EngagementDim4NameSyncBatch() {
        dim4Updates = new List<c2g__codaDimension4__c>();
    }

    
    global Database.QueryLocator start(Database.BatchableContext BC) {

        Set<Id> engagementIdSet = new Set<Id>();

        if(Test.isRunningTest()){
            return Database.getQueryLocator('SELECT Id, Name, Dimension_4__c FROM Engagement__c ORDER BY CreatedDate DESC LIMIT 1');
        } 
        
        
        // Query the Engagement object's History table for any Engagements 
        // whose Name field was updated today.
        List<Engagement__History> ehResults = [SELECT CreatedDate,Field,NewValue,OldValue,ParentId FROM Engagement__History WHERE Field = 'Name' AND CreatedDate = LAST_N_DAYS:2];
        
        if(ehResults.isEmpty()){
            System.debug(logTag + 'WARNING: NO ENGAGEMENT HISTORY RESULTS FOUND. It appears that no engagement names were changed today. Exiting batch.');
        } else {
            System.debug(logTag + 'There are ' + ehResults.size() + ' Engagement History records to process.');
        }

        for(Engagement__History eh :ehResults){
            engagementIdSet.add(eh.ParentId);
        }

        // if(engagementIdSet.isEmpty()){
        //     System.debug(logTag + 'NO ENGAGEMENTS HAD NAME CHANGES TODAY. EXITING..');
        //     return null;
        // } else {
            System.debug(logTag + 'There are ' + engagementIdSet.size() + ' engagements with name changes to sync with their DIM4 records.');
            String qry = 'SELECT Id, Name, Dimension_4__c, Dimension_4__r.Name FROM Engagement__c WHERE Id IN :engagementIdSet';
            return Database.getQueryLocator(qry);
        //}

    }

    global void execute(Database.BatchableContext BC, List<Engagement__c> scope) {
        
        System.debug(logTag + 'Processing ' + scope.size() + ' Engagement records.');

        for(Engagement__c eng:scope){

            if(eng.Dimension_4__c != null){

                //if(eng.Name != eng.Dimension_4__r.Name){
                    // Update the DIM4 record Name to match the Engagement Name.
                    System.debug(logTag + 'Processing DIM4 record [' + eng.Dimension_4__c + '] for engagement [' + eng.Id + '].');
                    c2g__codaDimension4__c dim4 = new c2g__codaDimension4__c(
                        Id = eng.Dimension_4__c,
                        Name = eng.Name
                    );
                    dim4Updates.add(dim4);
                //} else {
                //    System.debug('Engagement ' + eng.Name + ' was updated recently but properly matches its Dim4 Name. Skipping..');
                //}

            } else {

                // The Engagement DIM4 field is currently blank.
                System.debug(logTag + 'Engagement does not have a DIM4 assigned yet: ' + eng.Id + '. Skipping..');

            }
        }

        if( !dim4Updates.isEmpty() ){

            System.debug(logTag + 'dim4Updates contains ' + dim4Updates.size() + ' records.');

            Database.SaveResult[] lsr = Database.update(dim4Updates, false);
            Integer i = 0;

            for(Database.SaveResult sr:lsr){

                c2g__codaDimension4__c recUpdated = dim4Updates[i]; // The record in the collection that was updated.

                if(sr.isSuccess()){
                    System.debug(logTag + 'Updated DIM4 to [' + recUpdated.Name + '] for record ' + recUpdated.Id);
                } else {
                    System.debug(logTag + 'Error updating DIM4 to [' + recUpdated.Name + '] for record ' + recUpdated.Id + ': ' + sr.errors[0].getMessage());
                    Logger.logError(logTag, 'Error', 'Batch Job', 'DIM4 Sync Error: ' + recUpdated.Id, sr.errors[0].getMessage(), null);
                }
                
                i++;
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug(logTag + 'Finished. ' + dim4Updates.size() + ' DIM4 records updated.');
    }

}