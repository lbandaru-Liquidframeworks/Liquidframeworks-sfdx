public class JobTriggerHandler extends FXTriggerHandler
{
	
	public override void OnAfterUpdate(List<sObject> items, Map<Id, sObject> oldMap)
	{
		super.OnAfterUpdate(items, oldMap);
		List<Job__c> jobs = (List<Job__c>)items;	
			
		Set<Id> jobIds = new Set<Id>();
		
	        Set<String> rollupSummaryFields = MetadataHelper.GetRollupSummaryFields(Job__c.sObjectType); 
	        for(Job__c j : jobs)
	        {
	            Boolean isRollupUpdate = false;
	            Job__c prev = (Job__c)oldMap.get(j.Id);
	            for(String f : rollupSummaryFields)
	            {
	                if(j.get(f) != prev.get(f))
	                {
	                    isRollupUpdate=true;
	                    break;
	                }
	            }
	            if(!isRollupUpdate)
	            {
	        	   jobIds.add(j.Id);
	            }
	        }
	        if(!jobIds.isEmpty()) 
	        {
	            OverrideBatcher.RunOnJobs(jobIds);
	        }

	}
}