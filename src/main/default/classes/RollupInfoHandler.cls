public class RollupInfoHandler implements IFXWorker, Schedulable
{
	public virtual SvcResult DoWork(String param)
	{
		String msg = RollupInfoHandler.RefreshRollupSummary();
		SvcResult r = new SvcResult();
		r.Message = msg;
		return r;
	}

	public virtual void execute(SchedulableContext sc)
    {
        RollupInfoHandler.RefreshRollupSummary();
    }

    public static String RefreshRollupSummary()
    {
        String contents = JSON.serializePretty(GetRollupFieldInfo());           
        return StaticResourceHandler.UpsertFile('FX_Mobile_Rollups', contents);   
    } 

	@testVisible
	static List<RollupField> GetRollupFieldInfo()
	{
		Map<String, Schema.SObjectType> globalDescribes = Schema.getGlobalDescribe();

		Set<String> sobjTypes = new Set<String>();
        String ns = StringUtility.FXNamespace();  
        for(String s: globalDescribes.keySet())
        {
        	if(s.endsWithIgnoreCase('__history') 
				||s.endsWithIgnoreCase('__share') 
				|| s.endsWithIgnoreCase('__mdt'))
			{
				continue;
			}		

            if(s.startsWithIgnoreCase(ns) || s.removeEndIgnoreCase('__c').indexOf('__')<0)
            {
                sobjTypes.add(s);
            }
        }

		Map<String,String> sobjTypeLookup = new Map<String, String>();
		List<EntityDefinition> entityDefs = [SELECT QualifiedApiName, DurableId FROM EntityDefinition WHERE QualifiedApiName IN :sobjTypes];

		for(EntityDefinition e : entityDefs)
		{
			sobjTypeLookup.put(e.QualifiedApiName, e.DurableId);
		}

		List<RollupField> rollupFieldsInfo = new List<RollupField>();

		for(String t : sobjTypeLookup.keySet())	
		{
			List<String> fieldNames = GetRollupFields(globalDescribes.get(t));
			if(fieldNames.isEmpty()) continue;

			List<RollupField> rollups = GetRollupFieldInfo(sobjTypeLookup.get(t), t, fieldNames);

			if(!rollups.isEmpty())
			{
				rollupFieldsInfo.addAll(rollups);
			}			
		}
		return rollupFieldsInfo;
	}

    @testVisible
    static List<RollupField> GetRollupFieldInfo(String objTypeDurableId, String sobjType, List<String> rollupFields)
    {   
        List<RollupField> results = new List<RollupField>();    
        String apiUrlRoot = URL.getSalesforceBaseUrl().toExternalForm();
        String ns = StringUtility.FXNamespace();

		for(String f : rollupFields)
		{
			HttpRequest req = new HttpRequest();
	        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
	        req.setHeader('Content-Type', 'application/json');

            String devName = f.removeStartIgnoreCase(ns).removeEndIgnoreCase('__c');
            
            String endPoint = String.format('{0}/services/data/v37.0/tooling/query?q=SELECT+Metadata+FROM+CustomField+WHERE+TableEnumOrId=%27{1}%27+AND+DeveloperName=%27{2}%27',
                new String[]{apiUrlRoot, objTypeDurableId, devName});

            System.debug('endPoint: ' + endPoint);

	        req.setEndpoint(endPoint);
	        req.setMethod('GET');
	        Http h = new Http();
	        HttpResponse res = null;
	        if(Test.isRunningTest())
	        {
	        	// Create a fake response
		        res = new HttpResponse();
		        res.setHeader('Content-Type', 'application/json');
		        res.setBody('{"records" : [{"Metadata" : {"summarizedField" : null, "summaryFilterItems" : [ {"field" : "Ticket_Item__c.Auto_Added__c", "operation" : "equals","value" : "False","valueField" : null  }], "summaryForeignKey" : "Ticket_Item__c.Ticket__c", "summaryOperation" : "count"}}]}');
   				res.setStatusCode(200);
	        }
	        else
	        {
	        	res = h.send(req); 
	        }
	        String rawStr = res.getBody();

	        System.debug(sobjType + '.' + f + ' raw data: ' + rawStr);

	        RollupInfoHandler.CustomFieldResponse r =  (RollupInfoHandler.CustomFieldResponse)JSON.deserialize(rawStr, RollupInfoHandler.CustomFieldResponse.class);
	       
	        results.add(new RollupField(sobjType, f, r.GetMetaData()));

		}

		return results;      
	}

	public static List<String> GetRollupFields(sObjectType sobjType)
	{
		Schema.DescribeSObjectResult desObjResult = sobjType.getDescribe();
        List<String> rollupFields = new List<String>();
        for(Schema.SObjectField f: desObjResult.fields.getMap().values())
		{
		    Schema.DescribeFieldResult fd = f.getDescribe(); 
		    if(!fd.isCustom() || !fd.isCalculated() || !String.isBlank(fd.getCalculatedFormula())) continue;
		    rollupFields.add(fd.getName());
		}
		return rollupFields;
	}


	class RollupField
	{
		public RollupField(){}

		public RollupField(String sObjType0, String f, MetadataInfo m)
		{
			sObjType = sObjType0;
			fieldName = f;
			summarizedField = m.summarizedField;
			summaryForeignKey = m.summaryForeignKey;
			summaryOperation = m.summaryOperation;
			summaryFilterItems = m.summaryFilterItems;
		}

		public String sObjType {get; set;}
		public String fieldName {get;set;}
		public String summarizedField {get;set;}
		public String summaryForeignKey {get;set;}
		public String summaryOperation {get;set;} 
		public List<FilterItem> summaryFilterItems {get;set;}
	}

	class CustomFieldResponse
	{
		public List<RecordItem> records {get;set;}		

		public MetadataInfo GetMetaData()
		{
			return records.get(0).Metadata;
		}

	}
	class RecordItem
	{
		public MetadataInfo Metadata {get;set;}
	}

	class MetadataInfo
	{
		public String summarizedField {get;set;}
		public String summaryForeignKey {get;set;}
		public String summaryOperation {get;set;}
		public List<FilterItem> summaryFilterItems {get;set;}
	}

	class FilterItem
	{
		public String field {get;set;}
		public String operation {get;set;}
		public String value {get;set;}
		public String valueField {get;set;}
	}
}