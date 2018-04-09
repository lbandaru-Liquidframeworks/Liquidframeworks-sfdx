trigger WarehouseItemTrigger_MixPanelTracking on Warehouse_Item__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Warehouse_Item__c', trigger.isInsert, trigger.new.size());
}