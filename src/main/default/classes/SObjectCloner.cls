public with sharing class SObjectCloner {    

    public Enum ExecMode {DryRun, Sync, Async}

    ExecMode clonerExecMode {get; set;}

    public static String DeepCopy(Id objId, String typesToClone)
    {
        return DeepCopy(objId, typesToClone, ExecMode.Async);
    }

    public static String DeepCopy(Id objId, String typesToClone, ExecMode m)
    {
        SObjectCloner s = new SObjectCloner(objId,  typesToClone, m);
        return s.DoWork();
    }


    public static String DryRun(Id objId, String typesToClone)
    {
        SObjectCloner s = new SObjectCloner(objId,  typesToClone, ExecMode.DryRun);
        return s.DryRun();
    }

    public SObjectCloner(Id objId, String typesToClone)
    {
        this(objId, typesToClone, ExecMode.Async);
    }  


    public SObjectCloner(Id objId, String typesToClone, ExecMode mode)
    {
        this.SourceEntityId = objId; 
        cloneTypesInfo = typesToClone;  
        clonerExecMode = mode;
    }  

    public String DoWork() 
    {
        if(clonerExecMode == ExecMode.DryRun)
        {
            return DryRun();   
        }        
        if(clonerExecMode == ExecMode.Async)
        {
            return DeepCopyAsync();
        }
        
        Integer count = GetObjectsCount();

        Integer allowedDmlRows = Limits.getLimitDMLRows() - Limits.getDMLRows();

        System.debug('Total rows: ' + count + '; Allowed DML rows: ' + allowedDmlRows);

        return (count > allowedDmlRows)? DeepCopyAsync() : DeepCopy();      
        
    }  
    

    public Integer GetObjectsCount()
    {
        InitObjInfo();
        Integer count = 0;
        for(SObjectDescribeInfo sInfo : objInfo)
        {
            count += Database.countQuery(sInfo.SelectCountQuery);
        }
        return count;
    }

    public String DeepCopyAsync()
    {
        SObjectClonerUtility.CloningInProgress = (clonerExecMode != ExecMode.DryRun);
        InitObjInfo();

        if(objInfo==null || objInfo.isEmpty()) 
        {
            return null;
        }

        SObjectDescribeInfo sInfo = objInfo.remove(0);
        List<sObject> objs = Database.query(sInfo.SelectQuery);
        Map<Id, Id> idMapping = new Map<Id, Id>();

        sObject o = sInfo.CreateSObject(objs.get(0), idMapping, true);
        insert o;
                
        idMapping.put(SourceEntityId, o.Id);
        
        if(!objInfo.isEmpty())
        {
            SObjectClonerBatchable b = new SObjectClonerBatchable(objInfo, idMapping);
            Database.executeBatch(b);
        }       
        sObject dbObj = SObjectDescribeInfo.GetSObject(o.Id);
        EntityCopy = dbObj!=null? dbObj : o;
        return o.Id;
    }

    public String DryRun()
    { 
        SObjectClonerUtility.CloningInProgress = false;
        InitObjInfo();
        String msg = '';
        for(SObjectDescribeInfo sInfo : objInfo)
        {
            msg += sInfo.GetDiagnosis(); 
        }  
        return msg;
    }

    public sObject EntityCopy { get; private set; }


    public String DeepCopy()
    { 
        SObjectClonerUtility.CloningInProgress = (clonerExecMode != ExecMode.DryRun);
        InitObjInfo();

        Map<Id, Id> idMapping = new Map<Id, Id>();
        String msg = '';

        if(objInfo==null || objInfo.isEmpty()) 
        {
            return null;
        }

        SObjectDescribeInfo rootSInfo = objInfo.remove(0);
        List<sObject> objs = Database.query(rootSInfo.SelectQuery);

        sObject o = rootSInfo.CreateSObject(objs.get(0), idMapping, true);
        insert o;
        idMapping.put(objs.get(0).Id, o.Id);        

        Boolean alterNameField = false;  //Only update object name value for the root object

        for(SObjectDescribeInfo sInfo : objInfo)
        {
            List<sObject> newObjs = new List<sObject>();
            List<Id> sourceIds = new List<Id>();

            if(sInfo.HasSelfReferencingField)
            {
                List<sObject> items = Database.query(sInfo.SelectQuery);
                SObjectClonerUtility.CopySelfReferencingItems(sInfo, items, idMapping, alterNameField);                  
            }
            else
            {
                for(sObject s : Database.query(sInfo.SelectQuery))
                {    
                    sourceIds.add(s.Id);
                    newObjs.add(sInfo.CreateSObject(s, idMapping, alterNameField));
                }                 
                insert newObjs;  
                for(Integer i=0; i<newObjs.size(); i++)
                {
                    idMapping.put(sourceIds.get(i), newObjs.get(i).Id);
                }              
            }                            
        }  
        Id newId = idMapping.get(SourceEntityId);
        EntityCopy = SObjectDescribeInfo.GetSObject(newId);
        if(EntityCopy == null)
        {
            EntityCopy = o;
        }
        return newId;

    }

    void InitObjInfo()
    {
        if(objInfoLocal!=null || !SourceEntityId.getSobjectType().getDescribe().isCreateable()) return;  
                
        // types to clone might contain option filter as:
        // Ticket__c{IsArchived=false},Ticket_Item__c,Crew_Planning__c

        SObjectClonerUtility.CloningTypeInfo cInfo = SObjectClonerUtility.ParseCloningTypes(cloneTypesInfo);       

        objInfoLocal = SObjectDescribeInfo.GetSObjectDescribeInfo(SourceEntityId, cInfo.Types, cInfo.OptionalFilters);

    }

    Id SourceEntityId {get;set;}

    String cloneTypesInfo {get;set;}

    public List<SObjectDescribeInfo> objInfo 
    {
        get
        {
            if(objInfoLocal == null)
            {
                InitObjInfo();
            }
            return objInfoLocal;
        }
    }
    List<SObjectDescribeInfo> objInfoLocal = null;

    Boolean isDryRun {get; set;}
}