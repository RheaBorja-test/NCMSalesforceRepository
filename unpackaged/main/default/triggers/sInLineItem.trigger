trigger sInLineItem on c2g__codaInvoice__c (after insert) {

    list<c2g__codaInvoiceLineItem__c> sInLineItems = new list<c2g__codaInvoiceLineItem__c>();
    list<OpportunityLineItem> oppLineItemUpdates = new List<OpportunityLineItem>();
    for (c2g__codaInvoice__c sIn : system.trigger.new){
        
        if (sIn.c2g__Opportunity__c != null && sIn.Billing_Account__c == null) {
            list<OpportunityLineItem> oppLineItems = 
            [
                SELECT 
                    Id, 
                    Product2Id, 
                    Quantity, 
                    Description, 
                    UnitPrice, 
                    Dimension_1__c, 
                    Dimension_2__c, 
                    Dimension_3__c, 
                    Dimension_4__c,
                    OpportunityId, 
                    Recurring_Payment__c, 
                    Billing_Product__c
                FROM OpportunityLineItem 
                WHERE 
                    OpportunityId = :sIn.c2g__Opportunity__c AND 
                    Ready_to_Invoice__c = true AND 
                    Invoiced__c = false
            ];
            
            if (oppLineItems.size() > 0){
                
                for (OpportunityLineItem lineItem : oppLineItems){
                    c2g__codaInvoiceLineItem__c sInLineItem = new c2g__codaInvoiceLineItem__c();
                    
                    sInLineItem.c2g__Invoice__c = sIn.Id;
                    sInLineItem.c2g__Product__c = lineItem.Product2Id;
                    sInLineItem.c2g__DeriveUnitPriceFromProduct__c = false;
                    sInLineItem.c2g__Quantity__c = lineItem.Quantity;
                    sInLineItem.c2g__LineDescription__c = lineItem.Description;
                    sInLineItem.c2g__UnitPrice__c = lineItem.UnitPrice;
                    
                    sInLineItem.c2g__TaxValue1__c = 0;
                    sInLineItem.c2g__DeriveTaxRate1FromCode__c = false;
                    sInLineItem.c2g__CalculateTaxValue1FromRate__c = false;
                    
                    sInLineItem.Opportunity__c = lineItem.OpportunityId;
                    sInLineItem.OpportunityLineItem__c = lineItem.id;
                    sInLineItem.Billing_Product__c = lineItem.Billing_Product__c;
                    
                    sInLineItem.c2g__Dimension1__c = lineItem.Dimension_1__c;
                    sInLineItem.c2g__Dimension2__c = lineItem.Dimension_2__c;
                    sInLineItem.c2g__Dimension3__c = lineItem.Dimension_3__c;
                    sInLineItem.c2g__Dimension4__c = lineItem.Dimension_4__c;
                    
                    sInLineItems.add(sInLineItem);
                    if (lineItem.Recurring_Payment__c != true){
                        lineItem.Ready_to_Invoice__c = false;
                        lineItem.Invoiced__c = true;
                        oppLineItemUpdates.add(lineItem);
                    }
                }
                
            }            
        }

    }

    if (sInLineItems.size() > 0) {
        insert sInLineItems;   
    }
    if (oppLineItemUpdates.size() > 0) {
        update oppLineItemUpdates;
    }
}