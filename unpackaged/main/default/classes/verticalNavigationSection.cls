public class verticalNavigationSection {
    @AuraEnabled public string label {get; set;}
    @AuraEnabled public list<sectionItem> items {get; set;}
    
    public verticalNavigationSection() {

    }

    public verticalNavigationSection(string lbl, list<sectionItem> itms){
        this.label = lbl;
        this.items = itms;
    }

    public class sectionItem{
        @AuraEnabled public string label {get; set;}
        @AuraEnabled public string name {get; set;}
        @AuraEnabled public string icon {get; set;}

        public sectionItem(string lbl, string nme){
            this.label = lbl;
            this.name = nme;
        }
        public sectionItem(string lbl, string nme, string icn){
            this.label = lbl;
            this.name = nme;
            this.icon = icn;
        }
    }
}