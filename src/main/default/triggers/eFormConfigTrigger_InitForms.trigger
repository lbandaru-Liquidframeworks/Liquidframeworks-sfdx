trigger eFormConfigTrigger_InitForms on eForm_Config__c (before insert, before update, 
	after insert, after update) 
{
	if(trigger.isBefore)
	{
		eFormHandler.Validate(trigger.new, trigger.isInsert);		
	}
	else
	{
    	Set<String> formObjs = new Set<String>();
    	for(eForm_Config__c  c : trigger.new)
    	{
        	formObjs.add(c.eForm_SObject__c);         
    	}
    	eFormHandler.InitForms(formObjs);
    }
}