trigger PreventativeMaintenanceCriterionTrigger_MixPanelTracking on Preventative_Maintenance_Criterion__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Preventative_Maintenance_Criterion__c', trigger.isInsert, trigger.new.size());
}