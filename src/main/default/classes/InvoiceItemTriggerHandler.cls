public class InvoiceItemTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> items)
    {   
        super.OnBeforeInsert(items);                
        OverrideHandler.ApplyOverride(items);
    }  
    
    public override void OnBeforeUpdate(List<sObject> items, Map<Id, sObject> oldMap)
    {   
        super.OnBeforeUpdate(items, oldMap);                
        OverrideHandler.ApplyOverride(items);
    }    
}