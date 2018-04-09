trigger EquipmentQualificationTrigger_MixPanelTracking on Equipment_Qualification__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Equipment_Qualification__c', trigger.isInsert, trigger.new.size());
}