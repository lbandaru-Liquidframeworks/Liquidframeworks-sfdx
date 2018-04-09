trigger WorkOrderTrigger_MixPanelTracking on Work_Order__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Work_Order__c', trigger.isInsert, trigger.new.size());
}