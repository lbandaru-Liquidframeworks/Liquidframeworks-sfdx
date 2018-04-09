public class LookupFilterHandler implements IFXWorker, Schedulable,
    Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful
{
    //System.debug(FXWorkerLauncher.DoWork('CustomObjectInfoHandler', null));
    //System.debug(FXWorkerLauncher.DoWork('CustomFieldInfoHandler', null));
    //LookupFilterHandler.Run();

    //System.debug(LookupFilterHandler.Run());
     
    
    List<LookupFilterRecord> LookupFilters = new List<LookupFilterRecord>();
    
    List<String> fieldDefinitionIds = new List<String>();
    
    List<String> itemsForRetry = new List<String>();

    String userSessionId {get;set;}

    public LookupFilterHandler()
    {
        Init(UserInfo.getSessionID(), GetLookupFieldDefinitionIds());
    }

    public LookupFilterHandler(String sessionId)
    {
        Init(sessionId, GetLookupFieldDefinitionIds());
    }

    @testVisible
    private LookupFilterHandler(String sessionId, List<LookupFilterRecord> filters, List<String> moreItems)
    {  
        LookupFilters = filters;
        Init(sessionId, moreItems);
    }  

    @testVisible
    private LookupFilterHandler(String sessionId, List<String> fieldIds)
    {
        Init(sessionId, fieldIds);
    }    

    void Init(String sessionId, List<Id> fieldIds)
    {   
        userSessionId = sessionId;

        fieldDefinitionIds = fieldIds;        
    }

    @testVisible
    static List<String> GetLookupFieldDefinitionIds()
    {
        List<String> results = new List<String>();

        Set<String> lookupFieldNames = new Set<String>();

        List<Schema.SObjectType> sobjTypes = Schema.getGlobalDescribe().values();
        String ns = StringUtility.FXNamespace();
        for(Schema.SObjectType o : sobjTypes)
        {
            Schema.DescribeSObjectResult r = o.getDescribe();            
            if(!r.isCustom()) continue;
            String objName = r.getName();

            Map<String, SObjectField> fields = r.fields.getMap();
            if(!fields.containsKey('sync__c') 
                && !fields.containsKey( ns + 'sync__c')
                && !fields.containsKey('altsync__c')
                && !fields.containsKey( 'syncid__c')
                && !fields.containsKey( ns + 'syncid__c'))
                continue;

            for(SObjectField f: fields.values())
            {
                Schema.DescribeFieldResult dfr = f.getDescribe();
                if(!dfr.isCustom() || dfr.getType() != DisplayType.Reference) continue;
                lookupFieldNames.add( objName + '.' + dfr.getName());
            }
        }

        List<CustomFieldInfo__c> fieldInfoEntries = Test.isRunningTest()? [SELECT FieldDefinitionId__c FROM CustomFieldInfo__c]
        : [SELECT FieldDefinitionId__c FROM CustomFieldInfo__c WHERE FullName__c IN :lookupFieldNames];

        for(CustomFieldInfo__c f : fieldInfoEntries)
        {
            results.add(f.FieldDefinitionId__c);
        } 
        return results;     
    }

    public virtual Iterable<String> start(Database.BatchableContext BC)
    {
        return fieldDefinitionIds;
    }

    public virtual void execute(Database.BatchableContext BC, List<String> scope)
    {   
        List<LookupFilterRecord> batchResults = Run(scope, this.itemsForRetry, this.userSessionId);
        LookupFilters.addAll(batchResults);
    } 
    
    public virtual void finish(Database.BatchableContext BC)
    {      
        if(!itemsForRetry.isEmpty())
        {
            Database.executeBatch(new LookupFilterHandler(this.userSessionId, LookupFilters, itemsForRetry), 50);
        }
        else
        {
            String s = FormatFilters(LookupFilters);
            UpsertFilters(s);
        }
    }

    static void UpsertFilters(String filters)
    {
        String contents = 'window.FX_Mobile_Filters = ' + filters;
        StaticResourceHandler.UpsertFile('FX_Mobile_Filters', contents);
        System.debug(contents);
    }


    static String FormatFilters(List<LookupFilterRecord> filters)
    {
        Map<String, SortingInfo> existingSortFormulas = GetSortFormulas();

        Map<String, Map<String, FormattedFilterEntry>> entries = new  Map<String, Map<String, FormattedFilterEntry>>();
        for(LookupFilterRecord f : filters)
        {
            String lookupObjType = f.referenceTo;
            if(!entries.containsKey(lookupObjType))
            {
                entries.put(lookupObjType, new Map<String, FormattedFilterEntry>());
            }   
            FormattedFilterEntry formattedEntry = new FormattedFilterEntry(lookupObjType, f.FullName, f.predicate);        
            if(existingSortFormulas.containsKey(f.FullName))
            {
                formattedEntry.sortFormula = existingSortFormulas.get(f.FullName);
                existingSortFormulas.remove(f.FullName);
            }
            entries.get(lookupObjType).put(f.FullName, formattedEntry);
        } 
        if(!existingSortFormulas.isEmpty())
        {
            for(SortingInfo si : existingSortFormulas.values())
            {
                String refTo = si.referenceTo;
                String fieldName = si.fieldFullName;
                if(!entries.containsKey(refTo))
                {
                    entries.put(refTo, new Map<String, FormattedFilterEntry>());
                }
                FormattedFilterEntry entry = new FormattedFilterEntry();
                entry.sortFormula = si;
                entries.get(refTo).put(fieldName, entry);
            }
        }
        String result =  JSON.serializePretty(entries, true);   
        result = result.replace('sort_FX', 'sort').replace('limit_FX', 'limit');      
        //System.debug('formatted fitlers: ' + result);
        return result;
    }


    static Map<String, SortingInfo> GetSortFormulas()
    {
        Map<String, SortingInfo> results = new Map<String, SortingInfo>();
        List<StaticResource> items = [SELECT Id, Body FROM StaticResource WHERE Name='FX_Mobile_Filters'];
        if(!Test.isRunningTest() && items.isEmpty()) return results;
        
        String contents = Test.isRunningTest()? 'window.FX_Mobile_Filters = {' + 
               '"Account": {       ' +
               '"Job__c.CustomerAccount__c": {' +
               '    "predicate": "Account.RecordType.DeveloperName != \'Office\' && (ISNULL($Source.Price_Book__c) || ISNULL($Source.Price_Book__r.Account__c) || $Source.Price_Book__r.Account__c==Account.Id)",' +
               '    "sortFormula": {' +
               '        "formula": "Account.Name",' +
               '        "limit": "10",' +
               '        "sort": "asc"' +
               '    }' +
               '}},' +
               '"Well__c": {' +
               '    "Job__c.Well__c": {' +
               '"sortFormula": {' +
               ' "formula": "Well__c.Current_Drilling_Depth__c",' +
               ' "thresholdFloor": "3000",' +
                '"thresholdCeiling": "9000",' +
                '"limit": "25",' +
               ' "sort": "desc"' +
            '}' +
        '}}}'
               : items.get(0).Body.toString();

        String str = contents .replace('window.FX_Mobile_Filters =', '').replace('\"sort\"', '\"sort_FX\"').replace('\"limit\"', '\"limit_FX\"').trim();
        
        Map<String, Map<String, FormattedFilterEntry>> filters = 
        (Map<String, Map<String, FormattedFilterEntry>>)JSON.deserialize(str, Map<String, Map<String, FormattedFilterEntry>>.class);

        for( String ref  : filters.keySet())
        {
            String refTo = ref;
            Map<String, FormattedFilterEntry> m = filters.get(ref);
            for(String k: m.keySet())
            {
                FormattedFilterEntry filter = m.get(k);
                if(filter.sortFormula == null) continue;
                SortingInfo si = filter.sortFormula;
                si.referenceTo = refTo;
                si.fieldFullName = k;
                results.put(k, filter.sortFormula);
            }
        }
        return results;
    }
    
    class FilterResult 
    {
        public FilterResult( Integer sc, String pStatus, String pBody)
        {
            StatusCode = sc;
            Status = pStatus;
            RawResponse = pBody;
        }

        public Boolean IsSuccess()
        {
            return StatusCode == 200; 
        }

        public Integer StatusCode {get;set;}
        public String Status {get; set;}
        public String RawResponse {get;set;}
    }

    static FilterResult GetHttpResponse(String endPoint)
    {
        return GetHttpResponse(endPoint, UserInfo.getSessionID());
    }
    static FilterResult GetHttpResponse(String endPoint, String sessionId)
    {
        System.debug(endPoint);

        HttpRequest req = new HttpRequest();

        req.setHeader('Authorization', 'Bearer ' + sessionId);
        req.setHeader('Content-Type', 'application/json');  
        req.setEndpoint(endPoint);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse res = null;
        if(Test.isRunningTest())
        {
                // Create a fake response
            String body =  '{"size" : 1,' + 
                      ' "totalSize" : 1,' +
                      ' "done" : true,' +
                      ' "queryLocator" : null,' +
                      ' "entityTypeName" : "CustomField",' +
                      ' "records" : [ {' +
                      '   "attributes" : {' +
                      '     "type" : "CustomField",' +
                      '     "url" : "/services/data/v31.0/tooling/sobjects/CustomField/00N3600000E0xm7EAB"' +
                      '   },' +
                      '   "Id" : "00N3600000E0xm7EAB",' +
                      '   "TableEnumOrId" : "01I36000001VBPtEAO",' +
                      '   "DeveloperName" : "Office",' +
                      '   "FullName" : "Job__c.Office__c",' +
                      '   "Metadata" : {' +
                      '     "caseSensitive" : null,' +
                      '     "customDataType" : null,' +
                      '     "defaultValue" : null,' +
                      '     "deleteConstraint" : "Restrict",' +
                      '     "deprecated" : null,' +
                      '     "description" : null,' +
                      '     "displayFormat" : null,' +
                      '     "displayLocationInDecimal" : null,' +
                      '     "encrypted" : null,' +
                      '     "escapeMarkup" : null,' +
                      '     "externalDeveloperName" : null,' +
                      '     "externalId" : false,' +
                      '     "formula" : null,' +
                      '     "formulaTreatBlanksAs" : null,' +
                      '     "inlineHelpText" : "Office responsible for completing the job.",' +
                      '     "isFilteringDisabled" : null,' +
                      '     "isNameField" : null,' +
                      '     "isSortingDisabled" : null,' +
                      '     "label" : "Office",' +
                      '     "length" : null,' +
                      '     "lookupFilter" : {' +
                      '       "booleanFilter" : null,' +
                      '       "filterItems" : [ {' +
                      '         "field" : "Account.RecordType.DeveloperName",' +
                      '         "operation" : "equals",' +
                      '         "value" : "Office",' +
                      '         "valueField" : null' +
                      '       } ],' +
                      '       "active" : true,' +
                      '       "description" : null,' +
                      '       "errorMessage" : null,' +
                      '       "infoMessage" : null,' +
                      '       "isOptional" : false' +
                      '     },' +
                      '     "maskChar" : null,' +
                      '     "maskType" : null,' +
                      '     "picklist" : null,' +
                      '     "populateExistingRows" : null,' +
                      '     "precision" : null,' +
                      '     "readOnlyProxy" : null,' +
                      '     "referenceTargetField" : null,' +
                      '     "referenceTo" : "Account",' +
                      '     "relationshipLabel" : "Jobs (Office)",' +
                      '     "relationshipName" : "Jobs1",' +
                      '     "relationshipOrder" : null,' +
                      '     "reparentableMasterDetail" : null,' +
                      '     "required" : true,' +
                      '     "restrictedAdminField" : null,' +
                      '     "scale" : null,' +
                      '     "startingNumber" : null,' +
                      '     "stripMarkup" : null,' +
                      '     "summarizedField" : null,' +
                      '     "summaryFilterItems" : null,' +
                      '     "summaryForeignKey" : null,' +
                      '     "summaryOperation" : null,' +
                      '     "trackFeedHistory" : false,' +
                      '     "trackHistory" : false,' +
                      '     "trackTrending" : false,' +
                      '     "type" : "Lookup",' +
                      '     "unique" : null,' +
                      '     "urls" : null,' +
                      '     "visibleLines" : null,' +
                      '     "writeRequiresMasterRead" : null' +
                      '   }} ]}';

            res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody(body);
                res.setStatusCode(200);
        }
        else
        {
            res = h.send(req); 
        }

        return new FilterResult( res.getStatusCode(), res.getStatus(), res.getBody());
    }

    public virtual SvcResult DoWork(String param)
    {
        SvcResult r = new SvcResult();
        String msg = LookupFilterHandler.Run();
        System.debug(msg);
        r.Message = msg;
        return r;
    }

    public virtual void execute(SchedulableContext sc)
    {
        LookupFilterHandler.Run();
    }

    public static String RefreshLookupFilters()
    {
        return Run();
    }   
   
    Static List<LookupFilterRecord> Run(List<String> fieldIds, List<String> itemsForRetry, String userSessionId)
    { 
        String apiRoot = URL.getSalesforceBaseUrl().toExternalForm();
        String apiUrl =  apiRoot 
                + '/services/data/v31.0/tooling/query?q=SELECT+Id,TableEnumOrId,DeveloperName,FullName,Metadata+FROM+CustomField+WHERE+ID=%27[fieldId]%27';   
       
        List<LookupFilterRecord> results = new List<LookupFilterRecord>();
        for(String f: fieldIds)
        {
            String urlStr  = apiUrl.replace('[fieldId]', f);
            FilterResult r = GetHttpResponse(urlStr, userSessionId); 
            if(r.IsSuccess())
            {
                String str = r.RawResponse;
                try
                {
                
                    LookupFilterRawResponse result = (LookupFilterRawResponse)JSON.deserialize(str, 
                        LookupFilterRawResponse.class);

                    if(result.HasActiveFilter())
                    {   
                        results.add(result.LookupFilter);
                    }
                }
                catch(Exception ex)
                {
                    System.debug(ex);
                    System.debug(str);
                }
            }
            else 
            {
                if(r.StatusCode == 408)
                {
                    itemsForRetry.add(f);
                }
            }
        } 
        return results;       
    }
   

   public static String Run()
   {
        //System.debug(FXWorkerLauncher.DoWork('CustomObjectInfoHandler', null));
        //System.debug(FXWorkerLauncher.DoWork('CustomFieldInfoHandler', null));
        List<CustomObjectInfo__c> objInfo = [SELECT Id FROM CustomObjectInfo__c LIMIT 1];
        String ns = StringUtility.FXNamespace().replace('__', '.');
        if(objInfo.isEmpty())
        {          
            System.debug(FXWorkerLauncher.DoWork(ns + 'CustomObjectInfoHandler', null));
            return 'Running CustomObjectInfoHandler to populate CustomObjectInfo. Please execute ' + ns + 'LookupFilterHandler.Run() again to populate CustomFieldInfo.';
        }
       
        List<CustomFieldInfo__c> fieldInfo = [SELECT Id FROM CustomFieldInfo__c LIMIT 1];
        if(fieldInfo.isEmpty())
        {            
            System.debug(FXWorkerLauncher.DoWork(ns + 'CustomFieldInfoHandler', null));
            return 'Running CustomObjectInfoHandler to populate CustomFieldInfo. Please execute ' + ns + 'LookupFilterHandler.Run() again to refresh FX_Mobile_Filters.';              
        }

        List<String> fields = GetLookupFieldDefinitionIds();  
        String msg = '';
        if(fields.size() <= 100)
        {   
            List<String> itemsForRetry = new List<String>();
            List<LookupFilterRecord> results = Run(fields, itemsForRetry, UserInfo.getSessionID());
            msg = FormatFilters(results);
            StaticResourceHandler.UpsertFile('FX_Mobile_Filters', msg);
            System.debug(msg);         
        }
        else
        {
            msg = 'There are ' + fields.size() + ' lookup fields, have to run in batch mode.';
            Database.executeBatch(new LookupFilterHandler(UserInfo.getSessionID(), fields), 50);
        }
        return msg;
   }  

   @testVisible
   class LookupFilterRawResponse 
    {
        //public Integer size {get; set;}
        //public Integer totalSize {get; set;}
        public List<LookupFilterRecord> records {get;set;}

        public Boolean HasActiveFilter()
        {
            LookupFilterInfo filters = records.get(0).Metadata.lookupFilter;
            return filters != null
                && filters.active == true
                && filters.filterItems != null 
                && !filters.filterItems.isEmpty();
        }           
        
        public LookupFilterRecord LookupFilter
        {
            get { return records.get(0); }
        }
    }

    @testVisible
    class LookupFilterRecord
    {
        /*
        public String Id {get; set;}
        public String TableEnumOrId {get; set;}
        public String DeveloperName {get; set;}   
        
        */    
        public String FullName {get; set;}        

        public LookupFilterMetadata MetaData {get; set;}
        
        public String referenceTo 
        {
            get{ return MetaData.referenceTo; }
        }
        
        public String predicate
        {
            get{ return MetaData.lookupFilter.GetPredicate() ; }
        }
    }

    class LookupFilterMetadata 
    {
        /*
        public String description {get;set;}
        public String inlineHelpText {get;set;}
        public String label {get;set;}
       
        public String relationshipLabel {get;set;}
        public String relationshipName {get;set;}
        public Boolean required {get;set;}
        */
        
        public String referenceTo {get;set;}
        public LookupFilterInfo lookupFilter {get;set;}
        
    }
    class LookupFilterInfo
    {   
        /*
              
        public String description {get;set;}
        public String errorMessage {get;set;}
        public String infoMessage {get;set;}
        public Boolean isOptional {get;set;}
        */
        
        public Boolean active {get;set;} 
        public String booleanFilter {get;set;}
        public List<LookupFilter> filterItems {get;set;}

        public String GetPredicate()
        {
            String result = '';
            
            List<String> filters = new List<String>();
            for(LookupFilter f: filterItems)
            {
                filters.add(f.GetPredicate());
            }
            if(String.isBlank(booleanFilter))
            {
                result = String.join(filters, ' && ');
            }
            else
            {
                filters.add(0, '');
                List<Integer> params = new List<Integer>();
                Pattern p = Pattern.compile('[1-9]+');
                Matcher m= p.matcher(booleanFilter);
                
                while(m.find()) 
                {    
                    String matchStr = m.group(); 
                    params.add(Integer.valueOf(matchStr));  
                }
                
                params.sort();
                
                String f = booleanFilter.replace('AND', '&&').replace('OR', '||');
                
                for(Integer i=params.size()-1; i>=0; i--)
                {
                    Integer n= params.get(i);
                    f = f.replace(String.valueOf(n), '{' + n + '}'); 
                }  
                f = '{0}' + f;
                result = String.format(f, filters);                
            }
            return result;

        }
    }

    class LookupFilter
    {
        public String field {get;set;}
        public String operation {get;set;}
        public String value {get;set;}
        public String valueField {get;set;}

        public String GetPredicate()
        {
            String op = operation ;
            String result = '';
            
            if(field.contains('RecordTypeId'))
            {
              field = field.replace('RecordTypeId', 'RecordType.DeveloperName');
            }
            
            if(operation == 'equals')
            {
                op = '==';
            }
            else if(operation == 'notEqual')
            {
                op = '!=';
            }
            else if(operation == 'lessThan')
            {
                op = '<';
            }
            else if(operation == 'greaterThan')
            {
                op = '>';
            }
            else if(operation == 'lessOrEqual')
            {
                op = '<=';
            }           
            else if(operation == 'greaterOrEqual')
            {
                op = '>=';
            } 
            else if(operation == 'contains' || operation == 'startsWith' || operation=='notContain')
            {
                if(operation=='notContain')
                {
                    operation = '!contains';
                }
                return String.format('{0}({1}, {2})', new String[]{
                    operation, field, '\'' + value + '\''});
            } 
            
            if(!String.isBlank(valueField ))
            {
                result = field + op + valueField ;
            }
            else
            {
                String v = value;
                if(v == 'True' || v== 'False')
                {
                    result = field  + op + value;
                }
                else if(v.isNumeric())
                {
                    result = field + op + value;
                }
                else if(String.isBlank(v))
                {
                    result = 'ISNULL(' + field + ')';
                }
                else
                {
                  Pattern p =  Pattern.compile('^[+-]?[0-9]+[\\.]?[0-9]*$');
                  String str = v.replace(',', '').trim();
                  Matcher m = p.matcher(str);
                  if(m.matches())
                  {
                     result = field + op + str;
                  }
                  else
                  {
                    result = field + op + '\'' + v + '\''; 
                  }
                }
            }            
            
            return result;

        }
    }  
    
    class FormattedFilterEntry
    {
        public FormattedFilterEntry(){}
        
        public FormattedFilterEntry(String refTo, String field, String p)
        {
            fieldFullName = field;
            referenceTo = refTo;
            predicate = p;
        }
        
        public String predicate {get;set;}
        public SortingInfo sortFormula {get;set;}

        public transient String fieldFullName {get;set;}
        public transient String referenceTo {get;set;}
    }
    
    class SortingInfo
    {
        public String formula {get;set;}
        public String limit_FX {get;set;}
        public String sort_FX {get;set;}
        public String thresholdFloor {get;set;}
        public String thresholdCeiling {get;set;}

        public transient String fieldFullName {get;set;}
        public transient String referenceTo {get;set;}
        
        public override String toString()
        {
            return JSON.serializePretty(this, true).replace('limit_FX', 'limit').replace('sort_FX', 'sort');
        }        
    }
}