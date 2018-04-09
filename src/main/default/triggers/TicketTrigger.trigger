trigger TicketTrigger on Ticket__c (before insert, before update, before delete, after insert, after update, after delete) 
{
	FXTriggerHandler.Run(trigger.isDelete? trigger.old:trigger.new, trigger.oldMap, trigger.isBefore, trigger.isInsert, trigger.isUpdate, trigger.isDelete);

	if(trigger.isBefore)
	{
		if(trigger.isInsert)
		{
			TicketBuilder.OnBeforeInsert(trigger.new);
		}
		else if(trigger.isUpdate)
		{
			TicketBuilder.OnTicketUpdate(trigger.new, trigger.oldMap, true);
		}
		else
		{
			InventoryManager.RestoreInventoryUponTicketDelete(trigger.oldMap.keySet());
		}
	}
	else
	{
		if(trigger.isInsert)
		{
			TicketBuilder.OnAfterInsert(trigger.new);
		}
		else if(trigger.isUpdate)
		{
			TicketBuilder.OnTicketUpdate(trigger.new, trigger.oldMap, false);
		}
		
	}
}