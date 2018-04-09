public class UserTriggerHandler extends FXTriggerHandler
{
    public override void OnAfterUpdate(List<sObject> items, Map<Id, sObject> oldMap)
    {
        List<User> users = (List<User>)items;
        Map<Id, User> m  = (Map<Id, User>)oldMap;

        Set<Id> inactiveUserIds = new Set<Id>();
        for(User u : users)
        {
            User prev = m.get(u.Id);
            if(u.IsActive == false && prev.IsActive)
            {
                inactiveUserIds.add(u.Id);
            }
        }
        RemovePackageLicenseForInactiveUsers(inactiveUserIds);
        DeleteSyncConfigs(inactiveUserIds);
    }

    public override void OnBeforeDelete(List<sObject> items)
    {
        Set<Id> userIds = new Map<Id, sObject>(items).keySet();
        DeleteSyncConfigs(userIds);
    }
    
    static void RemovePackageLicenseForInactiveUsers(Set<Id> inactiveUserIds)
    {
        if(inactiveUserIds==null || inactiveUserIds.isEmpty() || FX_Settings__c.getInstance(UserInfo.getUserId()).UserTriggerSkipPackageLicenseCleanup__c)
        {
            return;
        }       
        delete [SELECT Id FROM UserPackageLicense where UserId IN :inactiveUserIds AND PackageLicense.NamespacePrefix in ('FX5', 'FXTKT', 'FXEAM', 'FXT2', 'FXJSD', 'FXMAP', 'FXCPQ')];        
    }

    static void DeleteSyncConfigs(Set<Id> inactiveUserIds)
    {
        if(inactiveUserIds==null || inactiveUserIds.isEmpty() || FX_Settings__c.getInstance(UserInfo.getUserId()).UserTriggerKeepInactiveUserSyncConfigs__c) return;        
        Database.delete([SELECT Id FROM Sync_Configuration__c WHERE Contact__r.User__c IN :inactiveUserIds], false);
    }
}