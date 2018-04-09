@isTest
private class VerifySessionSvcTest{
   
    static testmethod void Ping(){
        Test.startTest();
        
        // set up the request object
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
            
        req.requestURI = '/ping';
        req.httpMethod = 'GET';

        string namespace = '';
        req.addParameter('namespace', namespace);
        
        RestContext.request = req;
        RestContext.response = res;
        
        VerifySessionSvc.Result results = VerifySessionSvc.ping();
        
        System.assert(results.Status == 'BAD SESSION ID');

        namespace = '_DEV_';
        req.addParameter('namespace', namespace);
        
        RestContext.request = req;
        RestContext.response = res;
        
        results = VerifySessionSvc.ping();
        
        System.assert(results.Status == 'OK');

        namespace = 'FAKE';
        req.addParameter('namespace', namespace);
        
        RestContext.request = req;
        RestContext.response = res;
        
        results = VerifySessionSvc.ping();
        System.assert(results.Status == 'BAD SESSION ID');

        Test.stopTest();
    }
}