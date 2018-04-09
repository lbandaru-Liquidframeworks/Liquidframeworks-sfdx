public  class SyncConfigBatchable_UpdateExternalIds extends FXBatchableBase implements Database.Stateful
{
	
	Set<String> uniqueExternalIds = new Set<String>();

	public  SyncConfigBatchable_UpdateExternalIds()
	{
		soqlQuery = String.format('SELECT Id, {0}Contact__c, {0}Office__c, {0}Account__c, {0}Segment__c, {0}Sync_JobCrewOnly__c, {0}UniqueId__c, {0}UniqueExternalId__c, {0}Job_Type__c FROM {0}Sync_Configuration__c WHERE IsDeleted=false AND {0}Contact__r.{0}User__c!=null AND {0}Contact__r.{0}User__r.IsActive=true',
			new String[]{StringUtility.FXNamespace()});
	}
	 
	public override void execute(Database.BatchableContext BC, List<SObject> scope)
	{
		List<Sync_Configuration__c> itemsToUpdate = new List<Sync_Configuration__c>();
        List<Sync_Configuration__c> itemsToDelete = new List<Sync_Configuration__c>();        
      
	    for(SObject item : scope)
	    {        
	    	Sync_Configuration__c sc = (Sync_Configuration__c)item;
	        String str = SyncConfigBuilderController.GetUniqueId(sc);
	        if(uniqueExternalIds.contains(str))
	        {
	            itemsToDelete.add(sc);
	        }
	        else
	        {
	            sc.UniqueExternalId__c = str;
	            sc.UniqueId__c = str;
	            itemsToUpdate.add(sc);
	            uniqueExternalIds.add(str);
	        }
	    }
	    if(!itemsToDelete.isEmpty())
	    {
	        Database.delete(itemsToDelete, false);
	    }
	    if(!itemsToUpdate.isEmpty())
	    {
	        Database.update(itemsToUpdate, false);
	    }      		
	} 
}