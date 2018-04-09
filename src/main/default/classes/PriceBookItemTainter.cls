public class PriceBookItemTainter
{
    public static void TaintPriceBookItems(Set<Id> catalogItemIds)
    {
    	Integer rowCountLimit = Limits.getLimitDMLRows() - Limits.getDMLRows();
    	Integer itemCount = [SELECT COUNT() FROM Price_Book_Item__c WHERE IsDeleted=false AND Catalog_Item__c IN :catalogItemIds LIMIT :rowCountLimit];
       
        if(itemCount<rowCountLimit)
        {
        	update [SELECT Id FROM Price_Book_Item__c WHERE Catalog_Item__c IN :catalogItemIds];
        }
        else
        {
        	Database.executeBatch(new PriceBookItemBulkTainting(catalogItemIds));
        }
    }
}