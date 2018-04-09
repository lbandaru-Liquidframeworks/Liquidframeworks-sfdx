trigger PriceBookItemTrigger on Price_Book_Item__c (before insert, before update, before delete, after insert, after update, after delete) 
{  
    FXTriggerHandler.Run(trigger.isDelete? trigger.old:trigger.new, trigger.oldMap, trigger.isBefore, trigger.isInsert, trigger.isUpdate, trigger.isDelete);
}
/*
trigger PriceBookItemTrigger on Price_Book_Item__c(before insert, before delete) 
{
    if(trigger.isBefore)
    {
        if(trigger.isInsert)
        {
            PriceBookItemMangler.OnBeforeInsert(trigger.new);
        }
        else if(trigger.isDelete)
        {
            PriceBookItemMangler.OnBeforeDelete(trigger.old);      
        }  
    } 
}
*/