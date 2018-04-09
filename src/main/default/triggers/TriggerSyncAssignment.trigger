trigger TriggerSyncAssignment on Sync_Assignment__c (before insert, before update, after insert, after update, after delete) 
{
	if(trigger.isBefore)
	{
	Set<string> keys = new Set<string>();
	for(Sync_Assignment__c sa: trigger.new)
	{
		sa.Sync_Assignment_ID__c = string.valueOf(sa.Job__c) + sa.Contact__c;
		keys.add(sa.Sync_Assignment_ID__c);
	}
	if(!keys.isEmpty())
	{
		Database.delete([Select Id FROM Sync_Assignment__c WHERE Sync_Assignment_ID__c IN :keys], false);
	}
	}
	else if(trigger.isInsert)
	{
		ChatterFeedManager.ProcessJobTicketFeeds(trigger.new, true);
	}
	else if(trigger.isUpdate)
	{
	}
	else
	{
		ChatterFeedManager.ProcessJobTicketFeeds(trigger.old, false);
	}
}