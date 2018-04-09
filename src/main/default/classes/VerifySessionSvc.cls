@RestResource(urlMapping = '/ping/*')
global with sharing class VerifySessionSvc{
    //
    @HttpGet
    global static Result ping() {
        Result result = new Result();
        String namespace = RestContext.request.params.get('namespace');
        namespace = namespace.trim();
        if (namespace == '_DEV_') {
            result.Status = 'OK';
            return result;
        }
        if (namespace != '') {
            boolean isCurrentUserLicensed = false;
            try {
                isCurrentUserLicensed = UserInfo.isCurrentUserLicensed(namespace);
            } catch (System.TypeException ex) {
                isCurrentUserLicensed = false;
            }
            
            if (isCurrentUserLicensed) {
                result.Status = 'OK';
                return result;
            }
        }
        
        RestResponse res = RestContext.response;
        res.statusCode = 403;
        String jsonResponse = '{"response": {"status": "Failure", "message": "Invalid Namespace"}}';
        res.responseBody = blob.valueOf(jsonResponse);

        result.Status = 'BAD SESSION ID';
        return result;
    }
    
    global class Result {
        public string Status;
    }
}