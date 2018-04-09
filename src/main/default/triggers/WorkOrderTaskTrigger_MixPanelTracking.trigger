trigger WorkOrderTaskTrigger_MixPanelTracking on Work_Order_Task__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Work_Order_Task__c', trigger.isInsert, trigger.new.size());
}