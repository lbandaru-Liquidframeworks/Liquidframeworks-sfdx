public class CustomFieldInfoHandler implements IFXWorker, Schedulable
{
    public virtual SvcResult DoWork(String param)
    {
        String msg = CustomFieldInfoHandler.RefreshCustomFieldInfo();
        SvcResult r = new SvcResult();
        r.Message = msg;
        return r;
    }

    public virtual void execute(SchedulableContext sc)
    {
        CustomFieldInfoHandler.RefreshCustomFieldInfo();
    }
    
    public static String RefreshCustomFieldInfo()
    {   
        List<CustomFieldAttrs> records = GetCustomFieldAttrs();       
        Map<String, CustomObjectInfo__c> objLookup = new Map<String, CustomObjectInfo__c>();
        for(CustomObjectInfo__c o : [SELECT Id, DeveloperName__c, EntityDefinitionId__c FROM CustomObjectInfo__c WHERE IsDeleted=false])
        {
            objLookup.put(o.EntityDefinitionId__c, o);
        }       
       
        List<CustomFieldInfo__c> results = new List<CustomFieldInfo__c>();
        for(CustomFieldAttrs o : records)
        {
            if(!objLookup.containsKey(o.TableEnumOrId)) continue;

            String ns = String.isBlank(o.NamespacePrefix)? '' : o.NamespacePrefix + '__';

            CustomObjectInfo__c customObj = objLookup.get(o.TableEnumOrId);
            results.add(new CustomFieldInfo__c(CustomObjectInfo__c = customObj.Id,
                FieldDefinitionId__c = o.Id,
                DeveloperName__c = ns + o.DeveloperName + '__c', 
                FullName__c = customObj.DeveloperName__c + '.' + ns +  o.DeveloperName + '__c'));
        }
        Database.UpsertResult[] dbResults = Database.upsert(results, CustomFieldInfo__c.Fields.FullName__c, false);
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
                CustomFieldInfo__c cf = results.get(i);
                String msg = '';
                String sep = '';
                for(Database.Error e : ur.getErrors())
                {
                    msg += sep + e.getMessage();
                    sep = ' | ';
                }
                failedItemMsg.put(cf.FullName__c, msg);
            }
        }
        String rMsg = successCount + ' items upserted successfully. ' + failCount + ' items failed.';
        if(!failedItemMsg.isEmpty())
        {
            rMsg += ' Error msg: ' + JSON.serializePretty(failedItemMsg);
        }
        return rMSg;
    }

    public static List<CustomFieldAttrs> GetCustomFieldAttrs()
    {
        String apiRoot = URL.getSalesforceBaseUrl().toExternalForm();
        String apiUrl =  apiRoot + '/services/data/v31.0/tooling/query?q=SELECT+Id,TableEnumOrId,DeveloperName,NamespacePrefix+FROM+CustomField';
        
        Boolean done = false;
        List<CustomFieldAttrs> records = new List<CustomFieldAttrs>();
        
        while(!done)
        {
            String str = !Test.isRunningTest()? MetadataService.getRowResponse(apiUrl)
            : '{"size" : 4,"totalSize" : 4,"done" : true,"queryLocator" : null,"entityTypeName" : "CustomField",'
            +'  "records" : [ {"Id" : "00N3600000E0xkDEAR","TableEnumOrId" : "01I36000001VBPgEAO","DeveloperName" : "Event_Id"},'
            +' { "Id" : "00N3600000E0xkEEAR","TableEnumOrId" : "01I36000001VBPgEAO","DeveloperName" : "Message"},'
            +' { "Id" : "00N3600000E0xkFEAR","TableEnumOrId" : "01I36000001VBPgEAO","DeveloperName" : "Package_Id"},'
            +' { "Id" : "00N3600000E0xkGEAR","TableEnumOrId" : "01I36000001VBPgEAO","DeveloperName" : "Tracking_Number"}]}';

            CustomFieldQueryResponse r = (CustomFieldQueryResponse)JSON.deserialize(str, CustomFieldInfoHandler.CustomFieldQueryResponse.class);            
            records.addAll(r.records);
            done = r.done;
            apiUrl = apiRoot  + r.nextRecordsUrl;
        }
        return records;
    }   

    public class CustomFieldQueryResponse
    {
        public Integer size {get;set;}
        public Integer totalSize {get;set;}
        public Boolean done {get;set;}
        public String nextRecordsUrl {get;set;}
        public List<CustomFieldAttrs> records {get;set;}
    }
    
    public class CustomFieldAttrs
    {
        public String Id {get;set;}
        public String TableEnumOrId {get;set;}
        public String DeveloperName {get;set;}
        public String NamespacePrefix {get;set;}
    }
}