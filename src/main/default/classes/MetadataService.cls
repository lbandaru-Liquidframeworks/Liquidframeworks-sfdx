public class MetadataService
{
    public static LayoutDescribe.RecordTypeLayout getLayout(String obj, String recordTypeId)
    {
        String endPoint = String.format('{0}/services/data/v33.0/sobjects/{1}/describe/layouts/{2}',
                new String[]{URL.getSalesforceBaseUrl().toExternalForm(), obj, recordTypeId});
        String rawStr = getRowResponse(endPoint);
        return (LayoutDescribe.RecordTypeLayout)JSON.deserialize(rawStr, LayoutDescribe.RecordTypeLayout.class);
    }

    public static String getRowResponse(String endPoint)
    {
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');  
        req.setEndpoint(endPoint);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse res = null;
        if(Test.isRunningTest())
        {
                // Create a fake response
            res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"Id" : "03d360000002t7DAAQ","ValidationName" : "Single_Assignment","LastModifiedDate" : "2016-05-02T18:34:47.000+0000","Metadata" : {"errorConditionFormula" : "1=1","errorDisplayField" : null,"errorMessage" : "You may only select one location value. Please clear the other value."},"FullName" : "Crew_Planning__c.Single_Assignment"}');
                res.setStatusCode(200);
        }
        else
        {
            res = h.send(req); 
        }
        return res.getBody();
    }

	public static String getLayouts(String sobj)
	{
		String apiUrlRoot = URL.getSalesforceBaseUrl().toExternalForm();
		HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');

        String endPoint = String.format('{0}/services/data/v33.0/sobjects/{1}/describe/layouts',
                new String[]{apiUrlRoot, sobj});

        req.setEndpoint(endPoint);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse res = null;
        if(Test.isRunningTest())
        {
                // Create a fake response
            res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"Id" : "03d360000002t7DAAQ","ValidationName" : "Single_Assignment","LastModifiedDate" : "2016-05-02T18:34:47.000+0000","Metadata" : {"errorConditionFormula" : "1=1","errorDisplayField" : null,"errorMessage" : "You may only select one location value. Please clear the other value."},"FullName" : "Crew_Planning__c.Single_Assignment"}');
                res.setStatusCode(200);
        }
        else
        {
            res = h.send(req); 
        }

        LayoutDescribe  o = (LayoutDescribe)JSON.deserialize(res.getBody(),
        	LayoutDescribe.class);
        return JSON.serializePretty(o);              
	}
}