@isTest
private class ContentService_Test
{
    static testmethod void getContent_Test()
    {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/getContent';
        
        String pageUrl  = URL.getSalesforceBaseUrl().toExternalForm();
        req.addParameter('url', pageUrl);
        
        RestContext.request = req;
        RestContext.response = res;
        
        ContentService.getContent();
        
        System.debug(res);
        
    }
}