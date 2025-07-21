global class WorkatoMock implements HttpCalloutMock {
	global HTTPResponse respond(HTTPRequest req){
        
        HttpResponse resp = new HttpResponse();
        
        if(req.getEndpoint().contains('/roomblocksurveyemail')) {
            resp.setBody('{"code": 200,"token": "test_token123","message": "Success"}');
        } else {
            resp.setBody('{"code": 400,"message": "Error"}');
        }
        
        return resp;
    }
}