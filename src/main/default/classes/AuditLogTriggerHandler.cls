public class AuditLogTriggerHandler extends FXTriggerHandler
{
    public override  void OnBeforeUpdate(List<sObject> objs, Map<Id, sObject> oldMap)
    {
        // By default all MP fields are expected to be readonly for updates, but these new fields are to be updated.
        Set<string> allowedObjectsOverride = new Set<string>();
        allowedObjectsOverride.Add('FX5__Cleared__c');
        allowedObjectsOverride.Add('FX5__Originating_Audit_Log__c');
        allowedObjectsOverride.Add('FX5__New_Audit_Log__c');

        PackageObjectHandler.EnforceBuiltInFieldsReadOnly(objs, oldMap, allowedObjectsOverride);
    }

    public override void OnBeforeDelete(List<sObject> objs)
    {
        if(!IsDeleteAllowedForCurrentUser())
        {
            PackageObjectHandler.DisallowDelete(objs);
        }
    }

    public static Boolean IsDeleteAllowedForCurrentUser()
    {
        String ns = UtilityGetNamespace.CurrentNamespace();
        if(!String.isBlank(ns) && !UserInfo.isCurrentUserLicensed(ns)) return false;

        if(UserInfo.getProfileId() == FXAppSettingsHandler.getSystemAdminProfileId()) return true;

        Id userId = UserInfo.getUserId();
        String objType = UtilityGetNamespace.CurrentNamespace() + 'Audit_Log__c';
        Integer count = [SELECT Count() FROM ObjectPermissions WHERE (ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :userId)) AND (PermissionsModifyAllRecords = true) AND (SobjectType = :objType)];
        return count>0;
    }

}