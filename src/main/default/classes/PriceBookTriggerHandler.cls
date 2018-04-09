public class PriceBookTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> items)
    {
        super.OnBeforeInsert(items);
        PriceBookHandler.ResetGlobalPriceBooks((List<Price_Book__c>)items); 
        PriceBookHandler.EnforceCPQLicense((List<Price_Book__c>)items);  
        
    }

    public override void OnBeforeUpdate(List<sObject> items, Map<Id, sObject> oldmap)
    {   
        super.OnBeforeUpdate(items, oldmap);
        PriceBookHandler.ResetGlobalPriceBooks((List<Price_Book__c>)items);
        PriceBookHandler.EnforceCPQLicense((List<Price_Book__c>)items);   
    }
    
    public override void OnAfterUpdate(List<sObject> items, Map<Id, sObject> oldmap)
    { 
        List<Price_Book__c> pbs = (List<Price_Book__c>)items;
        Map<Id, Price_Book__c> pbMap = (Map<Id, Price_Book__c>)oldmap;
        
        Set<Id> itemsOfInterest = new Set<Id>();

     
        for(Price_Book__c pb : pbs)
        {
            Price_Book__c old = pbMap.get(pb.Id);
            if(pb.Is_Active__c != old.Is_Active__c)
            {
                itemsOfInterest.add(pb.Id);
            }
        }
        if(!itemsOfInterest.isEmpty())
        {  
            CatalogItemPriceBookBatcher.FlagIsDirty(itemsOfInterest);
        }
    }
}