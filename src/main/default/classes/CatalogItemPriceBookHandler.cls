public class CatalogItemPriceBookHandler
{       
    public static void SetDirtyFlagJointKey(List<CatalogItemPriceBook__c> items)
    {
        for(CatalogItemPriceBook__c o : items)
        {
            String key = GetJointKey(o);
            if(o.JointKey__c != key)
            {
                o.JointKey__c = key;
            }
            o.IsDirty__c = true;
        }
    }
    public static void CreateCatalogItemPriceBook(List<Price_Book_Item__c> items)
    {           
        List<CatalogItemPriceBook__c> objs = new List<CatalogItemPriceBook__c>();
        Set<String> keys = new Set<String>();
        for(Price_Book_Item__c pbi : items)
        {
            String key = GetJointKey(pbi);
            if(keys.contains(key)) continue;
            objs.add(new CatalogItemPriceBook__c(Catalog_Item__c = pbi.Catalog_Item__c, Price_Book__c = pbi.Price_Book__c, JointKey__c=key));
            keys.add(key);
        }
        if(!objs.isEmpty()){
            upsert objs JointKey__c;
        }
    }      

    public static void RefreshCatalogItemPriceBook(List<Price_Book_Item__c> items)
    {
        Set<String> jointKeys = new Set<String>();
        Set<Id> catalogItemIds = new Set<Id>();
        Set<Id> priceBookIds = new Set<Id>();

        for(Price_Book_Item__c pbi: items)
        {
            priceBookIds.add(pbi.Price_Book__c);            
            catalogItemIds.add(pbi.Catalog_Item__c);
            jointKeys.add(GetJointKey(pbi));
        }
        for(Price_Book_Item__c pbi: [SELECT Id, CatalogItemPriceBook__c FROM Price_Book_Item__c WHERE IsDeleted=false AND Price_Book__c IN :priceBookIds AND Catalog_Item__c IN :catalogItemIds])
        {
            jointKeys.remove(pbi.CatalogItemPriceBook__c);
        }
        if(!jointKeys.isEmpty())
        {
            delete [SELECT Id FROM CatalogItemPriceBook__c WHERE JointKey__c IN :jointKeys];
        }
    }

    public static String GetJointKey(Price_Book_Item__c o)
    {
        return String.valueOf(o.Catalog_Item__c) + String.valueOf(o.Price_Book__c);
    }

    public static String GetJointKey(CatalogItemPriceBook__c o)
    {
        return String.valueOf(o.Catalog_Item__c) + String.valueOf(o.Price_Book__c);
    }

}