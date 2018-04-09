public class StaticResourceHandler
{
    
    public static String UpsertFile(String resourceName, String contentStr)
    {
        if(contentStr == null)
        {
            contentStr = '';            
        }
        String contents = EncodingUtil.base64Encode(Blob.valueof(contentStr));
        Boolean isUpdate = true;
        Boolean hasNoChange = false;
               
        List<StaticResource> items = [SELECT Id, Body FROM StaticResource WHERE Name=:resourceName];
        String apiUrlRoot = URL.getSalesforceBaseUrl().toExternalForm();
        String endPoint = '';
        if(items.isEmpty())
        {
            hasNoChange = false;
            isUpdate = false;
            endPoint = apiUrlRoot + '/services/data/v29.0/tooling/sobjects/StaticResource';
        }
        else
        {
            endPoint = apiUrlRoot + '/services/data/v29.0/tooling/sobjects/StaticResource/' + items.get(0).Id 
                + '?_HttpMethod=PATCH';
            Integer oldHashCode = items.get(0).Body.toString().hashCode();
            Integer newHashCode = contentStr.hashCode();
            //System.debug(oldHashCode + ' vs ' + newHashCode);
            hasNoChange = oldHashCode == newHashCode;
        }       
        String msg = '';
        if(!hasNoChange)
        {           
            if(isUpdate) //backup 
            {
                String dtStr = String.valueOf(Datetime.now()).replace(' ', '_').replace('-', '').replace(':', '');
                String backupFileName = resourceName + dtStr;
                String newFileEndPoint =  apiUrlRoot + '/services/data/v29.0/tooling/sobjects/StaticResource' ;
                String fileContents = EncodingUtil.base64Encode(items.get(0).Body);
                HttpResponse res2 = SaveStaticResource(newFileEndPoint, backupFileName, 
                    fileContents, 'text/plain');                                                          
                System.debug(res2);
                msg = 'Backup entry ' + backupFileName + ' is created. ';
            }
            HttpResponse res = SaveStaticResource(endPoint, resourceName, contents, 'text/plain');
            msg += 'Status: ' + res.getStatus() + ', Response:' + res.getBody();
        }
        else
        {
            msg = 'No change for ' + resourceName;
        }
        return msg;
    }

    static HttpResponse SaveStaticResource(String endPoint, 
        String resourceName, String contents, 
        String contentType)
    {
        HttpResponse res = null;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json'); 
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

        req.setBody(
                '{"Name":"'+resourceName+'"'+
                ',"ContentType":"'+contentType+'"'+
                ',"Body":"'+contents+'"'+
                ',"CacheControl":"Private"}'
                );

        Http http = new Http();

        if(!Test.isRunningTest())
        {
            res = http.send(req);            
        }
        else
        {
            res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"foo":"bar"}');
            res.setStatusCode(200);
        }
        return res;
       
    }
}