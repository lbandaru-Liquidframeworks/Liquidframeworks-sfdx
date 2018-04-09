public class PriceBookItemBulkTainting extends FXBatchableBase
{
    String query {get;set;}
    Set<Id> catalogItemIds {get; set;}
    
    public PriceBookItemBulkTainting()
    {
        this(null);
    }
    public PriceBookItemBulkTainting(Set<Id> paramCatalogItemIds)
    {
        catalogItemIds = paramCatalogItemIds;
        String ns = StringUtility.FXNamespace();
        String idFilter = (catalogItemIds==null ||catalogItemIds.isEmpty())? '' 
            : String.format(' AND {0}Catalog_Item__c IN :catalogItemIds', new String[]{ns});

        soqlQuery = String.format('SELECT Id FROM {0}Price_Book_Item__c WHERE IsDeleted=false {1}', 
            new String[]{ns, idFilter});
    }   

    public override Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(soqlQuery);
    }
 
    public override void execute(Database.BatchableContext BC, List<SObject> scope)
    {  
        update scope;
    }     
}