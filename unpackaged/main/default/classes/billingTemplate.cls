public class billingTemplate {
	@AuraEnabled public string productName { get; set; }
	@AuraEnabled public string productURL { get; set; }
	@AuraEnabled public string productId { get; set; }
	@AuraEnabled public string displayURL { get; set; }
    
    @AuraEnabled public string frequency { get; set; }
    @AuraEnabled public boolean flowProvisioning { get; set; }

	@AuraEnabled public string pbId { get; set; }
	@AuraEnabled public string pbeId { get; set; }

	@AuraEnabled public Decimal listPrice { get; set; }
	@AuraEnabled public Decimal salePrice { get; set; }
	@AuraEnabled public Decimal quantity { get; set; }

	@AuraEnabled public string lineDescription { get; set; }
	@AuraEnabled public string billingNotes { get; set; }
	@AuraEnabled public string discountReason { get; set; }
    @AuraEnabled public string level1Name { get; set; }
	@AuraEnabled public Boolean shippedProduct { get; set; }

	@AuraEnabled public Integer meetingsIncluded {get; set;}

    public static boolean isValid(billingTemplate billTemp){
        if(
            billTemp.productId != null &&
            billTemp.pbId != null &&
            billTemp.quantity != null &&
            billTemp.salePrice != null
        ){
            return true;
        } else{
            return false;
        }
    }

	public billingTemplate() {
	}

	public billingTemplate(PricebookEntry pbe) {
		System.debug('billingTemplate Method is running');
		this.productName = pbe.Product2.Name;
		this.productURL = '/' + pbe.Product2Id;
		this.productId = pbe.Product2Id;
		this.shippedProduct = pbe.Product2.Shipped_Product__c;

		if(pbe.Product2.displayURL != null) {
			this.displayURL = pbe.Product2.displayURL;
		}
        if(pbe.Product2.Locked_Frequency__c != null){
            this.frequency = pbe.Product2.Locked_Frequency__c;
        }
        if(pbe.Product2.Core_Product__c){
            this.flowProvisioning = true;
        }

		this.pbId = pbe.Pricebook2Id;
		this.pbeId = pbe.Id;
		this.listPrice = pbe.UnitPrice;
		this.salePrice = pbe.UnitPrice;
		this.quantity = 1;
		this.level1Name = pbe.Product2.Level_1_Name__c;
		this.meetingsIncluded = Integer.valueOf(pbe.Product2.Meetings_Included__c);
	}

}