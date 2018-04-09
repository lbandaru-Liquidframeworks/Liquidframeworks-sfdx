@isTest
private class QuoteHandler_Test
{
    static testmethod void InitQuoteSyncIdTrackingNumber_Test()
    {
        Test.startTest();
        Integer count = 200;
        List<Quote__c> quotes = AlpineTestHelper.CreateQuotes(count , true);
        Test.stopTest();
        List<Quote__c> dbItems = [SELECT Id, Tracking_Number__c, SyncID__c FROM Quote__c WHERE Tracking_Number__c!=null AND SyncID__c!=null];
        System.assert(dbitems.size() == count, 'Quote should have Tracking_Number__c, SyncID__c');
    }
    
    static testmethod void InitQuoteStatus_Test()
    {
        Test.startTest();
        Integer count = 200;
        
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c'); 

        String newGuid = StringUtility.newGuid(); 

        string statusName = 'Status ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Quote__c', Sync__c=true, Initial_Status_Console__c =true, Initial_Status_Mobile__c=true, RecordTypeId=statusRecordType.Id);
        insert st;
        
        List<Quote__c> quotes = AlpineTestHelper.CreateQuotes(count , true);
        Test.stopTest();
        List<Quote__c> dbItems = [SELECT Id, Tracking_Number__c, SyncID__c FROM Quote__c WHERE Status__c!=null];
        System.assert(dbitems.size() == count, 'Quote should have Status!=null');
    }
    
    static testmethod void CreateJobFromQuote_Test()
    {
        Test.startTest();
        Quote__c q = AlpineTestHelper.CreateQuotes(1, true).get(0);
        Job__c job = QuoteHandler.CreateJob(q.Id, true);
        Test.stopTest();
        Id quoteId = q.Id;
        String ns = StringUtility.FXNamespace();
        Set<String> quoteFields = Quote__c.sObjectType.getDescribe().fields.getMap().keySet();
        String qFieldsStr = String.join(new List<String>(quoteFields), ',');
        String soql = String.format('SELECT {1} FROM {0}Quote__c WHERE Id=:quoteId', 
            new String[]{ns, qFieldsStr});
        
        Quote__c dbQuote = (Quote__c)Database.query(soql);
        
        Id jobId = job.Id;            
        Set<String> jobFields = Job__c.sObjectType.getDescribe().fields.getMap().keySet();
        String jobFieldsStr = String.join(new List<String>(jobFields ), ',');
        String jobSoql = String.format('SELECT {1} FROM {0}Job__c WHERE Id=:jobId', 
            new String[]{ns, jobFieldsStr });
            
         Job__c dbJob = (Job__c)Database.query(jobSoql );

         Set<String> excludedFields = new Set<String>();
         String nsLowercase = ns.toLowercase();
         excludedFields.add(nsLowercase+'status__c');
         excludedFields.add(nsLowercase+'syncid__c');
         excludedFields.add(nsLowercase+'tracking_number__c');

         
         for(String f: quoteFields)
         {
             if(f.endsWith('__c') && jobFields.Contains(f) && !excludedFields.Contains(f))
             {
                 System.assert(String.valueOf(dbQuote.get(f)) == String.valueOf(dbJob.get(f)), f + ' value on Quote__c is not copied to Job');
             }
         }  
         
         System.assert(dbJob.Quote2__c == dbQuote.Id, 'Job should have Quote__c value');          
    }
    
    static testmethod void QuoteToJobController_HappyPath_Test()
    {
        Test.startTest();
        Quote__c q = AlpineTestHelper.CreateQuotes(1, true).get(0);  
        PageReference page = new PageReference('QuoteToJobV2');
        Test.setCurrentPage(page);                
        
        QuoteToJobController ctrl = new QuoteToJobController(new ApexPages.StandardController(q));   
               
        ctrl.redirect();
        
       
        
        Test.stopTest();
        
         List<Job__c> jobs = [SELECT Id FROM Job__c WHERE Quote2__c =:q.Id];
        
        System.assert(jobs.size()==1, 'should have a Job with Quote__c');
        
    }
    
    static testmethod void QuoteToJobController_SadPath_Test()
    {
        Test.startTest();
        Quote__c q = AlpineTestHelper.CreateQuotes(1, true).get(0);  
        PageReference page = new PageReference('QuoteToJobV2');
        Test.setCurrentPage(page);         
        QuoteToJobController ctrl = new QuoteToJobController(new ApexPages.StandardController(q));   
        Job__c job = QuoteHandler.CreateJob(q.Id, false);
        job.Price_Book__c = null;
        ctrl.redirectInternal(job);        
        Test.stopTest();
        
        
         List<Job__c> jobs = [SELECT Id FROM Job__c WHERE Quote2__c =:q.Id];
        
        System.assert(jobs.size()==0, 'should NOT have a Job with Quote__c');
        
    }
    
    
}