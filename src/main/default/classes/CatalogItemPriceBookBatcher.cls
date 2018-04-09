public class CatalogItemPriceBookBatcher extends FXBatchableBase implements Database.Stateful
{    
    Set<Id> priceBookIds { get; set; }   
    Set<Id> catalogItemIds {get;set;}
    
    Map<Id, String> catalogItemPriceBookIndex {get;set;}

    List<CatalogItemPriceBook__c> catalogItemPriceBookEntries {get;set;}

    Set<Id> dirtyCatalogItemIds {get;set;}

    @TestVisible
    enum OperType {  
        ProcessCatalogItemPriceBook,
        FlagIsDirty
    }

    OperType opType { get; set; }

    static Integer catalogItemBatchSize = 1000;         
    
    public static void FlagIsDirty(Set<Id> priceBookIds)
    { 
        String soql = String.format('SELECT Id, {0}IsDirty__c, {0}Catalog_Item__c, {0}Price_Book__c FROM {0}CatalogItemPriceBook__c WHERE IsDeleted=false AND {0}Price_Book__c IN :priceBookIds AND {0}IsDirty__c=false',
                    new String[]{StringUtility.FXNamespace()});

        Integer rowCountLimit = Limits.getLimitDMLRows() - Limits.getDMLRows();
        String soqlQuery = soql + ' LIMIT ' + rowCountLimit;

        System.debug('FlagIsDirty soql=' + soqlQuery);

        List<CatalogItemPriceBook__c> items = (List<CatalogItemPriceBook__c>)Database.query(soqlQuery);

        System.debug('soql results count: ' + items.size());
        Set<Id> dirtyIds = new Set<Id>();
        List<CatalogItemPriceBook__c> itemsToUpdate = new List<CatalogItemPriceBook__c>();
        for(CatalogItemPriceBook__c o : items)
        {   
            if(dirtyIds.contains(o.Catalog_Item__c)) continue;
            o.IsDirty__c = true;            
            itemsToUpdate.add(o);
            dirtyIds.add(o.Catalog_Item__c);
        }
        if(!itemsToUpdate.isEmpty())
        {
            update itemsToUpdate;
        }

        if(items.size() == rowCountLimit)
        {
            CatalogItemPriceBookBatcher b = new CatalogItemPriceBookBatcher(soql, OperType.FlagIsDirty);
            b.priceBookIds = priceBookIds;
            Database.executeBatch(b); 
        }
        else
        {
            ScheduleRefreshPriceBookIndex(0);
        }
    }

    @TestVisible
    private CatalogItemPriceBookBatcher(String soql, OperType opt)
    {
        soqlQuery = soql;   
        opType = opt; 
        
        catalogItemPriceBookIndex = new Map<Id, String>();
        if(opt == OperType.FlagIsDirty)
        {
            dirtyCatalogItemIds = new Set<Id>();
        }
    }

    public static void ProcessCatalogItemPriceBook()
    {
        Database.executeBatch(new CatalogItemPriceBookBatcher());
    }

    public static void ScheduleRefreshPriceBookIndex(Integer delayInMintues)
    {
        Integer count = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE 'Refresh CatalogItem PriceBook Index%'];
        if(count==0)
        {
            count = [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name='CatalogItemPriceBookBatcher' AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')];
        }
        if(count !=0) 
        {
            System.debug('Either CatalogItemPriceBookBatcher is running or a Refresh CatalogItem PriceBook Index job has been scheduled.');
            return;
        }
        if(delayInMintues<=0)
        {
            Database.executeBatch(new CatalogItemPriceBookBatcher());
        }
        else
        {
           String jobName = 'Refresh CatalogItem PriceBook Index - ' + Datetime.now().getTime();
           System.scheduleBatch(new CatalogItemPriceBookBatcher(), jobName, delayInMintues); 
        }
    }
    
    public CatalogItemPriceBookBatcher()
    {
        opType = OperType.ProcessCatalogItemPriceBook;

        catalogItemPriceBookEntries = [SELECT Catalog_Item__c FROM CatalogItemPriceBook__c WHERE IsDeleted=false AND IsDirty__c = true ORDER BY Catalog_Item__c LIMIT :catalogItemBatchSize];

        catalogItemPriceBookIndex = new Map<Id, String>();
         
        catalogItemIds = new Set<Id>();
        for(CatalogItemPriceBook__c o : catalogItemPriceBookEntries)
        {
            catalogItemIds.add(o.Catalog_Item__c);
        }
        String ns = StringUtility.FXNamespace(); 

        String catalogItemFilter = String.format(' AND {0}Catalog_Item__c IN :catalogItemIds', new String[]{ns});

        soqlQuery =  String.format('SELECT {0}Price_Book__c, {0}Catalog_Item__c FROM {0}Price_Book_Item__c WHERE IsDeleted=false AND {0}Price_Book__r.{0}Is_Active__c=true {1} ORDER BY {0}Catalog_Item__c', 
                new String[]{ns, catalogItemFilter});        
    }
    

    public override Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(soqlQuery);
    }

    public override void execute(Database.BatchableContext BC, List<sObject> scope)
    {   
        if(opType == OperType.ProcessCatalogItemPriceBook)      
        {           
            List<Price_Book_Item__c> items = (List<Price_Book_Item__c>)scope;
            Set<Id> catalogItemIds = new Set<Id>();
            if(catalogItemPriceBookIndex == null)
            {
                catalogItemPriceBookIndex = new Map<Id, String>();

            }
            for(Price_Book_Item__c pbi : items)
            {
                if(catalogItemPriceBookIndex.containsKey(pbi.Catalog_Item__c)) continue;
                catalogItemIds.add(pbi.Catalog_Item__c);
            }
            
            for(Catalog_Item__c ci : [SELECT Id, (SELECT Price_Book__c FROM CatalogItemPriceBooks__r WHERE IsDeleted=false AND PriceBookIsActive__c=true) FROM Catalog_Item__c WHERE IsDeleted=false AND Id IN :catalogItemIds])
            {
                Set<Id> priceBookIds = new Set<Id>();
                for(CatalogItemPriceBook__c o : ci.CatalogItemPriceBooks__r)
                {
                    priceBookIds.add(o.Price_Book__c);
                }
                catalogItemPriceBookIndex.put(ci.Id, String.join(new List<Id>(priceBookIds), ','));
            }
            for(Price_Book_Item__c pbi : items)
            {
                pbi.Catalog_Price_Book_Index__c = catalogItemPriceBookIndex.get(pbi.Catalog_Item__c);
            }
            update items;
        }
        else if(opType == OperType.FlagIsDirty)
        {
            List<CatalogItemPriceBook__c> items = (List<CatalogItemPriceBook__c>)scope;
            List<CatalogItemPriceBook__c> dirtyItems = new List<CatalogItemPriceBook__c>();
            for(CatalogItemPriceBook__c o : items)
            {
                if(dirtyCatalogItemIds.contains(o.Catalog_Item__c)) continue;
                o.IsDirty__c = true;
                dirtyCatalogItemIds.add(o.Catalog_Item__c);
                dirtyItems.add(o);
            }
            if(!dirtyItems.isEmpty())
            {
                update dirtyItems;
            }
        }
    } 
    
    public override void finish(Database.BatchableContext BC)
    {       
        if(opType == OperType.FlagIsDirty)     
        {
            ScheduleRefreshPriceBookIndex(0);
        }            
        else if(opType == OperType.ProcessCatalogItemPriceBook)
        {
            for(CatalogItemPriceBook__c o: catalogItemPriceBookEntries)
            {
                o.IsDirty__c = false;
            }
            Database.update(catalogItemPriceBookEntries, false);
            if(catalogItemPriceBookEntries.size() == CatalogItemBatchSize)
            {
                Database.executeBatch(new CatalogItemPriceBookBatcher());
            }
        }      
    }     
}