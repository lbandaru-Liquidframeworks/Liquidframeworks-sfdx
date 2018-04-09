trigger JobTrigger on Job__c(before insert, before update, before delete, after insert, after update, after delete) 
{
    FXTriggerHandler.Run(trigger.isDelete? trigger.old:trigger.new, trigger.oldMap, trigger.isBefore, trigger.isInsert, trigger.isUpdate, trigger.isDelete);

    if(trigger.isBefore)
    {
        if(trigger.isInsert)
        {
            JobBuilder.OnBeforeInsert(trigger.new);
        }
        else if(trigger.isUpdate)      
        {
            JobBuilder.OnBeforeUpdate(trigger.new, trigger.oldMap);
        }
        else
        {
            InventoryManager.RestoreInventoryUponJobDelete(trigger.oldMap.keySet());
        }
    }
    else
    {
        if(trigger.isInsert)
        {
            JobBuilder.OnAfterInsert(trigger.new);
        }
        else if(trigger.isUpdate)      
        {
            JobBuilder.OnAfterUpdate(trigger.new, trigger.oldMap);
        }
    }
}