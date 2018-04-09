trigger QuoteTrigger_MixPanelTracking on Quote__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Quote__c', trigger.isInsert, trigger.new.size());
}