trigger TriggerSyncAssignmentOnSyncConfigUpdate on Sync_Configuration__c (after delete, after insert, after update)
{	
    
	if(trigger.isInsert)
	{	
		SyncAssignmentManager.UpdateSyncAssignments(trigger.new);
		}
	else
	{
		
        Set<Id> usersWithChanges =  SyncAssignmentManager.GetContacts(trigger.isDelete ? trigger.old : trigger.new);
        
		if(!usersWithChanges.isEmpty())
		{
			Database.delete([SELECT Id FROM Sync_Assignment__c WHERE Contact__c IN :usersWithChanges], true);
			SyncAssignmentManager.RefreshSyncAssignments(usersWithChanges);
		}
	}
}