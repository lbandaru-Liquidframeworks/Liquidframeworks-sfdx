public class CustomObjectInfoHandler  implements IFXWorker, Schedulable
{
    public virtual SvcResult DoWork(String param)
    {
        String msg = CustomObjectInfoHandler.RefreshCustomObjectInfo();
        SvcResult r = new SvcResult();
        r.Message = msg;
        return r;
    }

    public virtual void execute(SchedulableContext sc)
    {
        CustomObjectInfoHandler.RefreshCustomObjectInfo();
    }
    
    public static String RefreshCustomObjectInfo()
    {
        String apiUrl = URL.getSalesforceBaseUrl().toExternalForm() 
        + '/services/data/v37.0/tooling/query?q=SELECT+Id,DeveloperName,NamespacePrefix+FROM+CustomObject';

        String str = !Test.isRunningTest()? MetadataService.getRowResponse(apiUrl)
        : '{"size" : 2,"totalSize" : 2,"done" : true,"queryLocator" : null,"entityTypeName" : "CustomObject",'+
  '"records" : [ {"Id" : "01I36000001VBPgEAO","DeveloperName" : "Audit_Log"}, {"Id" : "01I36000001VBPhEAO","DeveloperName" : "Catalog_Item"}]}';

        return RefreshCustomObjectInfo(str);

    }

    @testVisible
    static String RefreshCustomObjectInfo(String str)
    {
        CustomObjectQueryResponse r = (CustomObjectQueryResponse)JSON.deserialize(str, 
            CustomObjectInfoHandler.CustomObjectQueryResponse.class);
        
        List<CustomObjectInfo__c> results = new List<CustomObjectInfo__c>();
        for(CustomObjectAttrs o : r.records)
        {            
            String ns = String.isBlank(o.NamespacePrefix)? '' : o.NamespacePrefix + '__';
            results.add(new CustomObjectInfo__c(DeveloperName__c = ns + o.DeveloperName + '__c', EntityDefinitionId__c = o.Id));
        }
        Database.UpsertResult[] dbResults = Database.upsert(results, CustomObjectInfo__c.Fields.EntityDefinitionId__c, false);

        Integer successCount = 0;
        Integer failCount = 0;
        Map<String, String> failedItemMsg = new Map<String, String>();
        for(Integer i=0; i<dbResults.size(); i++)
        {
            Database.UpsertResult ur = dbResults.get(i); 
            if(ur.isSuccess())
            {
                ++successCount;
            }
            else
            {   
                ++failCount;
                CustomObjectInfo__c dataItem = results.get(i);
                String msg = '';
                String sep = '';
                for(Database.Error e : ur.getErrors())
                {
                    msg += sep + e.getMessage();
                    sep = ' | ';
                }
                failedItemMsg.put(dataItem.DeveloperName__c, msg);
            }
        }
        String rMsg = successCount + ' items upserted successfully. ' + failCount + ' items failed.';
        if(!failedItemMsg.isEmpty())
        {
            rMsg += ' Error msg: ' + JSON.serializePretty(failedItemMsg);
        }
        return rMSg;
    }
    
    public class CustomObjectQueryResponse
    {
        public Integer size {get;set;}
        public List<CustomObjectAttrs> records {get;set;}
    }
    
    public class CustomObjectAttrs
    {
        public String Id {get;set;}
        public String DeveloperName {get;set;}
        public String NamespacePrefix {get;set;}
    }

}