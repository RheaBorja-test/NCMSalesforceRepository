public class CZ_LoadProductsBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    public String productId {get;set;}

    private final String logTag = '[CZ_LoadProductsBatch]';
    private List<Product2> productUpdates;

    public CZ_LoadProductsBatch(Id productId) {
        productUpdates = new LIst<Product2>();
        this.productId = productId;
    }


    public Database.QueryLocator start(Database.BatchableContext BC) {
        String qry = 'SELECT Id, Name, Description, Product_Value__c ' + 
                    'FROM Product2 WHERE CZ_ItemId__c = null AND IsActive = true';
        
        // If a Product ID was passed to the batch, just process that one Product.
        if(this.productId != null){
            qry += ' AND Id = \'' + this.productId + '\'';
        } 

        System.debug(logTag + 'Query: ' + qry);
        return Database.getQueryLocator(qry);
    }


    public void execute(Database.BatchableContext BC, List<Product2> scope) {
        
        System.debug(logTag + 'There are Billing Accounts to process (scope size).');

        
        for(Product2 pr : scope){
            PaymentModel.CZCreateItem itm = new PaymentModel.CZCreateItem();
            itm.itemName = pr.Name;
            itm.itemType = 'Service'; //this field is required by CZ, but not used.
            itm.itemSalePrice = pr.Product_Value__c >= 0 ? pr.Product_Value__c : 0;
            itm.itemSaleDescription = pr.Description ?? pr.Name;

            try{
                ChargeZoomUtility cz = new ChargeZoomUtility();           
                PaymentModel.CZCreateItemResponse resp = cz.createItem(itm);
                // Check if successful
                if(resp.code == 200){
                    System.debug(logTag + 'CZ create item response: ' + resp.message + ' (' + resp.code + ')');
                    String czItemId = resp.data.ListId;
                    productUpdates.add(new Product2(Id = pr.Id, CZ_ItemId__c = czItemId));
                } else {
                    System.debug(logTag + 'Error with CZ create customer api call: ' + resp.message);
                }
            } catch (Exception ex){
                System.debug('Error creating customer in ChargeZoom: ' + ex.getMessage());
            }

        }

    }


    public void finish(Database.BatchableContext BC) {
        System.debug(logTag + 'CZ_LoadProductsBatch::finish');  
        
        if( !productUpdates.isEmpty() ){
            System.debug(logTag + 'There are ' + productUpdates.size() + ' Products to udpate with a CZ Item Id code.');
            Database.SaveResult[] saveResults = Database.update(productUpdates, false);
            Integer i=0;
            for(Database.SaveResult sr:saveResults){
                if( !sr.isSuccess() ){
                    Product2 pr = productUpdates[i];
                    System.debug(logTag + 'Error updating billing account ' + pr.Name + '. Error: ' + sr.getErrors()[0].getMessage());
                }
                i++;
            }
        } else {
            System.debug(logTag + 'No Products to update.');
        }  
        
    }
}