trigger TicketItemTrigger on Ticket_Item__c (before insert, before update, before delete, after insert, after update, after delete) 
{
    if(trigger.isBefore)
    {
        if(trigger.isInsert)
        {
            TicketItemMangler.OnBeforeInsert(trigger.new);
        }
        else if(trigger.isUpdate)
        {
            TicketItemMangler.OnBeforeUpdate(trigger.new, trigger.oldMap);      
        }
        else //before delete
        {
            TicketItemMangler.OnBeforeDelete(trigger.old);      
        }  
    }
    else
    {
        if(trigger.isInsert)
        {
            TicketItemMangler.OnAfterInsert(trigger.new);
        }
        else if(trigger.isUpdate)
        {
            TicketItemMangler.OnAfterUpdate(trigger.new, trigger.oldMap);      
        }
        else //before delete
        {
            TicketItemMangler.OnAfterDelete(trigger.old);      
        }  
    }    
}