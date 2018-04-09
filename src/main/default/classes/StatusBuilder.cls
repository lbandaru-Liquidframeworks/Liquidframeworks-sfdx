public class StatusBuilder
{
	static void EnforceSingleInitialStatus(List<Status__c> items, Boolean isBeforeTrigger)
	{	
		Map<string, Status__c> mapInitStatus = new Map<string, Status__c>();
		for(Status__c s : items)
		{			
			if(s.Initial_Status_Console__c)
			{
				string key = s.SObject__c + s.SObject_Record_Type__c + 'c';
				if(mapInitStatus.containsKey(key) && isBeforeTrigger)
				{
					mapInitStatus.get(key).Initial_Status_Console__c = false;
					mapInitStatus.remove(key);
				}
				mapInitStatus.put(key, s);
			}
			if(s.Initial_Status_Mobile__c)
			{
				string key = s.SObject__c + s.SObject_Record_Type__c + 'm';
				if(mapInitStatus.containsKey(key) && isBeforeTrigger)
				{
					mapInitStatus.get(key).Initial_Status_Mobile__c = false;
					mapInitStatus.remove(key);
				}
				mapInitStatus.put(key, s);
			}

		}
		if(isBeforeTrigger) return;

		List<Status__c> statuses = [SELECT Id, SObject__c, SObject_Record_Type__c, Initial_Status_Console__c, Initial_Status_Mobile__c FROM Status__c WHERE (Initial_Status_Console__c=true OR Initial_Status_Mobile__c=true)];

		List<Status__c> itemsToUpdate = new List<Status__c>();
    	for(Status__c s: statuses)
    	{
    		Boolean hasChange = false;
    		if(s.Initial_Status_Console__c)
    		{
    			string key = s.SObject__c + s.SObject_Record_Type__c + 'c';
    			if(mapInitStatus.containsKey(key) && mapInitStatus.get(key).Id != s.Id)
    			{
    				s.Initial_Status_Console__c = false;
    				hasChange = true;
    			}    			
    		}
    		if(s.Initial_Status_Mobile__c)
    		{
    			string key = s.SObject__c + s.SObject_Record_Type__c + 'm';
    			if(mapInitStatus.containsKey(key) && mapInitStatus.get(key).Id != s.Id)
    			{
    				s.Initial_Status_Mobile__c = false;
    				hasChange = true;
    			}    
    		}
    		if(hasChange)
    		{
    			itemsToUpdate.add(s);
    		}
    	}

    	if(!itemsToUpdate.isEmpty())	           
	    {
	    	 update itemsToUpdate;	
	    }
	}	

	public static void OnBeforeInsert(List<Status__c> items)
	{
		List<Status__c> actionItems = new List<Status__c>();		
		for (Status__c s: items)
    	{
    		if (s.Initial_Status_Console__c || s.Initial_Status_Mobile__c) 
	        {	        	
    			actionItems.add(s);
	        }
	    }
	    if(!actionItems.isEmpty())	           
	    {
	    	EnforceSingleInitialStatus(actionItems, true);
	    }	   
	}	
	public static void OnAfterInsert(List<Status__c> items)
	{
		List<Status__c> actionItems = new List<Status__c>();		
		for (Status__c s: items)
    	{
    		if (s.Initial_Status_Console__c || s.Initial_Status_Mobile__c) 
	        {	        	
    			actionItems.add(s);
	        }
	    }
	    if(!actionItems.isEmpty())	           
	    {
	    	EnforceSingleInitialStatus(actionItems, false);
	    }	   
	}	


	public static void OnBeforeUpdate(List<Status__c> items, Map<Id, Status__c> oldMap)
	{
		List<Status__c> actionItems = new List<Status__c>();

		for (Status__c s: items)
    	{	       
	        if (s.Initial_Status_Console__c == true && s.Initial_Status_Console__c != oldMap.get(s.Id).Initial_Status_Console__c 
	        	|| s.Initial_Status_Mobile__c == true && s.Initial_Status_Mobile__c != oldMap.get(s.Id).Initial_Status_Mobile__c)
	        {
	        	actionItems.add(s);
	        }	       
    	}
    	if(!actionItems.isEmpty()) 
    	{
    		EnforceSingleInitialStatus(actionItems, true);
    	}    	
	}

	public static void OnAfterUpdate(List<Status__c> items, Map<Id, Status__c> oldMap)
	{	

		EnforceSingleInitialStatus(items, false);
		List<Status__c> actionItems = new List<Status__c>();
		for(Status__c s : items) 
		{
			if(oldMap.get(s.Id).Sync__c != s.Sync__c) 
			{
                actionItems.add(s);
            }			
	    }
	    if(!actionItems.isEmpty()) 
	    {	    	
	        SyncAssignmentManager.UpdateJobTicketSyncFlag(actionItems);            
	    }
	}
	
}