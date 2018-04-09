public class RuleEngineDispatcher
{
    public static void RunDisallowedRules(List<Quote_Item__c> items)
    {
        if(RuleEngineCore.IsSuspended() || RuleEngineCore.RuleEngineInProgress == true) return;
        RuleEngineForQuote.ValdiateDisallowRules(items);
    }

    public static void Run(List<Quote_Item__c> items, Boolean isUpdate)
    {
        ExecuteOnQuoteItems(new Map<Id, Quote_Item__c>(items).keySet(), isUpdate);
    } 

    public static void Run(List<Quote__c> objs)
    {
        if(RuleEngineCore.IsSuspended()) return;

        Set<Id> objIds = new Set<Id>();
        
        for(Quote__c o: objs)
        {
            if(o.Created_in_Mobile__c == true) continue;
            objIds.add(o.Id);
        }
        Execute(objIds, false);
    }
    
    public static void OnQuoteUpdate(List<Quote__c> objs, Map<Id, Quote__c> oldMap)
    {
        if(RuleEngineCore.IsSuspended() || RuleEngineCore.RuleEngineInProgress == true) return;
            
        Map<Id, Status__c> qStatuses = new Map<Id, Status__c>([SELECT Id, Sync__c FROM Status__c WHERE IsDeleted=false AND Sync__c=false AND SObject__c='Quote__c' AND Read_Only_Apps__c EXCLUDES ('Console')]);
        
        List<Quote__c> ojbsOfInterest = new List<Quote__c>();
         Set<Id> priceBookIds = new Set<Id>();
         
        for(Quote__c o: objs)
        {
            if(String.isBlank(o.Status__c) || !qStatuses.containsKey(o.Status__c)) continue;
            ojbsOfInterest.add(o);         
            priceBookIds.add(o.Price_Book__c);
            
        }    
        if(ojbsOfInterest.isEmpty()) return;

        Map<String, Set<String>> criteriaFields = RuleEngineForQuote.GetPriceBookRuleCriteriaFields(priceBookIds);
        // System.debug('criteriaFields:'  + criteriaFields);

        Set<Id> objWithRuleRelatedUpdate = new Set<Id>();
        
        for(Quote__c o: ojbsOfInterest)
        {
            Quote__c prev = oldMap.get(o.Id);
            
            String fKey = 'quote' + o.Price_Book__c;
            if(!criteriaFields.containsKey(fKey)) continue;
            for(String f : criteriaFields.get(fKey))
            {
                if(o.get(f) != prev.get(f))
                {
                    objWithRuleRelatedUpdate.add(o.Id);
                    break;
                }
            }
        }  

        //System.debug('run rule engine for tkts upon Ticket update:' + tktIds);
        if(!objWithRuleRelatedUpdate.isEmpty())
        {
           Execute(objWithRuleRelatedUpdate, true);           
        }
    }
    
    
    static void Execute(Set<Id> objIds, Boolean skipRecommendedItems)
    {

        if(objIds==null || objIds.isEmpty()) return;

        if(objIds.size()==1|| Test.isRunningTest())
        {
            RuleEngineForQuote.Execute(objIds, skipRecommendedItems);
        }
        else
        {
            System.enqueueJob(new RuleEngineQueueable(objIds, skipRecommendedItems));
        }
    }

    static void ExecuteOnQuoteItems(Set<Id> objIds, Boolean skipRecommendedItems)
    {
        if(objIds==null || objIds.isEmpty()) return;
        

        if(RuleEngineCore.IsSuspended() || RuleEngineCore.RuleEngineInProgress == true) return;       

        if(objIds.size()==1 || Test.isRunningTest())
        {
            RuleEngineForQuote.ExecuteOnQuoteItems(objIds, skipRecommendedItems);
        }
        else
        {
            System.enqueueJob(new RuleEngineQueueable(objIds, skipRecommendedItems));
        }
    }
    
}