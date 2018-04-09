@isTest
private class FieldSetSvcTests {
    static testMethod void runTest() 
    { 
        // set up the request object
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
            
        req.requestURI = '/getFieldSets';
        req.httpMethod = 'GET';

        string namespace = UtilityGetNamespace.CurrentNamespace();
        req.addParameter('sObjectType', namespace + 'Ticket_Item__c');
        
        RestContext.request = req;
        RestContext.response = res;
        
        LIST<FieldSetSvc.FieldSetData> results = FieldSetSvc.getFieldSets();
    }
}