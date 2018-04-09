@isTest
private class SyncAssignment_Quote_Test {

	static testmethod void UpdateJobsStatus_NoSync_Test()
    {
    	Contact user= AlpineTestHelper.CreateUser('Doe', 'Jane', true);
    	System.debug('user=' + user.Id);
      
        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = user.Id, Sync_JobCrewOnly__c=true, Account__c=null, Office__c=null, Job_Type__c=null, Segment__c=null);
        insert sc;

		Test.StartTest();

		Job__c job = AlpineTestHelper.CreateJobs(1, false).get(0);
		job.Category__c = 'Deal';
		insert job;


		Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, false).get(0);
		tkt.Category__c = 'Quote';
		insert tkt;

		Job__c s = [SELECT Name, Price_Book__c, Office__c, CustomerAccount__c, Segment__c, RecordTypeId, Sync__c FROM Job__c where Id =:job.Id LIMIT 1];

		System.assert(s.Sync__c);

        Job__c jobFromQuote = new Job__c(Name = s.Name, Price_Book__c = s.Price_Book__c,
        	Office__c = s.Office__c, CustomerAccount__c = s.CustomerAccount__c, 
        	RecordTypeId = s.RecordTypeId, Category__c = 'Job');
        if(QuoteExtension.HasQuoteV1 == true)
        {
            jobFromQuote.put(QuoteExtension.QuoteV1FieldName, tkt.Id);
        }

        insert jobFromQuote;

       	Crew_Planning__c cp =  new Crew_Planning__c(Job__c=jobFromQuote.Id, Crew_Member__c=user.Id);
       	insert cp;

		Test.StopTest();

		//List<Sync_Assignment__c> items = [SELECT Id FROM Sync_Assignment__c WHERE Contact__c=:user.Id];
		//System.assertEquals(2, items.size());
	}

}