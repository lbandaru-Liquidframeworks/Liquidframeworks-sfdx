@isTest
private class ScheduledEquipmentSvcTest{
   
    static testmethod void GetItems()
    {
        Test.startTest();
    
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        List<Equipment_Planning__c> pbItems = AlpineTestHelper.CreateScheduledEquipment(5, job, true);   

        // set up the request object
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
            
        req.requestURI = '/getScheduledEquipment';
        req.httpMethod = 'GET';

        req.addParameter('jobId', job.Id);
        req.addParameter('limit', '');
        req.addParameter('offset', '');
        req.addParameter('sortby', '');
        req.addParameter('sortdir', '');
        req.addParameter('fields', 'Id');
        
        RestContext.request = req;
        RestContext.response = res;
        
        ScheduledEquipmentSvc.Result result = ScheduledEquipmentSvc.getScheduledEquipment();
        
        System.assert(result.items.size() == 5);

    }
}