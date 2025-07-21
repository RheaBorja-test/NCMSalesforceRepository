@RestResource(urlMapping='/Engagements/*')
global with sharing class EngagementService {
    
    @HttpGet
    global static EngagementModel.EngagementResponse getEngagementsByGroupNumber() {
        
        // Prepare the response
        EngagementModel.EngagementResponse resp = new EngagementModel.EngagementResponse();
        
        // Parse the group account number
        RestRequest request = RestContext.request;
        String groupNumber = request.requestURI.substring(request.requestURI.lastIndexOf('/')+1);
        System.debug('Group Number: ' + groupNumber);

        if( String.isNotBlank(groupNumber) ){
            groupNumber = String.escapeSingleQuotes(groupNumber); // SOQL Injection Attack protection.

            List<Engagement__c> engagementResults = [SELECT 
                                                        Engagements_Checklist__c,
                                                        Engagement_End_Date__c,
                                                        Engagement_Start_Date__c,
                                                        City__c,
                                                        Confirmed_Hotel__r.Name, 
                                                        Confirmed_Hotel__r.ShippingStreet, 
                                                        Confirmed_Hotel__r.ShippingCity,
                                                        Confirmed_Hotel__r.ShippingState,
                                                        Confirmed_Hotel__r.ShippingStateCode,
                                                        Confirmed_Hotel__r.ShippingPostalCode,
                                                        Confirmed_Hotel__r.ShippingCountryCode,
                                                        Confirmed_Hotel__r.Phone, 
                                                        Confirmed_Hotel__r.Fax, 
                                                        Confirmed_Hotel__r.Website,
                                                        Reception_Date__c, 
                                                        State__c,
                                                        Status__c,
                                                        X20_Group__c,
                                                        X20_Group__r.Name,
                                                        X20_Group__r.Meeting_Support_Contact__r.Email,
                                                        X20_Group__r.Meeting_Support_Contact__r.Name,
                                                        Proprietary_Group__c,
                                                        Proprietary_Group__r.Name,
                                                        Proprietary_Group__r.Meeting_Support_Contact__r.Email,
                                                        Proprietary_Group__r.Meeting_Support_Contact__r.Name, 
                                                        X20_Group__r.NCM_Support_Staff__r.Email, 
                                                        X20_Group__r.NCM_Support_Staff__r.Name,  
                                                        X20_Group__r.NCM_Proprietor__r.Email, 
                                                        X20_Group__r.NCM_Proprietor__r.Name, 
                                                        Proprietary_Group__r.Support_Staff__r.Name,
                                                        Proprietary_Group__r.Support_Staff__r.Email,
                                                        Proprietary_Group__r.Group_Owner__r.Name,
                                                        Proprietary_Group__r.Group_Owner__r.Email,
                                                        Room_Block_Cut_off__c
                                                    FROM Engagement__c
                                                    WHERE (X20_Group__r.Name = :groupNumber OR Proprietary_Group__r.Group_Number__c = :groupNumber)
                                                        AND Engagement_End_Date__c >= TODAY
                                                        AND Status__c IN ('Firm','Tentative')
                                                    ORDER BY Engagement_Start_Date__c // This Order By is being used for the Next Meeting Info. Do not change. 
                                                    ];



            if(engagementResults.isEmpty()){
                resp.status = 'Error';
                resp.statusCode = '500';
                resp.message = 'No Engagement results found for group number ' + groupNumber;
            } else {
                resp.status = 'Success';
                resp.statusCode = '200';
                resp.message = engagementResults.size() + ' Engagement results found for group number ' + groupNumber;
                resp.groupNumber = groupNumber;
                resp.moderatorName = engagementResults[0].X20_Group__c != null ? engagementResults[0].X20_Group__r.NCM_Proprietor__r.Name : engagementResults[0].Proprietary_Group__r.Group_Owner__r.Name;
                resp.moderatorEmail = engagementResults[0].X20_Group__c != null ? engagementResults[0].X20_Group__r.NCM_Proprietor__r.Email : engagementResults[0].Proprietary_Group__r.Group_Owner__r.Email;
                resp.clientSupportName = engagementResults[0].X20_Group__c != null ? engagementResults[0].X20_Group__r.NCM_Support_Staff__r.Name : engagementResults[0].Proprietary_Group__r.Support_Staff__r.Name;
                resp.clientSupportEmail = engagementResults[0].X20_Group__c != null ? engagementResults[0].X20_Group__r.NCM_Support_Staff__r.Email : engagementResults[0].Proprietary_Group__r.Support_Staff__r.Email;
                resp.meetingSupportContactName = engagementResults[0].X20_Group__c != null ? engagementResults[0].X20_Group__r.Meeting_Support_Contact__r.Name : engagementResults[0].Proprietary_Group__r.Meeting_Support_Contact__r.Name;
                resp.meetingSupportContactEmail = engagementResults[0].X20_Group__c != null ? engagementResults[0].X20_Group__r.Meeting_Support_Contact__r.Email : engagementResults[0].Proprietary_Group__r.Meeting_Support_Contact__r.Email; 

                // Next Meeting Info. SALES-1614
                Date nextDate = null;
                String nextLocation = null;
                Date nextReservationDate = null;
                for( Engagement__c engagement :engagementResults) {  
                    if(engagement.Engagement_Start_Date__c > Date.Today()) {
                        nextDate = engagement.Engagement_Start_Date__c;
                        nextLocation = engagement.Confirmed_Hotel__r.Name;
                        nextReservationDate = engagement.Room_Block_Cut_off__c;
                        break;    
                    }
                }
                resp.nextMeetingDate = nextDate;
                resp.nextMeetingLocation = nextLocation;
                resp.nextHotelReservationDue = nextReservationDate;

                List<EngagementModel.Engagement> engagementList = new List<EngagementModel.Engagement>();
                for(Engagement__c eng:engagementResults){

                    String city = eng.Confirmed_Hotel__r.ShippingCity == null ? eng.City__c : eng.Confirmed_Hotel__r.ShippingCity;
                    String state = eng.Confirmed_Hotel__r.ShippingStateCode == null ? eng.State__c : eng.Confirmed_Hotel__r.ShippingStateCode;

                    EngagementModel.Engagement engModel = new EngagementModel.Engagement();
                    engModel.engagementId = eng.Id;
                    engModel.startDate = eng.Engagement_Start_Date__c;
                    engModel.endDate = eng.Engagement_End_Date__c;
                    engModel.receptionDate = eng.Reception_Date__c != null ? date.newinstance(eng.Reception_Date__c.year(), eng.Reception_Date__c.month(), eng.Reception_Date__c.day()) : null;
                    engModel.status = eng.Status__c;
                    engModel.checklistId = eng.Engagements_Checklist__c;
                    engModel.confirmedHotel = eng.Confirmed_Hotel__r.Name;
                    engModel.hotelPhone = eng.Confirmed_Hotel__r.Phone;
                    engModel.hotelFax = eng.Confirmed_Hotel__r.Fax;
                    engModel.hotelWebsite = eng.Confirmed_Hotel__r.Website;
                    engModel.hotelStreet = eng.Confirmed_Hotel__r.ShippingStreet; 
                    engModel.hotelCity = city;// eng.Confirmed_Hotel__r.ShippingCity;
                    engModel.hotelState = state; //eng.Confirmed_Hotel__r.ShippingStateCode;
                    engModel.hotelZipCode = eng.Confirmed_Hotel__r.ShippingPostalCode;
                    engModel.hotelCountry = eng.Confirmed_Hotel__r.ShippingCountryCode;
                    engagementList.add(engModel);
                }                      
                resp.engagements = engagementList;
            }

        } else {
            resp.status = 'Error';
            resp.statusCode = '500';
            resp.message = 'Missing parameter: groupNumber.';
        }

        return resp;
    }

    

    private static String getHotelAddress(Account hotelAccount){
        if(hotelAccount != null){
            return hotelAccount.ShippingStreet + ', ' + hotelAccount.ShippingCity + ', ' + hotelAccount.ShippingState + ' ' + hotelAccount.ShippingPostalCode + ' ' + hotelAccount.ShippingCountry;
        } else {
            return '';
        }
    }
    
}