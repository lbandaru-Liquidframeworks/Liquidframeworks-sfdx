trigger PreventativeMaintenanceCriterionTrigger on Preventative_Maintenance_Criterion__c (before insert, before update, before delete, after insert, after update, after delete)
{   
    PMCTriggerHandler h = new PMCTriggerHandler();
    h.Execute(trigger.isDelete? trigger.old:trigger.new, trigger.oldMap, trigger.isBefore, trigger.isInsert, trigger.isUpdate, trigger.isDelete);
}