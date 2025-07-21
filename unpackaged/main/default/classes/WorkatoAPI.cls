public class WorkatoAPI {
    
    @TestVisible private String token = 'abc';
    public class WorkatoAPIException extends Exception {}
    

    public WorkatoAPI() {
        final String logTag = 'WorkatoAPI::constructor';

        if(String.isBlank(this.token)) {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:WorkatoDev/oauth2/token');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            //req.setHeader('grant_type', 'client_credentials');
            req.setMethod('POST');
            req.setBody('grant_type=client_credentials&client_id=6bde5b3656e9139b1998b99c671ca40981659b7a56ffcd310eb21ccb0594325b&client_secret=53a0269d307bdbfbda66823c81b3c0de7c5c2929e0aeec5a77bd93e01d4d4986');
            //req.setBody('grant_type=client_credentials');

            
            System.debug('Request body: ' + req.toString());
            
            HttpResponse res = http.send(req);
            String respBody = res.getBody();
            System.debug('Workato auth response: ' + respBody);
            
            
            //"access_token"
            Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(respBody);  
            this.token = String.valueOf(resMap.get('access_token'));
            System.debug('Access token: ' + token);
			/*
            if(respBody.startsWith('\n<')) {
                //logResponse(null, respBody.stripHtmlTags(), logTag);
                throw new WorkatoAPIException(respBody.stripHtmlTags());
            } else {
                Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(respBody);            
                if((Integer) resMap.get('code') == 200) {
                    //if successful then save token
                    this.theToken = (String) resMap.get('token');
                } else {
                    //not successful. log response and throw exception
                    //logResponse(null, (String) resMap.get('message'), 'CZ::GenerateToken');
                    throw new WorkatoAPIException((String) resMap.get('message'));
                }
            }
			*/
        }
    }
    
    public void sendSurveyData(String surveyDataJSON){
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        //req.setEndpoint('callout:WorkatoDev/portal-sf-integration-v1/roomblocksurveyemail');
        //req.setEndpoint('callout:WorkatoDev/ncmd/mailgateway-v1/roomblocksurvey');
        //ConnectApi.NamedCredential nc = ConnectApi.NamedCredentials.getNamedCredential('WorkatoDev');
		//System.debug('WorkatoDev url: ' + nc.calloutUrl);
		req.setEndpoint('callout:WorkatoDev' + System.Label.WorkatoRoomBlockSurvey); 
        req.setHeader('token', this.token);
        req.setHeader('Accept', 'application/json');
        req.setMethod('POST');
        req.setBody(surveyDataJSON);
        System.debug('Workato API endpoint: ' + req.toString());
        
                
        HttpResponse res = http.send(req);
        System.debug('WorkatoAPI.sendSurveyData response:' + res.getBody()); //JSON.deserialize(res.getBody(), PaymentModel.CZCreateCustomerResponse.class);
        
    }
}