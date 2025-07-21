public class Product2ChargeZoomSync implements Database.Batchable<SObject>, Database.Stateful {
    
    private final String logTag = '[Product2ChargeZoomSync]';
    public Integer recordsProcessed {get;set;}

    public Product2ChargeZoomSync() {
        recordsProcessed = 0; // initialize counter.
    }


    public Database.QueryLocator start(Database.BatchableContext bc){
        System.debug(logTag + 'Starting.');
        String qry = 'SELECT Id, Name, Product_Value__c, Description, IsActive, CZ_ItemId__c FROM Product2 WHERE CreatedDate = Today OR LastModifiedDate = Today';
        return Database.getQueryLocator(qry);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope){
        List<Product2> prodList = (List<Product2>)scope;
        System.debug(logTag + 'There are ' + scope.size() + ' Product2 records to sync with ChargeZoom.');
        for(Product2 prod:prodList) System.debug(logTag + '\t' + prod.Name);

        Product2Controller.createProduct(scope, new Map<Id,Product2>());
        recordsProcessed += prodList.size();
        System.debug(logTag + 'recordsProcessed: ' + recordsProcessed);
    }

    public void finish(Database.BatchableContext bc){
        System.debug(logTag + 'Complete. ' + recordsProcessed + ' products synced with CZ.');
    }

}