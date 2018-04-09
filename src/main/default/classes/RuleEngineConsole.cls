public class RuleEngineConsole
{  
    public static void OnTicketItemBeforeInsert(List<Ticket_Item__c> tktItems)
    {
        if(RuleEngineCore.IsSuspended() || RuleEngineCore.RuleEngineInProgress == true) return;
        RuleEngineCore.ValdiateDisallowRules(tktItems);
        //Execute(new Map<Id, Ticket_Item__c>(tktItems).keySet(), false);
    }

    public static void OnTicketItemAfterInsert(List<Ticket_Item__c> tktItems)
    {
        //System.debug('***************** RuleEngineConsole.OnTicketItemAfterInsert');
        ExecuteOnTicketItems(new Map<Id, Ticket_Item__c>(tktItems).keySet(), false);
    }

    public static void OnTicketItemUpdate(List<Ticket_Item__c> tktItems)
    {   
        //System.debug('***************** RuleEngineConsole.OnTicketItemUpdate');
        ExecuteOnTicketItems(new Map<Id, Ticket_Item__c>(tktItems).keySet(), true);
    }


    public static void OnJobUpdate(List<Job__c> jobs, Map<Id, Job__c> oldMap)
    {
        if(RuleEngineCore.IsSuspended() || RuleEngineCore.RuleEngineInProgress == true) return;
        Set<Id> priceBookIds = new Set<Id>();
        for(Job__c j : jobs)
        {
            priceBookIds.add(j.Price_Book__c);
        }
        Map<String, Set<String>> criteriaFields = RuleEngineCore.GetPriceBookRuleCriteriaFields(priceBookIds);
        
        //System.debug('criteriaFields:'  + criteriaFields);

        Set<Id> jobIds = new Set<Id>();
        
        for(Job__c j : jobs)
        {
            Job__c prev = oldMap.get(j.Id);
            String fKey = 'job' + j.Price_Book__c;
            if(!criteriaFields.containsKey(fKey)) continue;
            for(String f : criteriaFields.get(fKey))
            {
                if(j.get(f) != prev.get(f))
                {
                    jobIds.add(j.Id);
                    break;
                }
            }
        }
        if(jobIds.isEmpty()) return;

        List<Ticket__c> tkts = [SELECT Id, Status__r.Read_Only_Apps__c FROM Ticket__c WHERE Job__c IN :jobIds AND Sync__c=false AND Status__c!=null];
        Set<Id> tktIds = new Set<Id>();
        for(Ticket__c t:tkts)
        {
            if(t.Status__c!=null && !String.isBlank(t.Status__r.Read_Only_Apps__c) && t.Status__r.Read_Only_Apps__c.contains('Console')) continue;
            tktIds.add(t.Id);            
        }
        //System.debug('run rule engine for tkts upon Job update:' + tktIds);
        Execute(tktIds, true);
    }
    public static void OnTicketInsert(List<Ticket__c> tickets)
    {
        if(RuleEngineCore.IsSuspended()) return;
        
        Set<Id> tktIds = new Set<Id>();
        
        for(Ticket__c t: tickets)
        {
            if(t.Created_in_Mobile__c == true) continue;
            tktIds.add(t.Id);
        }
        Execute(tktIds, false);
    }
    
    public static void OnTicketUpdate(List<Ticket__c> tickets, Map<Id, Ticket__c> oldMap)
    {
        if(RuleEngineCore.IsSuspended() || RuleEngineCore.RuleEngineInProgress == true) return;
        
        List<Ticket__c> tktsOfInterest = new List<Ticket__c>();
        
        Set<Id> tktIdsForRuleEngine = new Set<Id>();
        Set<Id> tktIds = new Set<Id>();
        Set<Id> jobIds = new Set<Id>();
        for(Ticket__c t: tickets)
        {
            if(t.Sync__c == true) continue;
            tktsOfInterest.add(t);
            jobIds.add(t.Job__c);
        }
        if(tktsOfInterest.isEmpty()) return;

        Map<Id, Id> jobPriceBookLookup = new Map<Id, Id>();
        List<Job__c> jobs = [SELECT Id, Price_Book__c FROM Job__c WHERE Id IN :jobIds];
        Set<Id> priceBookIds = new Set<Id>();
        for(Job__c j : jobs)
        {
            priceBookIds.add(j.Price_Book__c);
            jobPriceBookLookup.put(j.Id, j.Price_Book__c);
        }
        Map<String, Set<String>> criteriaFields = RuleEngineCore.GetPriceBookRuleCriteriaFields(priceBookIds);
        // System.debug('criteriaFields:'  + criteriaFields);

        for(Ticket__c t: tktsOfInterest)
        {
            Ticket__c prev = oldMap.get(t.Id);
            if(t.Sync__c != prev.Sync__c && t.Sync__c==false) 
            {
                tktIds.add(t.Id);
                continue;
            }
            
            String fKey = 'tkt' + jobPriceBookLookup.get(t.Job__c);
            if(!criteriaFields.containsKey(fKey)) continue;
            for(String f : criteriaFields.get(fKey))
            {
                if(t.get(f) != prev.get(f))
                {
                    tktIds.add(t.Id);
                    break;
                }
            }
        }  

        //System.debug('run rule engine for tkts upon Ticket update:' + tktIds);
        if(!tktIds.isEmpty())
        {
           Execute(tktIds, true);           
        }
    }
    
    static void Execute(Set<Id> objIds, Boolean skipRecommendedItems)
    {

        if(objIds==null || objIds.isEmpty()) return;

        //System.debug('Execute on objIds:' + objIds);

        if(objIds.size()==1)
        {
            RuleEngineCore.Execute(objIds, skipRecommendedItems);
        }
        else
        {
            System.enqueueJob(new RuleEngineQueueable(objIds, skipRecommendedItems));
        }
    }

    static void ExecuteOnTicketItems(Set<Id> objIds, Boolean skipRecommendedItems)
    {
        if(objIds==null || objIds.isEmpty()) return;
        
        //System.debug('objIds.size()=' + objIds.size());

        if(RuleEngineCore.IsSuspended() || RuleEngineCore.RuleEngineInProgress == true) return;       

        if(objIds.size()==1)
        {
            RuleEngineCore.ExecuteOnTicketItems(objIds, skipRecommendedItems);
        }
        else
        {
            System.enqueueJob(new RuleEngineQueueable(objIds, skipRecommendedItems));
        }
    }
}