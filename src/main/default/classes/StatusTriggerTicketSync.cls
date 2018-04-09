global class StatusTriggerTicketSync implements Database.Batchable<SObject>
{
	
	final String Query;	
	Set<Id> statusIds {get; set;}

	public StatusTriggerTicketSync()
	{
		this(null);
	}

	global StatusTriggerTicketSync(List<Status__c> statusItems)
	{		
		String ns = StringUtility.FXNamespace();	
		String statusIdFilter = '';
		if(statusItems!=null && !statusItems.isEmpty())
		{	
			statusIds = new Map<Id, Status__c>(statusItems).keySet();
			statusIdFilter = String.format(' AND {0}Status__c IN :statusIds', new String[]{ns});
		}
		Query= String.format('SELECT {0}Sync__c FROM {0}Ticket__c WHERE IsDeleted=false AND (({0}Sync__c=true AND {0}Status__r.{0}Sync__c=false) OR ({0}Sync__c=false AND {0}Status__r.{0}Sync__c=true)) {1}',
			new String[]{ns, statusIdFilter});
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC)
	{
		return Database.getQueryLocator(Query);
	}
 
	global void execute(Database.BatchableContext BC, List<SObject> scope)
	{
		List<Ticket__c> tickets = (List<Ticket__c>)scope;
		for(Ticket__c t : tickets)
		{				
			t.Sync__c = !t.Sync__c;
		}
		update tickets;
	}
 
	global void finish(Database.BatchableContext BC)
	{		
	}
}