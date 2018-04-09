public class CatalogItemPriceBookIndexBatchable extends FXBatchableBase
{
    public CatalogItemPriceBookIndexBatchable()
    {
        String ns = StringUtility.FXNamespace(); 
        soqlQuery = String.format('SELECT {0}Catalog_Item__c, {0}Price_Book__c FROM {0}Price_Book_Item__c WHERE IsDeleted=false ORDER BY {0}Catalog_Item__c, {0}Price_Book__c', 
            new String[]{ns});        
    }
    public override Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(soqlQuery);
    }

    public override void execute(Database.BatchableContext BC, List<sObject> scope)
    {   
         CatalogItemPriceBookHandler.CreateCatalogItemPriceBook((List<Price_Book_Item__c>)scope);
    } 
    
    public override void finish(Database.BatchableContext BC)
    {  
        CatalogItemPriceBookBatcher.ScheduleRefreshPriceBookIndex(0);
    }
}