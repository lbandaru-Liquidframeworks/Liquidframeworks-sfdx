public class CatalogItemPriceBookTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> items)
    {
        CatalogItemPriceBookHandler.SetDirtyFlagJointKey((List<CatalogItemPriceBook__c>)items);
    }

    public override void OnAfterInsert(List<sObject> items)
    {
        if(!System.isBatch() && !System.isFuture()) 
        {
            CatalogItemPriceBookBatcher.ScheduleRefreshPriceBookIndex(0);
        }
    }


    public override void OnAfterDelete(List<sObject> items)
    {
        List<CatalogItemPriceBook__c> objs = (List<CatalogItemPriceBook__c>)items;
        Set<Id> catalogItemIds = new Set<Id>();
        for(CatalogItemPriceBook__c o : objs)
        {
            catalogItemIds.add(o.Catalog_Item__c);
        }

        List<CatalogItemPriceBook__c> dirtyItems = new List<CatalogItemPriceBook__c>();
        Set<Id> dirtyCatalogItemIds = new Set<Id>();

        for(CatalogItemPriceBook__c o : [SELECT Id, Catalog_Item__c FROM CatalogItemPriceBook__c WHERE IsDeleted=false AND Catalog_Item__c IN :catalogItemIds])
        {
            if(dirtyCatalogItemIds.contains(o.Catalog_Item__c)) continue;

            o.IsDirty__c = true;
            dirtyItems.add(o);
            dirtyCatalogItemIds.add(o.Catalog_Item__c);
        }
        if(!dirtyCatalogItemIds.isEmpty())
        {
            update dirtyItems;
            if(!System.isBatch() && !System.isFuture()) 
            {
                CatalogItemPriceBookBatcher.ScheduleRefreshPriceBookIndex(0);
            }
        }

        
    }
    
}