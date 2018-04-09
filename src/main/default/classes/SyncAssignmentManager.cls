public class SyncAssignmentManager
{
	static Map<string, Id> JobTypePickListToRecordType = null;

	public static void RefreshSyncAssignments(Set<Id> users)
	{
		List<Sync_Configuration__c> configs = [SELECT Id, Contact__c, Contact__r.User__c, Account__c, Job_Type__c, Office__c, Segment__c, Sync_JobCrewOnly__c 
		FROM Sync_Configuration__c WHERE IsDeleted=false AND Contact__c IN :users AND Contact__r.User__c!=null AND Contact__r.User__r.IsActive=true];
		if(!configs.isEmpty())
		{
			UpdateSyncAssignments(configs);
		}
	}
	
	public static void UpdateJobSyncFlag(List<Job__c> jobs)
	{		
        Set<Id> accountIds = new Set<Id>();
        Set<Id> pbIds = new Set<Id>();
        for(Job__c job: jobs)
        {
            accountIds.add(job.CustomerAccount__c);
            pbIds.add(job.Price_Book__c);
        }
		Map<Id, Status__c> statusItems = new  Map<Id, Status__c>([SELECT Sync__c FROM Status__c WHERE SObject__c='Job__c']);
        Map<Id, Price_Book__c> pbMap = new  Map<Id, Price_Book__c>([SELECT Id, Is_Active__c FROM Price_Book__c WHERE Is_Active__c=false AND Id IN :pbIds]);
        Map<Id, Account> acctMap = new  Map<Id, Account>([SELECT Id FROM Account WHERE IsArchived__c=true AND Id IN :accountIds]);
		for(Job__c job: jobs)
		{
            if(pbMap.containsKey(job.Price_Book__c) || acctMap.containsKey(job.CustomerAccount__c))
			{
				job.Sync__c = false;
			}
			else if(job.Status__c!=null && statusItems.containsKey(job.Status__c)) 
			{
				job.Sync__c = statusItems.get(job.Status__c).Sync__c;		
			}
		}
	}
	
	public static void UpdateTicketSyncFlag(List<Ticket__c> tkts)
	{		
		Map<Id, Status__c> statusItems = new  Map<Id, Status__c>([SELECT Sync__c FROM Status__c WHERE SObject__c='Ticket__c']);
		for(Ticket__c t: tkts)
		{
			if(t.Status__c!=null && statusItems.containsKey(t.Status__c)) t.Sync__c = statusItems.get(t.Status__c).Sync__c;	
		}
	}

	public static Map<string, Id> GetJobTypePickListToRecordType()
	{
		if(JobTypePickListToRecordType==null)
		{
			JobTypePickListToRecordType = new  Map<string, Id>();
			string objType = UtilityGetNamespace.CurrentNamespace() + 'Job__c';

			for(RecordType rt : [SELECT Id, DeveloperName FROM RecordType where IsActive=true AND  SObjectType=:objType])
			{
				JobTypePickListToRecordType.put(rt.DeveloperName, rt.Id);
			}
		}		
		return JobTypePickListToRecordType;
	}

	public static void UpdateSyncAssignmentsOnCrewDelete(List<Crew_Planning__c> jobCrewRemoved)
	{
		if(jobCrewRemoved.isEmpty()) return;
		Set<Id> users = new Set<Id>();
		Set<Id> jobIDs = new Set<Id>();
		Set<Id> crewPlanningIds = new Set<Id>();
		
		Set<string> jobUserKeys = new Set<string>();
		for(Crew_Planning__c jw: jobCrewRemoved)
		{
			jobUserKeys.add(string.valueOf(jw.Job__c) + jw.Crew_Member__c);	
			crewPlanningIds.add(jw.Id);	
			users.add(jw.Crew_Member__c);	
		}		

		List<Sync_Configuration__c> jobCrewConfigs = [SELECT Id, Contact__c, Contact__r.User__c FROM Sync_Configuration__c 
		WHERE Sync_JobCrewOnly__c=true AND Contact__c IN :users AND Contact__r.User__c!=null AND Contact__r.User__r.IsActive=true];		
		if(jobCrewConfigs.isEmpty()) return;

		List<Sync_Assignment__c> syncAssignments = [SELECT Contact__c, Job__c FROM Sync_Assignment__c WHERE Sync_Assignment_ID__c IN :jobUserKeys];
		if(syncAssignments.isEmpty()) return;
		for(Sync_Assignment__c sa : syncAssignments)
		{
			users.add(sa.Contact__c);
			jobIDs.add(sa.Job__c);
		}		

		delete syncAssignments;		

		String quoteStr = (QuoteExtension.HasQuoteV1 == true)? ','+ QuoteExtension.QuoteV1FieldName : '';

		String jobSoql = String.format('SELECT Id, {0}CustomerAccount__c, {0}Office__c, {0}Segment__c, RecordType.DeveloperName, RecordTypeId {1} FROM {0}Job__c WHERE {0}Sync__c = true AND Id IN :jobIDs',
				new String[]{StringUtility.FXNamespace(), quoteStr});
		
		List<Job__c> jobs = (List<Job__c>)Database.query(jobSoql);	

		List<Crew_Planning__c> jobCrews = [SELECT Crew_Member__c, Job__c FROM Crew_Planning__c WHERE Id NOT IN :crewPlanningIds AND Crew_Member__c IN :users AND Job__c in :jobIDs];
		List<Sync_Configuration__c> syncConfigs = [SELECT Id, Contact__c, Contact__r.User__c, Account__c, Job_Type__c, Office__c, Segment__c, Sync_JobCrewOnly__c 
		FROM Sync_Configuration__c WHERE Contact__c IN :users AND Contact__r.User__c!=null AND Contact__r.User__r.IsActive=true];

		CreateSyncAssignments(jobs, syncConfigs, jobCrews);
	}

	public static void UpdateSyncAssignmentsOnCrewAdd(List<Crew_Planning__c> jobCrewAdded)
	{		
		if(jobCrewAdded.isEmpty()) return;

		Set<Id> users = new Set<Id>();
		Set<Id> jobIDs = new Set<Id>();		

		for(Crew_Planning__c jw: jobCrewAdded)
		{
			users.add(jw.Crew_Member__c);
			jobIDs.add(jw.Job__c);
		}

		List<Sync_Configuration__c> syncConfigs = [SELECT Id, Contact__c, Contact__r.User__c, Account__c, Job_Type__c, Office__c, 
		Segment__c, Sync_JobCrewOnly__c FROM Sync_Configuration__c WHERE Sync_JobCrewOnly__c=true AND Contact__c IN :users AND Contact__r.User__c!=null AND Contact__r.User__r.IsActive=true];

		if(syncConfigs.isEmpty()) return;

		
		String quoteFieldStr = (QuoteExtension.HasQuoteV1 == true)? (',' + QuoteExtension.QuoteV1FieldName) : '';
		String soql = String.format('SELECT Id, {0}CustomerAccount__c, {0}Office__c, {0}Segment__c, RecordType.DeveloperName, RecordTypeId {1} FROM {0}Job__c WHERE {0}Sync__c = true AND Id IN :jobIDs',
			new String[]{StringUtility.FXNamespace(), quoteFieldStr});

		List<Job__c> jobs = (List<Job__c>)Database.query(soql);
		CreateSyncAssignments(jobs, syncConfigs, jobCrewAdded);
	}

	public static void UpdateSyncAssignments(List<Sync_Configuration__c> configs)
	{
		List<Sync_Configuration__c> jobCrewConfigs = new List<Sync_Configuration__c>();
		List<Sync_Configuration__c> nonJobCrewConfigs = new List<Sync_Configuration__c>();

		Map<string, Id> jobTypeMap = GetJobTypePickListToRecordType();

		for(Sync_Configuration__c sc: configs)
		{			
			if((sc.Account__c == null && sc.Job_Type__c==null && sc.Office__c==null && sc.Segment__c==null&& !sc.Sync_JobCrewOnly__c)
				||(sc.Job_Type__c!=null && sc.Job_Type__c!='' && !jobTypeMap.containsKey(sc.Job_Type__c))) 
			{				
				continue;
			}

			if(sc.Sync_JobCrewOnly__c) 
			{
				jobCrewConfigs.add(sc);
			}
			else nonJobCrewConfigs.add(sc);
		}
		

		if(!jobCrewConfigs.isEmpty())
		{
			SyncAssignmentBatchable jobCrewBatch = new SyncAssignmentBatchable(jobCrewConfigs, jobTypeMap, true);
			Database.executeBatch(jobCrewBatch);
		}

		if(!nonJobCrewConfigs.isEmpty())
		{			
			SyncAssignmentBatchable nonJobCrewBatch = new SyncAssignmentBatchable(nonJobCrewConfigs, jobTypeMap, false);
			Database.executeBatch(nonJobCrewBatch);
		}		
	}
		
	public static void DeleteSyncAssignment(Set<Id> jobIds, Set<Id> quotes)
	{
		if(!quotes.isEmpty())
		{	
			for(Ticket__c t : [SELECT Id, Job__c FROM Ticket__c WHERE Id IN :quotes])		
			{
				jobIds.add(t.Job__c);
			}			
		}
		if(!jobIds.isEmpty())
		{
			delete [SELECT Id FROM Sync_Assignment__c WHERE Job__c IN :jobIds];
		}
	}
	
	public static void CreateSyncAssignments(List<Job__c> jobs, List<Sync_Configuration__c>  configs, List<Crew_Planning__c> jobCrews)
	{		
	

		if(jobs.isEmpty() || configs.isEmpty()) return;		

		Set<Id> users = new Set<Id>();
		List<Sync_Assignment__c> newAssignments = new List<Sync_Assignment__c>();

		Set<string> jobCrewKey = new Set<string>();
		for(Crew_Planning__c cp: jobCrews)
		{
			jobCrewKey.add(string.valueOf(cp.Crew_Member__c) + cp.Job__c);
		}
		
		Map<string, Id> jobTypeMap = GetJobTypePickListToRecordType();	
		Set<Id> quotes = new Set<Id>();
		Map<Id, List<Id>> quoteSubscriber = new Map<Id, List<Id>>();
		for(Sync_Configuration__c sc: configs)
		{
			if(sc.Contact__r.User__c != null) users.add(sc.Contact__r.User__c);
			if(sc.Job_Type__c !=null && sc.Job_Type__c!='' && !jobTypeMap.containsKey(sc.Job_Type__c)) continue;	
			Id jobTypeRecordType = (sc.Job_Type__c==null || sc.Job_Type__c=='')? null: jobTypeMap.get(sc.Job_Type__c);

			//System.debug('Sync_Configuration__c info:' + sc);

			for(Job__c job: jobs)
			{					
				string saUserJob= string.valueOf(sc.Contact__c) + job.Id;

				//System.debug('Job info:' + job);

				if((!sc.Sync_JobCrewOnly__c || jobCrewKey.contains(saUserJob))
						&& (sc.Account__c ==null || sc.Account__c == job.CustomerAccount__c )
						&& (jobTypeRecordType == null || jobTypeRecordType==job.RecordTypeId)
						&& (sc.Office__c == null || sc.Office__c==job.Office__c)
						&& (sc.Segment__c == null || sc.Segment__c==job.Segment__c))
				{
					newAssignments.add(new Sync_Assignment__c(Job__c = job.Id, Contact__c = sc.Contact__c));

					if(QuoteExtension.HasQuoteV1 == true)
					{
						Id quoteV1 = (Id)job.get(QuoteExtension.QuoteV1FieldName);
						if(sc.Sync_JobCrewOnly__c && !String.isBlank(quoteV1))
						{
							quotes.add(quoteV1);
							if(!quoteSubscriber.containsKey(quoteV1))
							{
								quoteSubscriber.put(quoteV1, new List<Id>());
							}
							quoteSubscriber.get(quoteV1).add(sc.Contact__c);
						}
					}
				}
			}
		}	
		if(!quotes.isEmpty())
		{
			for(Ticket__c t: [SELECT Id, Job__c FROM Ticket__c WHERE Id IN :quotes])
			{
				for(Id p : quoteSubscriber.get(t.Id))
				{
					newAssignments.add(new Sync_Assignment__c(Job__c = t.Job__c, Contact__c = p));
				}				
			}			
		}	
		if(!newAssignments.isEmpty())
		{
		    Database.insert(newAssignments, false);
		}
	}
	
	
	public static void UpdateSyncAssignments(List<SObject> jobs, List<Sync_Configuration__c> configs)
	{	
		Set<Id> jobIDs = new Map<Id, SObject>(jobs).keySet();
		Set<Id> contactIDs = new Set<Id>();
		for(Sync_Configuration__c sc : configs)
		{
			contactIDs.add(sc.Contact__c);
		}
		List<Crew_Planning__c> jobCrews = [SELECT Crew_Member__c, Job__c FROM Crew_Planning__c WHERE Crew_Member__c IN :contactIDs AND Job__c in :jobIDs];
		CreateSyncAssignments(jobs, configs, jobCrews);
	}
	
	public static void UpdateJobCrewSyncAssignments(List<SObject> jobCrews, List<Sync_Configuration__c> configs)
	{	
		if(jobCrews.isEmpty() || configs.isEmpty()) return;
		Set<Id> jobIDs = new Set<Id>();
		List<Job__c> jobs = new List<Job__c>();
		List<Crew_Planning__c> crews = new List<Crew_Planning__c>();
		for(SObject obj : jobCrews)
		{
			Crew_Planning__c cp = (Crew_Planning__c)obj;
			crews.add(cp);		
			if(!jobIDs.contains(cp.Job__c))
			{
				jobIDs.add(cp.Job__c);
				jobs.add(cp.Job__r);
			}
		}
		CreateSyncAssignments(jobs, configs, crews);		
	}

	public static void UpdateSyncAssignments(List<Job__c> jobs)
	{		
		Set<Id> unSyncJobIDs = new Set<Id>();
		List<Job__c> syncJobs = new List<Job__c>();

		Set<Id> jobIds = new Set<Id>();
		Set<Id> syncJobIds = new Set<Id>();
		Set<Id> quotes = new Set<Id>();
		for(Job__c j : jobs)
		{
			if(j.Sync__c)
			{
				syncJobs.add(j);
				syncJobIds.add(j.Id);
			}			 
			jobIds.add(j.Id);	
			if(QuoteExtension.HasQuoteV1 == true && j.get(QuoteExtension.QuoteV1FieldName) != null)
			{				
				quotes.add((Id)j.get(QuoteExtension.QuoteV1FieldName));
			}
		}
		if(!jobIds.isEmpty())
		{
			DeleteSyncAssignment(jobIds, quotes);
		}

		if(QuoteExtension.HasQuoteV1 == true)
		{
			//List<Job__c> deals = [SELECT Id, CustomerAccount__c, Office__c, Segment__c, RecordType.DeveloperName, RecordTypeId FROM Job__c 
			//WHERE Sync__c=true AND Id IN (SELECT Job__c FROM Ticket__c WHERE Id IN :quotes AND Sync__c = true)];

			String soql = String.format('SELECT Id, {0}CustomerAccount__c, {0}Office__c, {0}Segment__c, {0}Quote__c, RecordType.DeveloperName, RecordTypeId FROM {0}Job__c WHERE {0}Sync__c=true AND Id IN (SELECT {0}Job__c FROM {0}Ticket__c WHERE Id IN :quotes AND {0}Sync__c = true)', 
				new String[]{StringUtility.FXNamespace()});

			List<Job__c> deals = (List<Job__c>)Database.query(soql);
			for(Job__c j : deals)
			{
				if(syncJobIds.contains(j.Id)) continue;
				syncJobIds.add(j.Id);
				syncJobs.add(j);
				jobIds.add(j.Id);
			}
		}

		

		List<Id> crewIds = new List<Id>();
		Map<string, Id> jobTypeMap = GetJobTypePickListToRecordType();
		List<Sync_Configuration__c> syncConfigs = new List<Sync_Configuration__c>();

		for(Sync_Configuration__c sc: [SELECT Contact__c, Contact__r.User__c, Account__c, Job_Type__c, Office__c, Segment__c, Sync_JobCrewOnly__c FROM Sync_Configuration__c WHERE Contact__r.User__c!=null AND Contact__r.User__r.IsActive=true])
		{
			if(sc.Job_Type__c==null || sc.Job_Type__c=='' || jobTypeMap.containsKey(sc.Job_Type__c)) 
			{
				if(sc.Sync_JobCrewOnly__c) 
				{
					crewIds.add(sc.Contact__c);
				}
				syncConfigs.add(sc);
			}
		}

		List<Crew_Planning__c> jobCrews = crewIds.isEmpty()? new List<Crew_Planning__c>(): [SELECT Crew_Member__c, Job__c FROM Crew_Planning__c WHERE Crew_Member__c in :crewIds AND Job__c IN :jobIds];
		
		CreateSyncAssignments(syncJobs, syncConfigs, jobCrews);
	}

	public static void UpdateJobTicketSyncFlag(List<Status__c> statusItems)
	{			
		List<Status__c> jobStatus = new List<Status__c>();
		List<Status__c> ticketStatus = new List<Status__c>();
		for(Status__c s: statusItems)
		{			
			if(s.SObject__c =='Job__c') jobStatus.add(s);
			else if( s.SObject__c == 'Ticket__c') ticketStatus.add(s);
		}
		if(!jobStatus.isEmpty())
		{
			StatusTriggerJobSync t = new StatusTriggerJobSync(jobStatus);
			Database.executeBatch(t);
		}
		if(!ticketStatus.isEmpty())
		{
			StatusTriggerTicketSync t = new StatusTriggerTicketSync(ticketStatus);
			Database.executeBatch(t);
		}	
	}

	public static Set<Id> GetContacts(List<Sync_Configuration__c> syncConfigs)
	{
		Set<Id> contacts = new Set<Id>();		
		for(Sync_Configuration__c sc : syncConfigs) 
		{
			contacts.add(sc.Contact__c);
		}
		return contacts;
	}
	
}