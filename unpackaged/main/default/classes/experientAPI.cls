public with sharing class experientAPI{
    @future(callout=true)
    public static void callExperient(id scnId, string barcode, id usrId) {
        
        Experient_API__c usrSett = Experient_API__c.getInstance(usrId);
        Experient_API__c orgDef = Experient_API__c.getOrgDefaults();
        
        string endPnt;
        string apiKey;
        string actCde;
        string bdgId;
        if (usrSett != null){
            if (usrSett.End_Point__c != null){
                endPnt = usrSett.End_Point__c;
            } else {
                endPnt = orgDef.End_Point__c;
            }
            if (usrSett.apiKey__c != null){
                apiKey = usrSett.apiKey__c;
            } else {
                apiKey = orgDef.apiKey__c;
            }
            if (usrSett.actcode__c != null){
                actCde = usrSett.actcode__c;
            } else {
                actCde = orgDef.actcode__c;
            }
            if (usrSett.BadgeId__c != null){
                bdgId = usrSett.BadgeId__c;
            } else {
                bdgId = orgDef.BadgeId__c;
            }
        } else {
            endPnt = orgDef.End_Point__c;
            apiKey = orgDef.apiKey__c;
            actCde = orgDef.actcode__c;
            bdgId = orgDef.BadgeId__c;
        }

        DescribeSObjectResult describeResult = eContacts__Queue_Item__c.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );
        String query =
            ' SELECT ' +
            String.join( fieldNames, ',' ) +
            ' FROM ' +
            describeResult.getName() +
            ' where id = :scnId';
        eContacts__Queue_Item__c  scnItm = Database.query( query ); 
        
        string ntes = scnItm.eContacts__Notes__c;
        scnItm.eContacts__Notes__c = ntes.right(ntes.length() - (ntes.indexOf('</a>') + 4)) + ', QR Code: ' + barcode ;
        
        barcode.replaceAll('/', '%2F');
        barcode.replaceAll(':', '%3A');
        
        Http httpProtocol = new Http();
        // Create HTTP request to send.
        HttpRequest request = new HttpRequest();
        // Set the endpoint URL.
        String endpoint = 
            endPnt + 
            '?apikey=' + apiKey + 
            '&actcode=' + actCde + 
            '&badgeid=' + bdgId + 
            '&barcode=' + barcode;
        
        request.setEndPoint(endpoint);
        // Set the HTTP verb to GET.
        request.setMethod('GET');
        // Send the HTTP request and get the response.
        // The response is in JSON format.
        string response;
        if (orgDef.Test_Mode__c == false){
            HttpResponse rspnse = httpProtocol.send(request);
            response = rspnse.getBody();
        } else {
            response = '{"Success":true,"Messages":[],"LeadInfo":{"LeadID":"26347572","CapturedDate":"4/16/2016 10:00:31 PM","CapturedBy":"Dev Kit 18610245","ConnectKey":"1001","FirstName":"DEMO_1001","LastName":"ATTENDEE_1001","Title":"","Company":"DEMOCOMPANY_1001","Company2":"","Address":"145861 N Market Street","Address2":"","Address3":"","City":"Frederick","StateCode":"MD","ZipCode":"21701","CountryCode":"United States","Email":"1001@experient-inc.com","Phone":"1234567890","PhoneExtension":"1111","Fax":"9876543210","Notes":""},"Demographics":[{"Key":"CATEGORY","Description":"Category/Classification","Value":"Educator"},{"Key":"SPECIALTY","Description":"Specialty","Value":"General"},{"Key":"ADDTYPECODE","Description":"ADDRESS TYPE","Value":""}]}';
        }
        
        JSONParser parser = JSON.createParser(response);
        response res = (response)parser.readValueAs(response.class);

        scnItm.eContacts__First_Name__c = res.LeadInfo.FirstName;
        scnItm.eContacts__Last_Name__c = res.LeadInfo.LastName;
        scnItm.eContacts__Title__c = res.LeadInfo.Title;
        scnItm.eContacts__Company__c = res.LeadInfo.Company;

        string addStr = res.LeadInfo.Address;
        if (res.LeadInfo.Address2 != null && res.LeadInfo.Address2 != ''){
            addStr = addStr + ', ' + res.LeadInfo.Address2;
        }
        if (res.LeadInfo.Address3 != null && res.LeadInfo.Address3 != ''){
            addStr = addStr + ', ' + res.LeadInfo.Address3;
        }
        
        if (addStr != null && addStr.length() > 0){
            scnItm.eContacts__Address_Street__c = addStr;
        } else{
            scnItm.eContacts__Address_Street__c = 'N/A';
        }
        if (res.LeadInfo.City != null && res.LeadInfo.City.length() > 0){
            scnItm.eContacts__Address_City__c = res.LeadInfo.City;
        } else{
            scnItm.eContacts__Address_City__c = 'N/A';
        }
        if (res.LeadInfo.StateCode != null && res.LeadInfo.StateCode.length() > 0){
            scnItm.eContacts__Address_State__c = res.LeadInfo.StateCode;
        } else{
            scnItm.eContacts__Address_State__c = 'N/A';
        }
        if (res.LeadInfo.ZipCode != null && res.LeadInfo.ZipCode.length() > 0){
            scnItm.eContacts__Address_Zip__c = res.LeadInfo.ZipCode;
        } else{
            scnItm.eContacts__Address_Zip__c = 'N/A';
        }
        if (res.LeadInfo.CountryCode != null && res.LeadInfo.CountryCode.length() > 0){
            scnItm.eContacts__Address_Country__c = res.LeadInfo.CountryCode;
        } else{
            scnItm.eContacts__Address_Country__c = 'N/A';
        }

        scnItm.eContacts__Email__c = res.LeadInfo.Email;
        scnItm.eContacts__Phone_Fax__c = res.LeadInfo.Fax;

        string phn = res.LeadInfo.Phone;
        if (res.LeadInfo.PhoneExtension != null && res.LeadInfo.PhoneExtension != ''){
            phn = phn + ' EXT' + res.LeadInfo.PhoneExtension;
        }
        scnItm.eContacts__Phone_Office__c = phn;
        scnItm.Badge_Id__c = res.LeadInfo.LeadID;

        string notes = scnitm.eContacts__Notes__c;
        notes = notes.substringBefore(', QR Code:');
        if (notes == null || notes == ''){
            notes = 'No Notes Entered';
        }

        for (Demographic dem : res.Demographics){
            notes = notes + ', ' + dem.Description + ': ' + dem.Value;
        }
        if (res.LeadInfo.Notes != null && res.LeadInfo.Notes != ''){
            notes = notes + ', API Notes: ' + res.LeadInfo.Notes;
        }
        scnItm.eContacts__Notes__c = notes.left(32768);

        scnItm.Lead_Source__c = 'Tradeshow';
        scnItm.API_Completed__c = true;
        update scnItm;
    }

    public class response {
        public boolean Success;
        public list<message> Messages;
        public LeadInfo LeadInfo;
        public list<Demographic> Demographics;

        public response(boolean wasSuccess, list<message> msgs, LeadInfo ldInfo, list<Demographic> dems){
            Success = wasSuccess;
            Messages = msgs;
            LeadInfo = ldInfo;
            Demographics = dems;
        }
    }

    public class message{
        public string MessageID;
        public string Message;
        public integer Severity;
    }

    public class LeadInfo {
        public string LeadID;
        public string CapturedDate;
        public string CapturedBy;
        public string ConnectKey;
        public string FirstName;
        public string LastName;
        public string Title;
        public string Company;
        public string Company2;
        public string Address;
        public string Address2;
        public string Address3;
        public string City;
        public string StateCode;
        public string ZipCode;
        public string CountryCode;
        public string Email;
        public string Phone;
        public string PhoneExtension;
        public string Fax;
        public string Notes;
    }

    public class Demographic {
        public string Key;
        public string Description;
        public string Value;
    }
}