public class WorkOrderTaskTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> items)
    {
    	FXLicenseController.EnforceEAMLicense();
        FXSyncIDSetter.SetSyncID(items);
    }  
   	
   	public override void OnBeforeUpdate(List<sObject> items, Map<Id, sObject> oldMap)
    {
        FXLicenseController.EnforceEAMLicense();
    } 
    
    public override void OnBeforeDelete(List<sObject> items)
    {
    	FXLicenseController.EnforceEAMLicense();
    } 
}