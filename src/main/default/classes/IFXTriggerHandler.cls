global interface  IFXTriggerHandler
{
    void OnBeforeInsert(List<sObject> items);    
    void OnAfterInsert(List<sObject> items);    
    void OnBeforeUpdate(List<sObject> items, Map<Id, sObject> oldMap);    
    void OnAfterUpdate(List<sObject> items, Map<Id, sObject> oldMap);    
    void OnBeforeDelete(List<sObject> items);    
    void OnAfterDelete(List<sObject> items);
    void Execute(List<sObject> items, Map<Id, sObject> oldMap, Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete);
}