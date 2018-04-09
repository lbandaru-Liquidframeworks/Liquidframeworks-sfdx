public class EquipmentPlanningHandler 
{
    public static String EnableExtendedPricingColumnName
    {
        get { return 'Enable_Extended_Pricing__c';}
    }

    public static String EnableExtendedPricingColumnNameLowercase
    {
        get { return 'enable_extended_pricing__c';}
    }

    public static Boolean HasColumnEnableExtendedPricing
    {
        get
        {
            if(EnableExtendedPricingFlag<0)
            {
                EnableExtendedPricingFlag = Job__c.sObjectType.getDescribe().fields.getMap().keySet().contains(EnableExtendedPricingColumnNameLowercase)? 1 : 0;
            }
            return EnableExtendedPricingFlag==1;
        }
    }
    Static Integer EnableExtendedPricingFlag = -1;

    public static void ValidateSourcePriceBook(List<Equipment_Planning__c> items, Map<Id, Equipment_Planning__c> oldmap)
    {
        Set<Id> jobIds = new Set<Id>();
        Set<Id> priceBookItemIds = new Set<Id>();

        List<Equipment_Planning__c> itemsOfInterest = new List<Equipment_Planning__c>();
        for(Equipment_Planning__c o : items)
        {
            if(String.isBlank(o.Job__c) || String.isBlank(o.Price_Book_Item__c)) continue;
            
            if(oldmap!=null)
            {
                Equipment_Planning__c prev = oldmap.get(o.Id);
                if(o.Job__c == prev.Job__c && o.Price_Book_Item__c == prev.Price_Book_Item__c) continue;
            }
            itemsOfInterest.add(o);    
            jobIds.add(o.Job__c);
            priceBookItemIds.add(o.Price_Book_Item__c);
        }
        if(itemsOfInterest.isEmpty()) return;
        
        //System.debug('itemsOfInterest size='+ itemsOfInterest.size());

        String extendedPricingCol = HasColumnEnableExtendedPricing? (', ' + EnableExtendedPricingColumnName): '';
        String soql = String.format('SELECT Id, {0}Price_Book__c {1} FROM {0}Job__c WHERE IsDeleted=false', 
            new String[]{StringUtility.FXNamespace(), extendedPricingCol });

        Map<Id, Job__c> jobMap = new Map<Id, Job__c>((List<Job__c>)Database.query(soql));      

        Map<Id, Id> parentPriceBookMap = new Map<Id, Id>();
        if(HasColumnEnableExtendedPricing)
        {
            for(Price_Book__c p : [SELECT Id, Parent_Price_Book__c FROM Price_Book__c WHERE IsDeleted=false AND Is_Active__c=true])
            {
                if(String.isBlank(p.Parent_Price_Book__c)) continue;
                parentPriceBookMap.put(p.Id, p.Parent_Price_Book__c);
            }
        }

        List<Price_Book_Item__c> pbItems = [SELECT Id, Catalog_Item__c, Price_Book__c, CatalogItemPriceBook__c FROM Price_Book_Item__c WHERE IsDeleted=false AND Price_Book__r.Is_Active__c=true AND Id IN :priceBookItemIds];
        Set<Id> catalogItemIds = new Set<Id>();
        for(Price_Book_Item__c o : pbItems)
        {
            catalogItemIds.add(o.Catalog_Item__c);
        }
        Map<Id, Price_Book_Item__c> equipPlanningPriceBookItemMap = new Map<Id, Price_Book_Item__c>(pbItems);

        Map<String, Set<Id>> catalogItemPriceBookItemMap = new Map<String, Set<Id>>();
        for(Price_Book_Item__c o : [SELECT Id, Catalog_Item__c, Price_Book__c, CatalogItemPriceBook__c FROM Price_Book_Item__c WHERE IsDeleted=false AND Price_Book__r.Is_Active__c=true  AND Catalog_Item__c IN : catalogItemIds])
        {
            if(!catalogItemPriceBookItemMap.containsKey(o.CatalogItemPriceBook__c))
            {
                catalogItemPriceBookItemMap.put(o.CatalogItemPriceBook__c, new Set<Id>());
            }
            catalogItemPriceBookItemMap.get(o.CatalogItemPriceBook__c).add(o.Id);

        }


        Map<Id, Price_Book_Item__c> pbiMap = new Map<Id, Price_Book_Item__c> ([SELECT Id, Catalog_Item__c, Price_Book__c, Price_Book__r.Parent_Price_Book__c FROM Price_Book_Item__c WHERE IsDeleted=false AND Id IN :priceBookItemIds]);

        for(Equipment_Planning__c o : itemsOfInterest)
        {
            
            Job__c job = jobMap.get(o.Job__c);
            if(job.Price_Book__c == pbiMap.get(o.Price_Book_Item__c).Price_Book__c) continue;

            Id jobId = o.Job__c;
           
            //System.debug('extendedPricing='+ extendedPricing);
            if(!HasColumnEnableExtendedPricing || !Boolean.valueOf(job.get(EnableExtendedPricingColumnName)))
            {
                o.addError('Price Book Item must be from the Job\'s Price Book.');             
            }
            else
            {                  
                Price_Book_Item__c pbi = equipPlanningPriceBookItemMap.get(o.Price_Book_Item__c);
                String key = pbi.CatalogItemPriceBook__c;
                Id priceBookId = jobMap.get(jobId).Price_Book__c;
                Boolean isGood = false;

                while(!String.isBlank(priceBookId))
                {
                    String catalogItemPriceBookIndex = String.valueOf(pbi.Catalog_Item__c) + String.valueOf(priceBookId);
                    if(catalogItemPriceBookItemMap.containsKey(catalogItemPriceBookIndex))                      
                    {
                        isGood = catalogItemPriceBookItemMap.get(catalogItemPriceBookIndex).contains(pbi.Id);
                        break;
                    }   
                    priceBookId = parentPriceBookMap.containsKey(priceBookId)? parentPriceBookMap.get(priceBookId) : null;
                }

                if(!isGood)
                {
                    o.addError('Price Book Item must be from the Job\'s Price Book or the nearest active upper level Price Book.');
                }               
            }
        }
        
    }
    
}