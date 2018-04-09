public with sharing class SObjectClonerBatchable extends FXBatchableBase implements Database.Stateful 
{
    public SObjectClonerBatchable() 
    {      
    } 
    
    public override String DryRun()
    {
        String msg = currentObjInfo.GetDiagnosis();
        String sep = '<br />';
        for(SObjectDescribeInfo s : sInfoToDo)
        {
            msg += sep + s.GetDiagnosis();
        }
        return msg;
    }
    public override void SetParams(Map<String, Object> params)
    {
        super.SetParams(params);
        if(!params.containsKey('sources')) return;
        String sourceIds = (String)params.get('sources');
        Set<Id> objIds = new Set<Id>();
        for(String o : sourceIds.split(','))
        {
            if(String.isBlank(o)) continue;
            objIds.add(Id.valueOf(o.trim().replace('\'', '')));                   
        }

        String cloneTypesInfo = params.containsKey('cloningtypes') ? (String)params.get('cloningtypes') : '';
        SObjectClonerUtility.CloningTypeInfo cInfo = SObjectClonerUtility.ParseCloningTypes(cloneTypesInfo); 

        List<SObjectDescribeInfo> sInfo = SObjectDescribeInfo.GetSObjectDescribeInfo(objIds, cInfo.Types, cInfo.OptionalFilters);
       
        Init(sInfo, new Map<Id, Id>()); 
    }

    public SObjectClonerBatchable(List<SObjectDescribeInfo> sInfo) 
    {   
        Init(sInfo, new Map<Id, Id>());        
    } 

    public SObjectClonerBatchable(List<SObjectDescribeInfo> sInfo, Map<Id, Id> idMapping) 
    {
        Init(sInfo, idMapping);       
    } 

    void Init(List<SObjectDescribeInfo> sInfo, Map<Id, Id> idMapping)
    {
        if(sInfo==null || sInfo.isEmpty()) return;

        lookupIdMapping = idMapping;        
        currentObjInfo = sInfo.get(0);
        soqlQuery = currentObjInfo.SelectQuery;        
        sInfoToDo = new List<SObjectDescribeInfo>(sInfo);
        sInfoToDo.remove(0);
    }
    
    public override void execute(Database.BatchableContext BC, list<Sobject> scope) 
    {
        if(currentObjInfo==null) return;
        SObjectClonerUtility.CloningInProgress = true;

        if(currentObjInfo.HasSelfReferencingField)
        {
            SObjectClonerUtility.CopySelfReferencingItems(currentObjInfo, scope, lookupIdMapping, false); 
        }
        else
        {
            List<sObject> newObjs = new List<sObject>();
            List<Id> objIds = new List<Id>();
            for(sObject o : scope)
            {
                newObjs.add(currentObjInfo.CreateSObject(o, lookupIdMapping, false));
                objIds.add(o.Id);
            }
            insert newObjs;
            for(Integer i=0; i<newObjs.size(); i++)
            {
                lookupIdMapping.put(objIds.get(i), newObjs.get(i).Id);
            }
        }
    }

    public override void finish(Database.BatchableContext BC) 
    {
        SObjectClonerUtility.CloningInProgress = false;
        
        if(sInfoToDo==null || sInfoToDo.isEmpty()) return;        
        Database.executeBatch(new SObjectClonerBatchable(sInfoToDo, lookupIdMapping));        
    }

    Map<Id, Id> lookupIdMapping {get;set;}
    SObjectDescribeInfo currentObjInfo {get;set;}
    List<SObjectDescribeInfo> sInfoToDo {get; set;}
}