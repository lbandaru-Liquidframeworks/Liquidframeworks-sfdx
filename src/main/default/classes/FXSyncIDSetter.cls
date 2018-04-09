public class FXSyncIDSetter
{
    public static void SetSyncID(string syncIdField, List<sObject> items)
    {
        for(sObject s : items)
        {
           if(!String.isBlank((String)s.get(syncIdField))) continue;
           
           s.put(syncIdField, StringUtility.newGuid());
        }        
    }    
    
    public static void SetSyncID(List<sObject> items)
    {      
        SetSyncID(UtilityGetNamespace.CurrentNamespace() + 'SyncID__c', items);     
    }
    
}