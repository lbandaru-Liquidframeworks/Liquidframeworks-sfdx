public class PriceBookItemTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> items)
    {
        PriceBookItemMangler.OnBeforeInsert((List<Price_Book_Item__c>)items);
    }
    
    public override void OnAfterInsert(List<sObject> items)
    {
        CatalogItemPriceBookHandler.CreateCatalogItemPriceBook((List<Price_Book_Item__c>)items);
    }
    
    public override void OnBeforeDelete(List<sObject> items)
    {
        PriceBookItemMangler.OnBeforeDelete((List<Price_Book_Item__c>)items);      
    }   

    public override void OnAfterDelete(List<sObject> items)
    {
        CatalogItemPriceBookHandler.RefreshCatalogItemPriceBook((List<Price_Book_Item__c>)items);   
    }   
}