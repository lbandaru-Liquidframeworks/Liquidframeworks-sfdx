trigger QualificationTrigger_MixPanelTracking on Qualification__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Qualification__c', trigger.isInsert, trigger.new.size());
}