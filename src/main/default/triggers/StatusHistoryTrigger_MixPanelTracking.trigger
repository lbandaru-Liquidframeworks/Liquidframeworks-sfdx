trigger StatusHistoryTrigger_MixPanelTracking on Status_History__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Status_History__c', trigger.isInsert, trigger.new.size());
}