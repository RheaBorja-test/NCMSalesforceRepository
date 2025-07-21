public with sharing class Product2Controller {
    public static void createProduct(List<Product2> newList, Map<Id,Product2> oldMap) {
        if(!System.isQueueable()) {
            Map<Id,PaymentModel.CZCreateItem> czItems = new Map<Id,PaymentModel.CZCreateItem>();
            for(Product2 prod : newList) {
                //find if item is new or certain fields were updated
                if((oldMap.isEmpty()
                || !prod.Name.equals(oldMap.get(prod.Id).Name) 
                || prod.Product_Value__c != oldMap.get(prod.Id).Product_Value__c 
                || prod.Description != oldMap.get(prod.Id).Description)
                && prod.IsActive) {
                    //create the payment model item
                    PaymentModel.CZCreateItem itm = new PaymentModel.CZCreateItem();
                    itm.itemId = prod.CZ_ItemId__c;
                    itm.itemName = prod.Name;
                    itm.itemSaleDescription = prod.Description ?? prod.Name;    
                    itm.itemSalePrice = prod.Product_Value__c >= 0 ? prod.Product_Value__c : 0;
                    itm.itemType = 'Service';
                    czItems.put(prod.Id, itm);
                }
            }
            if(czItems.size() > 0) {
                System.enqueueJob(new sendIemToCZQueueable(czItems));
            }
        }
    } 

}