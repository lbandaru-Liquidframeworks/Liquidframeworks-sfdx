trigger PreventativeMaintenanceScheduleTrigger_MixPanelTracking on Preventative_Maintenance_Schedule__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Preventative_Maintenance_Schedule__c', trigger.isInsert, trigger.new.size());
}