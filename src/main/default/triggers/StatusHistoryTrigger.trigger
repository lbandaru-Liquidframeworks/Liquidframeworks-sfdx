trigger StatusHistoryTrigger on Status_History__c (before update, before delete) {
	
	if(FX_Settings__c.getInstance(UserInfo.getUserId()).TurnOffStatusHistoryTrigger__c) return;

    if(Trigger.isUpdate)
    {
        PackageObjectHandler.EnforceBuiltInFieldsReadOnly(trigger.new, trigger.oldMap);
    }
    else if(Trigger.isDelete)
    {
        PackageObjectHandler.DisallowDelete(trigger.old);
    }
}