public with sharing class SObjectDescribeInfo
{ 
    public SObjectDescribeInfo(Schema.DescribeSObjectResult r, 
        Set<String> typesOfInterest, 
        String rootObjFilter,
        String rootObjType,
        Map<String, String> optionalFilters)
    {       
        TypesForCloning = new Set<String>();
        for(String s: typesOfInterest)
        {
            TypesForCloning.add(s.toLowercase());
        }

        if(optionalFilters!=null && !optionalFilters.isEmpty())
        {
            for(String t : optionalFilters.keySet())
            {                
                ObjTypeOptionalFilters.put(t.toLowercase(), optionalFilters.get(t));
            }
        }        
        DescSObjResultLocal = r;
        ObjectType = r.Name;
        RootObjectFilter = GetPathsToRoot(ObjectType.toLowercase(), TypesForCloning, rootObjFilter, rootObjType.toLowercase()); 
        Init();  


    }  


    public static String GetPathsToRoot(String objType,
        Set<String> typesForCloning, 
        String rootObjFilter,
        String rootObjType)
    {      
        if(objType == rootObjType) return rootObjFilter;

       
        Schema.DescribeSObjectResult r = Schema.getGlobalDescribe().get(objType).getDescribe();

        Map<String, String> pathsToRoot = new Map<String, String>();
        Map<String, String> paths = new Map<String, String>();

        Map<String, String> masterDetailPaths = new Map<String, String>();

        Set<String> typesProcessed = new Set<String>();
        typesProcessed.add(objType);
        typesForCloning.add(rootObjType);
        //typesForCloning.remove(objType);

        for(Schema.SObjectField f: r.fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe();
            String fieldName = fd.getName().toLowercase();
            List<Schema.sObjectType> fks = fd.getReferenceTo();
            if(fks.isEmpty()) continue;

            String refType = fks.get(0).getDescribe().getName().toLowercase();
            if(!typesForCloning.contains(refType)) continue;
            
            if(fd.getRelationshipOrder() >= 0)                
            {
                masterDetailPaths.put(fieldName, refType);               
            }
            else
            {
                paths.put(fieldName, refType);                
            }
        }
        GetPathsToRoot(pathsToRoot, masterDetailPaths.isEmpty()? paths: masterDetailPaths, typesForCloning, rootObjType, typesProcessed);

        //System.debug(objType + ': ' + JSON.serializePretty(pathsToRoot));

        Set<String> pathItems = pathsToRoot.keySet();

        String filter = '';
        String sep = '';
        for(String p : pathItems)
        {
            String[] fields = p.split('\\.');
            if(fields.size()==1)
            {
                filter += sep + '(' + p.removeEndIgnoreCase('__c') + '__r.' + rootObjFilter + ')';
                
            }
            else
            {

                String formattedFieldName = (p.removeEndIgnoreCase('__c') + '__r.').replace('__c.', '__r.');

                filter += sep + '(' + formattedFieldName + rootObjFilter + ')';

            }
            sep = ' AND ';
        }
        return filter;
    }

    static void GetPathsToRoot(Map<String, String> pathsToRoot, Map<String, String> paths, 
        Set<String> typesForCloning, String rootType, Set<String> typesProcessed)
    {
       // System.debug('*************** paths: ' + JSON.serializePretty(paths));
        Map<String, sObjectType> types = Schema.getGlobalDescribe(); 

        Map<String, String> newPaths = new Map<String, String>();
        Map<String, String> masterDetailPaths = new Map<String, String>();

        for(String p: paths.keySet())
        {   
            String objType = paths.get(p);
            
            if(objType == rootType) 
            {
                pathsToRoot.put(p, paths.get(p));
                continue;
            }          
            Schema.DescribeSObjectResult r = types.get(objType).getDescribe();
            for(Schema.SObjectField f: r.fields.getMap().values())
            {
                Schema.DescribeFieldResult fd = f.getDescribe();
                String fieldName = fd.getName().toLowercase();
                List<Schema.sObjectType> fks = fd.getReferenceTo();
                if(fks.isEmpty()) continue;

                String refType = fks.get(0).getDescribe().getName().toLowercase();
                if(!typesForCloning.contains(refType) || typesProcessed.contains(refType)) continue;
                
                String path = p + '.' + fieldName;            

                if(fd.getRelationshipOrder() >= 0)                
                {
                    masterDetailPaths.put(path, refType);               
                }
                else
                {
                    newPaths.put(path, refType);                
                }


            }
            typesProcessed.add(objType);
        }


        if(!masterDetailPaths.isEmpty())
        {
            GetPathsToRoot(pathsToRoot, masterDetailPaths, typesForCloning, rootType, typesProcessed); 
        }
        else if(!newPaths.isEmpty())
        {
            GetPathsToRoot(pathsToRoot, newPaths, typesForCloning, rootType, typesProcessed);
        }
        
    }  

    Set<String> TypesForCloning {get; private set;}
    Schema.DescribeSObjectResult GetDescSObjResult()     
    {
        if(DescSObjResultLocal == null) 
        {
            DescSObjResultLocal = Schema.getGlobalDescribe().get(ObjectType).getDescribe();
        }
        return DescSObjResultLocal;
    }
    transient Schema.DescribeSObjectResult DescSObjResultLocal = null;

    Map<String, String> LookupFieldNameTypeMapping = new Map<String, String>();
    Map<String, String> ObjTypeOptionalFilters = new Map<String, String>();
   
    public sObject CreateSObject(sObject source, Map<Id, Id> oldNewIdMapping, Boolean alterName)
    {           
        sObject o = source.clone();

        if(!LookupFieldNameTypeMapping.isEmpty())
        {           
            for(String s : LookupFieldNameTypeMapping.keySet())
            {
                Id old = (Id)source.get(s);
                Object newRefValue = oldNewIdMapping.containsKey(old)? oldNewIdMapping.get(old) : null;
                o.put(s, newRefValue);
            }
        }

        if(alterName && IsNameEditable)
        {
            String str = String.valueOf(source.get('name')) + ' <Copy>';
            o.put('name', str.Length()>80? str.substring(0, 80) : str);
        }

        return o;
    }
    
    Boolean IsNameEditable 
    {
        get { return QueryFields.contains('name');}
    }

    public String ObjectType { get; private set; }  

    public String GetDiagnosis()
    {
        String sep = '<br />';
        Integer count = Database.countQuery(SelectCountQuery);

        Schema.DescribeSObjectResult desObjResult = Schema.getGlobalDescribe().get(ObjectType).getDescribe();
        Set<String> noAccessFields = new Set<String>();

        Set<String> theBlackoutFields = this.BlackoutFields;

        Set<String> requiredFieldsLackAccess = new Set<String>();
        for(Schema.SObjectField f: desObjResult.fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe(); 
            String fieldName = fd.getName().toLowercase();        

            if((!fd.isAccessible() || !fd.isCreateable())
                && !fd.isCalculated()                   
                && !fd.isAutoNumber()
                && !theBlackoutFields.contains(fieldName)) 
            {
                if(fd.isCustom()) 
                {
                    noAccessFields.add(fieldName);   
                }

                if(!fd.isDefaultedOnCreate() && !fd.isNillable())        
                {
                    requiredFieldsLackAccess.add(fieldName);
                }
            }
        }

        String msg = '<Strong>' + ObjectType + '</Strong>' +  sep
                + 'Item Count: ' + String.valueOf(count) + sep
                + 'Select Query: ' + SelectQuery + sep;
        if(HasSelfReferencingField)
        {
            msg += 'Self Referencing Field: ' + SelfReferenceFieldPath + sep;
        }

        if(!theBlackoutFields.isEmpty())
        {
            msg += 'Blackout Fields: ' + String.join(new List<String>(theBlackoutFields), ', ') + sep;
        }

        if(!noAccessFields.isEmpty())
        {
            msg += 'Custom Fields with NO Access: ' + String.join(new List<String>(noAccessFields), ', ') + sep;
        }    
        if(!requiredFieldsLackAccess.isEmpty())   
        {
            msg += 'FATAL ERROR - Required Fields with NO Access: ' + String.join(new List<String>(requiredFieldsLackAccess), ', ') + sep;
        } 

        if(!LookupFieldNameTypeMapping.isEmpty())
        {
            msg += 'Reference Fields: ' + JSON.serializePretty(LookupFieldNameTypeMapping) + sep;
        }      

        return msg;
    }
   
    public String SelfReferenceFieldPath {get; private set; }

    public Boolean HasSelfReferencingField 
    {
        get { return !String.isEmpty(SelfReferenceFieldPath); }
    }

    public String SelectQuery 
    {
        get
        {
            String typeFilter = String.isBlank(OptionalFilter)? '' : ' AND (' + OptionalFilter + ')';
            String selfRefrenceNullFirst = this.HasSelfReferencingField? (',' + this.SelfReferenceFieldPath + ' NULLS FIRST') : '';
            
            List<String> fields = new List<String>(this.QueryFields);
            if(!QueryFields.contains('name'))
            {
                fields.add('name');
            }
            String q = String.format('SELECT {0} FROM {1} WHERE IsDeleted=false AND ({2}) {3} ORDER BY CreatedDate {4}',
                new String[]{
                    String.join(fields, ','), 
                        this.ObjectType,
                        this.RootObjectFilter,
                        typeFilter, 
                        selfRefrenceNullFirst});
            return q;
        }
    }  
    public String OptionalFilter 
    {
        get
        {
            if(ObjTypeOptionalFilters.isEmpty()) return '';
            
            List<String> myFilters = new List<String>();

            String subjectType = GetDescSObjResult().getName().toLowercase();
            if(ObjTypeOptionalFilters.containsKey(subjectType))
            {
                myFilters.add('(' + ObjTypeOptionalFilters.get(subjectType) + ')');
            }
             
            for(String fkField : LookupFieldNameTypeMapping.keySet())
            {
                String objType = LookupFieldNameTypeMapping.get(fkField);               

                if(objType == subjectType
                    || !ObjTypeOptionalFilters.containsKey(objType)) continue;

                String refFilter = ObjTypeOptionalFilters.get(objType);

                String prefix = fkField.removeEndIgnoreCase('__c') + '__r.';
                Set<String> fields = StringUtility.GetSobjectFields(refFilter);
                for(String f: fields)
                {
                    refFilter = '(' + refFilter.replace(f, prefix + f) + ')';
                }            

                String filter = String.format('({0}=null OR ({1}))',
                    new String[]{ fkField, refFilter});

                myFilters.add(filter);

            }      
            return myFilters.isEmpty()? null : String.join(myFilters, ' AND ');      
        }      
    }

    public String SelectCountQuery 
    {
        get
        {
            String typeFilter = String.isBlank(OptionalFilter)? '' : ' AND (' + OptionalFilter + ')';
       
            return String.format('SELECT COUNT() FROM {0} WHERE IsDeleted=false AND ({1}) {2}', 
                new String[]{ this.ObjectType,
                              this.RootObjectFilter,
                              typeFilter});
        }
    }
   
    public String RootObjectFilter {get; private set;}

    Set<String> BlackoutFields {get;set;}

    Set<String> QueryFields {get;set;}

    void Init()
    {
        if(isInitialized == true) return;  

        String subjectType = GetDescSObjResult().getName().toLowercase();

        QueryFields = new Set<String>();  
        QueryFields.add('id');

        String ns = StringUtility.FXNamespace().toLowercase();

        Set<String> restrictedFields = new Set<String>();
        restrictedFields.add(ns + 'tracking_number__c');
        restrictedFields.add(ns + 'status__c');
        restrictedFields.add(ns + 'syncid__c');
        if(subjectType == ns + 'ticket_item__c')
        {
            restrictedFields.add(ns + 'invoice_item__c'); //#1061
        }

        BlackoutFields = GetBlackoutFields();

        for(Schema.SObjectField f: GetDescSObjResult().fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe(); 
            String fieldName = fd.getName().toLowercase();
            if(restrictedFields.contains(fieldName))
            {
                BlackoutFields.add(fieldName);
            }
            
            //master-detail field, blackout is not allowed
            if(fd.getRelationshipOrder() == 0)
            {
                BlackoutFields.remove(fieldName);
            }

            if(!fd.isAccessible() || BlackoutFields.contains(fieldName)) continue;

            if(fd.isCustom())
            {
                List<Schema.sObjectType> fks = fd.getReferenceTo();
                if(!fks.isEmpty()) 
                {
                    Schema.sObjectType fk = fks.get(0);
                    String referenceObjType = fk.getDescribe().Name.toLowercase();

                    if(subjectType == referenceObjType)
                    {
                        this.SelfReferenceFieldPath = fieldName;
                    }
                    if(TypesForCloning.contains(referenceObjType))
                    {
                        LookupFieldNameTypeMapping.put(fieldName, referenceObjType);
                    }
                }
            }

            if(!fd.isCreateable() || fd.isCalculated() || fd.isAutoNumber() 
                || fd.isExternalId() || fd.isUnique()) continue;

            QueryFields.add(fieldName);            
        }
        isInitialized = true;
    }
    Boolean isInitialized {get;set;}

    Set<String> GetBlackoutFields()
    {
        Set<String> results = new Set<String>();

        Map<String, Schema.FieldSet> fsMap = GetDescSObjResult().fieldSets.getMap();
        results.addAll(GetFieldSetFields(fsMap, 'cloneblackoutfields'));
        String ns = StringUtility.FXNamespace().toLowercase();
        if(!String.isBlank(ns))
        {
            results.addAll(GetFieldSetFields(fsMap, ns + 'cloneblackoutfields'));
        }
        return results;
    }

    static Set<String> GetFieldSetFields(Map<String, Schema.FieldSet> fsMap, String fieldsetName)
    {
        Set<String> results = new Set<String>();

        //Map<String, Schema.FieldSet> fsMap = desObjResult.fieldSets.getMap();

        String ns = StringUtility.FXNamespace();
        String nsLowercase = ns.toLowercase();

        if(!fsMap.containsKey(fieldsetName)) return results;

        Schema.FieldSet fieldSet = fsMap.get(fieldsetName);
        for(Schema.FieldSetMember fieldSetMemberObj:fieldSet.getFields())
        {
            results.add(fieldSetMemberObj.getFieldPath().toLowercase());         
        }
        return results;
    } 


     public static SObjectDescribeInfo GetSObjectDescribeInfo(Id objId)
    {
        List<SObjectDescribeInfo> results = GetSObjectDescribeInfo(objId, null, null);
        return (results!=null && !results.isEmpty())? results.get(0) : null;
    }

    public static sObject GetSObject(Id objId)
    {
        SObjectDescribeInfo s = GetSObjectDescribeInfo(objId);
        List<sObject> objs = Database.query(s.SelectQuery);
        return objs.isEmpty()? null : objs.get(0);
    }

    public static List<SObjectDescribeInfo> GetSObjectDescribeInfo(Set<Id> objIds, List<String> childTypes, Map<String, String> optionalFilters)
    {
        Map<String, SObjectDescribeInfo> results = new Map<String, SObjectDescribeInfo>();

        Id objId = (new List<Id>(objIds)).get(0);
        Schema.DescribeSObjectResult r = objId.getSobjectType().getDescribe();      

        String idStr = StringUtility.GetJoinedString(objIds, ',');

        String rootObjFilter = 'Id IN (' + idStr + ')';

        String rootObjType = r.getName().toLowercase();

        Set<String> typesOfInterest = new Set<String>();
        typesOfInterest.add(r.Name);

        List<String> typesInSequence = new List<String>();
        typesInSequence.add(r.Name);


        if(childTypes!=null && !childTypes.isEmpty())
        {
            typesOfInterest.addAll(childTypes);
            typesInSequence.addAll(childTypes);
        }       

        BuildSObjectDescribeInfoList(results, r, typesOfInterest, rootObjFilter, rootObjType, optionalFilters);      
        List<SObjectDescribeInfo> rs = new List<SObjectDescribeInfo>();

        Set<String> typesAdded = new Set<String>();

        for(String s : typesInSequence)
        {
            if(!typesAdded.contains(s) && results.containsKey(s))
            {
                rs.add(results.get(s));
                typesAdded.add(s);
            }
        }
        return rs;
    }

    public static List<SObjectDescribeInfo> GetSObjectDescribeInfo(Id objId, List<String> childTypes, 
        Map<String, String> optionalFilters)
    {
        return GetSObjectDescribeInfo(new Set<Id>{objId}, childTypes, optionalFilters);
    }   


    static void BuildSObjectDescribeInfoList(Map<String, SObjectDescribeInfo> results, 
        Schema.DescribeSObjectResult r, 
        Set<String> typesOfInterest, 
        String rootObjFilter,
        String rootObjType,
        Map<String, String> optionalFilters)
    {       
        SObjectDescribeInfo objInfo = new SObjectDescribeInfo(r, typesOfInterest, rootObjFilter, rootObjType,
            optionalFilters);      

        if(!results.containsKey(objInfo.ObjectType))
        {
            results.put(objInfo.ObjectType, objInfo);  
        }     

        String pType = r.Name;

        for(ChildRelationship cr : r.childRelationships)
        {          

            Schema.DescribeFieldResult fieldDsr = cr.getField().getDescribe();
            if(!fieldDsr.isAccessible()) continue;
             String fieldPath = fieldDsr.getName().toLowercase();

            Schema.DescribeSObjectResult dsr = cr.childSObject.getDescribe();

            Set<String> blackoutFields = new SObjectDescribeInfo(dsr, typesOfInterest, rootObjFilter, rootObjType,
                optionalFilters).BlackoutFields;
            
            if(blackoutFields.contains(fieldPath)) continue;

            String objType = dsr.name;
            
            if(objType == pType 
                || results.containsKey(objType) 
                || typesOfInterest ==null 
                || !typesOfInterest.contains(objType) 
                || !dsr.isCreateable()) continue;         

            BuildSObjectDescribeInfoList(results, dsr, typesOfInterest, rootObjFilter, rootObjType, optionalFilters);
            
        }
    }
  
}