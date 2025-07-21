public with sharing class sendIemToCZQueueable implements Queueable, Database.AllowsCallouts{
    public Map<Id,PaymentModel.CZCreateItem> items;
    public sendIemToCZQueueable(Map<Id,PaymentModel.CZCreateItem> items) {
        this.items = items;
    }

    public void execute(QueueableContext context) {
        //convert keyset to list and get the first Id
        List<Id> prodIdList = new List<Id>(items.keySet());
        Id prodId = prodIdList[0];
        try {
            System.debug('~~~prodId: ' + prodId);
            PaymentModel.CZCreateItem item = items.remove(prodId);
            ChargeZoomUtility czu = new ChargeZoomUtility();
            PaymentModel.CZCreateItemResponse itmRsp = czu.createItem(item);
            //if(item.itemId == null) {
                Product2 p = new Product2(
                    CZ_ItemId__c = itmRsp.data.ListId,
                    Id = prodId,
                    Last_CZ_Sync__c = DateTime.now()
                );
                update p;
            //}
        } catch (Exception ex) {
            Logger.logErrorEvent('sendIemToCZQueueable', null, UserInfo.getName(), ex.getTypeName(), ex.getMessage(), ex.getStackTraceString(), prodId);
        }

        //if there are still items in the map, then loop through the queueable again
        //unless this is a test.
        if(items.size() > 0 && !Test.isRunningTest()) {
            System.enqueueJob(new sendIemToCZQueueable(items));
        }
        
    }
}