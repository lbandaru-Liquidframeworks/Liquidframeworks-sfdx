@isTest
private class QuoteItemsSvcTest{
   
    static testmethod void GetItems(){
        Test.startTest();
    
       Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
       insert catalogItem;
              
        RecordType rtJob = AlpineTestHelper.GetRecordType('Job__c');

        Status__c oldStatus = new Status__c(Name = 'Old Status', SObject__c = 'Job__c', SObject_Record_Type__c = rtJob.DeveloperName);
        insert oldStatus;
        
        Status__c newStatus = new Status__c(Name = 'New Status', SObject__c = 'Job__c', SObject_Record_Type__c = rtJob.DeveloperName);
        insert newStatus;

        Status_Workflow__c workflow = new Status_Workflow__c(SObject__c = 'Job__c', SObject_Record_Type__c = rtJob.DeveloperName, New_Status__c = newStatus.Id, Old_Status__c = oldStatus.id);
        insert workflow;   

        Job__c j = AlpineTestHelper.CreateJobs(1, false).get(0);
        
        j.RecordTypeId = rtJob.Id;
        j.Status__c = oldStatus.Id;
        j.Category__c = 'Deal';

        insert j;

        Ticket__c tkt = AlpineTestHelper.CreateTickets(j, 1, false).get(0);
        tkt.Category__c = 'Quote';

        insert tkt;

           Price_Book_Item__c pli = new Price_Book_Item__c(Price_Book__c = j.Price_Book__c, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
           insert pli;

      Ticket_Item__c tktItem  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pli.Id);
       
       insert tktItem;    

        
        QuoteExtension extension = new QuoteExtension(tkt.Id, tkt);
        extension.getForm();

        string jobObjectType = UtilityGetNamespace.CurrentNamespace()  + 'Job__c';
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType WHERE SObjectType =: jobObjectType AND IsActive=true]; // AND Id != :rtJob.Id];

        string newJobRecordType = recordTypes.get(0).Id;
        extension.HiddenTextValue = newJobRecordType;
        extension.convertToJob();

        List<Job__c> jobs = [SELECT Name, Price_Book__c, Office__c, CustomerAccount__c, RecordTypeId FROM Job__c WHERE Id !=:j.Id];

        if(jobs.size()==1)
        {
            Job__c j2 = jobs.get(0);

            Ticket__c t= new Ticket__c(Job__c = j2.Id);
            insert t;

            // set up the request object
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
                
            req.requestURI = '/getQuoteItems';
            req.httpMethod = 'GET';

            req.addParameter('jobId', j2.Id);
            req.addParameter('ticketId', t.Id);
            req.addParameter('limit', '');
            req.addParameter('offset', '');
            req.addParameter('sortby', '');
            req.addParameter('sortdir', '');
            
            RestContext.request = req;
            RestContext.response = res;
            
            QuoteItemsSvc.Result result = QuoteItemsSvc.getQuoteItems();
            
            System.assert(result.items.size() > 0);

        }

    }
}