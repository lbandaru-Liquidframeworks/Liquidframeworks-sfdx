@isTest
private class TicketItemInsertSvcTest{
   
    static testmethod void InsertTktItem()
    {
        Test.startTest();
    
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);   
        List<Crew_Planning__c> crew = AlpineTestHelper.CreateScheduledCrew(5, job, true);
        
        List<Id> sourceIds = new List<Id>();
        for(integer i = 0; i<5 ; i++){
            sourceIds.add(crew[i].Id);
        }      

        // set up the request object
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
            
        req.requestURI = '/getScheduledCrew';
        req.httpMethod = 'GET';

        req.addParameter('jobId', job.Id);
        req.addParameter('limit', '');
        req.addParameter('offset', '');
        req.addParameter('sortby', '');
        req.addParameter('sortdir', '');
        req.addParameter('fields', 'Id');
        
        RestContext.request = req;
        RestContext.response = res;
        
        List<Ticket_Item__c> items = TicketItemInsertSvc.InsertTktItem(tkt.Id, sourceIds, 0);
        System.assert(items.size() == 5);
    }
}