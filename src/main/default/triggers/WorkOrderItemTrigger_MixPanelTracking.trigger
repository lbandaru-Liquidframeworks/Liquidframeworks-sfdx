trigger WorkOrderItemTrigger_MixPanelTracking on Work_Order_Item__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Work_Order_Item__c', trigger.isInsert, trigger.new.size());
}