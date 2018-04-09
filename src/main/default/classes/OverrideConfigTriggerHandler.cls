public class OverrideConfigTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> items)
    {
        super.OnBeforeInsert(items);
        if(!System.isBatch())
        {
        	OverrideHandler.Validate((List<Override_Config__c>)items);
        }
    }
    
    public override void OnBeforeUpdate(List<sObject> items, Map<Id, sObject> oldmap)
    {
        super.OnBeforeUpdate(items, oldmap);
        if(!System.isBatch())
        {
        	OverrideHandler.Validate((List<Override_Config__c>)items);
        }
    }
}