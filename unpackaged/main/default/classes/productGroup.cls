public class productGroup{
        @AuraEnabled public string groupName { get; set; }
        @AuraEnabled public List<PricebookEntry> prods { get; set; }

        public productGroup(string groupName, List<PricebookEntry> prods){
            this.groupName = groupName;
            this.prods = prods;
        }

        public productGroup() {

        }
    }