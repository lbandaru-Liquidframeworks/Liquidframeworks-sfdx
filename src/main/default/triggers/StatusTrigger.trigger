trigger StatusTrigger on Status__c (before insert, after insert, before update, after update)
{
	if(trigger.isInsert)
	{
		if(trigger.isBefore)
		{
			StatusBuilder.OnBeforeInsert(trigger.new);
		}
		else
		{
			StatusBuilder.OnAfterInsert(trigger.new);
		}
	}
	else if(trigger.isUpdate)
	{
		if(trigger.isBefore)
		{
			StatusBuilder.OnBeforeUpdate(trigger.new, trigger.oldMap);
		}
		else
		{
			StatusBuilder.OnAfterUpdate(trigger.new, trigger.oldMap);	
		}		
	}	
}