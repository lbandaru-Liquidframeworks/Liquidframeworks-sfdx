trigger WarehouseTrigger_MixPanelTracking on Warehouse__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Warehouse__c', trigger.isInsert, trigger.new.size());
}