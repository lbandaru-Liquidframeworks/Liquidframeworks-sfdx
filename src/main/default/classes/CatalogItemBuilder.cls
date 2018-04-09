public class CatalogItemBuilder
{
	public static void OnBeforeInsert(List<Catalog_Item__c> items)
	{
		CopyClassificationBreadcrumb(items);
        for(Catalog_Item__c ci : items)
        {
            ci.Name_Unique__c = ci.Name;
        }
	}

	public static void OnBeforeUpdate(List<Catalog_Item__c> items, Map<Id, Catalog_Item__c> oldMap)
	{
		List<Catalog_Item__c> actionItems = new List<Catalog_Item__c>();
		for(Catalog_Item__c ci : items)
		{
			if(ci.Classification__c != oldMap.get(ci.Id).Classification__c)
			{
				if(ci.Classification__c == null)
				{
					ci.Breadcrumb__c = null;
				}
				else
				{
					actionItems.add(ci);
				}
			}
			ci.Name_Unique__c = ci.Name;
		}
		if(!actionItems.isEmpty()) CopyClassificationBreadcrumb(actionItems);
	}

	public static void OnAfterUpdate(List<Catalog_Item__c> items, Map<Id, Catalog_Item__c> oldMap)
	{
		TaintPriceBookItems(items);
	}	

	public static void CopyClassificationBreadcrumb(List<Catalog_Item__c> items)
	{
		Set<Id> classificationIDs = new Set<Id>();
		List<Catalog_Item__c> actionItems = new List<Catalog_Item__c>();
		for(Catalog_Item__c ci : items)
		{
			if(ci.Classification__c != null)
			{
				classificationIDs.add(ci.Classification__c);
				actionItems.add(ci);
			}
		}
		if(!actionItems.isEmpty())
		{
			Map<Id, Classification__c> classificationLookup = new Map<Id, Classification__c>([SELECT Id, Breadcrumb__c FROM Classification__c  WHERE Id IN :classificationIDs]);
			for(Catalog_Item__c ci : actionItems)
			{
				ci.Breadcrumb__c = classificationLookup.get(ci.Classification__c).Breadcrumb__c;
			}
		}
	}

	public static void TaintPriceBookItems(List<Catalog_Item__c> items)
	{
		Set<Id> catalogItemIDs = new Map<Id, Catalog_Item__c>(items).keySet();
		PriceBookItemTainter.TaintPriceBookItems(catalogItemIDs);
		//PriceBookItemBulkTainting b= new PriceBookItemBulkTainting(catalogItemIDs);
		//Database.executeBatch(b, 200);	

	}
}