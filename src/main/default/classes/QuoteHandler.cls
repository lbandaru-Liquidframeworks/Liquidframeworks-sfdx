public class QuoteHandler
{
	public static void InitQuote(List<Quote__c> items)
	{
		for(Quote__c q: items)
		{
			if(String.isBlank(q.Tracking_Number__c)){
				q.Tracking_Number__c = StringUtility.getTrackingNumber('Q-');
			}
			if(String.isBlank(q.SyncID__c)){
				q.SyncID__c = StringUtility.newGuid();
			}
		}
        FXObjectStatusHandler.SetInitialStatus(items);
	}
	public static Job__c CreateJob(String quoteId, Boolean autoSave)
	{
		String ns = StringUtility.FXNamespace().toLowerCase();
		Set<String> quoteFields = Quote__c.sObjectType.getDescribe().fields.getMap().keySet();
		String qFieldsStr = String.join(new List<String>(quoteFields), ',');
		String soql = String.format('SELECT {1} FROM {0}Quote__c WHERE Id=:quoteId', 
			new String[]{ns, qFieldsStr});

		quoteFields.remove('id');
		quoteFields.remove('ownerid');
		quoteFields.remove('recordtypeid');
		quoteFields.remove(ns+'status__c');
		quoteFields.remove(ns+'syncid__c');
		quoteFields.remove(ns+'tracking_number__c');

		Quote__c q = (Quote__c)Database.query(soql);
		
		String jobType = q.Job_Type__c;
        String sObjType = ns + 'Job__c';

        Id jobRecordTypeId = null;

		if(!String.isBlank(jobType))
		{
			List<RecordType> rts = [SELECT Id, Name, DeveloperName FROM RecordType WHERE sObjectType=:sObjType AND (Name=:jobType OR DeveloperName=:jobType)];
			if(!rts.isEmpty())
			{
				jobRecordTypeId = rts.get(0).Id;	
			}
		}
		
		Job__c job = (Job__c)Job__c.sObjectType.newSObject(jobRecordTypeId, true);

		Schema.DescribeSObjectResult dsrJob = Job__c.sObjectType.getDescribe();

		for(Schema.SObjectField f : dsrJob.fields.getMap().values())
        {           
            Schema.DescribeFieldResult dsf = f.getDescribe();
            String fieldName = dsf.Name.toLowerCase();  
            String fieldName2 = fieldName.replace(ns, '');        

            if(!dsf.isAccessible() || dsf.isAutoNumber() || dsf.isCalculated() || !dsf.isCreateable() ||dsf.isUnique()) continue;

            if(quoteFields.contains(fieldName))
            {
            	job.put(fieldName, q.get(fieldName));
            }
            else if(quoteFields.contains(fieldName2))
            {
            	job.put(fieldName2, q.get(fieldName2));
            }
        }
        job.Quote2__c = quoteId;
        
        if(autoSave==true)
        {
        	insert job;
        }
		return job;
	}
}