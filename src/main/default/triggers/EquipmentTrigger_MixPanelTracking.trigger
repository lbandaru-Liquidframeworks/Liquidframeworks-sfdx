trigger EquipmentTrigger_MixPanelTracking on Equipment__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Equipment__c', trigger.isInsert, trigger.new.size());
}