trigger WorkOrderQualificationTrigger_MixPanelTracking on Work_Order_Qualification__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Work_Order_Qualification__c ', trigger.isInsert, trigger.new.size());
}