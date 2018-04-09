@RestResource(urlMapping = '/getContent/*')
global with sharing class ContentService {

    @HttpGet
    global static void getContent()
    {
         String url = EncodingUtil.urlDecode(RestContext.request.params.get('url'), 'UTF-8');
         getContent(url);
    }
    
    @testVisible    
    static void getContent(String url)
    {
        PageReference pageRef = new PageReference(url);
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type','image/png');
        res.responseBody =  Test.IsRunningTest()? Blob.valueOf('UNIT.TEST') : pageRef.getContent();
    }    
}