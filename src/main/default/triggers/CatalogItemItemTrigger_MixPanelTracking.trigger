trigger CatalogItemItemTrigger_MixPanelTracking on Catalog_Item__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Catalog_Item__c', trigger.isInsert, trigger.new.size());
}