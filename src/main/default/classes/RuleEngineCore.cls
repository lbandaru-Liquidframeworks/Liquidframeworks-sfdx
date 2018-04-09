public class RuleEngineCore
{
    public static Boolean IsSuspended()
    {
        FX_Settings__c s = FX_Settings__c.getInstance(UserInfo.getUserId());
        return s.SuspendRuleEngine__c == true;
    }
    
    public static void Suspend()
    {
        FX_Settings__c s = FX_Settings__c.getInstance(UserInfo.getUserId());
        s.SuspendRuleEngine__c = true;
        Database.upsert(s, false);
    }
    public static void Activate()
    {
        FX_Settings__c s = FX_Settings__c.getInstance(UserInfo.getUserId());
        s.SuspendRuleEngine__c = false;
        Database.upsert(s, false);
    }   
    
    public static Boolean IsActive()
    {
        return !IsSuspended();
    }
    
    
    public static Boolean RuleEngineInProgress {get;set;}   

     
    public enum RuleActionType {PriceBookRequired, Required, Recommended, Disallowed}
    
    public static void Execute(Set<Id> tktIds, Boolean skipRecommendedRuleAction)
    { 
        try
        {
            RuleEngineInProgress =true;
            ExecuteInternal(tktIds, skipRecommendedRuleAction);
            RunTicketItemRulesOnTickets(tktIds, skipRecommendedRuleAction);
        }
        catch(Exception ex)
        {
            throw ex;
        }
        finally
        {
            RuleEngineInProgress =false;
        }
    }

    public static void ExecuteOnTicketItems(Set<Id> tktItemsIds, Boolean skipRecommendedRuleAction)
    { 
        try
        {            
            RuleEngineInProgress =true;
            RunTicketItemRules(tktItemsIds, skipRecommendedRuleAction);
        }
        catch(Exception ex)
        {
            throw ex;
        }
        finally
        {
            RuleEngineInProgress =false;
        }
    }

   
    @TestVisible
    static void RunTicketItemRulesOnTickets(Set<Id> tktIds, Boolean skipRecommendedRuleAction)
    {
         Map<Id, Ticket_Item__c> tktItems = new Map<Id, Ticket_Item__c>([SELECT Id, Price_Book_Item__c, Ticket__c,  Auto_Added__c, Rule_Required_Item__c, PBI_Required_Item__c,
             (SELECT Id, Price_Book_Item__c, Ticket__c, Auto_Added__c, Rule_Required_Item__c, PBI_Required_Item__c FROM Ticket_Items__r ORDER BY Auto_Added__c ASC)
             FROM Ticket_Item__c 
             WHERE Ticket__c IN :tktIds AND Ticket__r.Sync__c = false]);
        RunTicketItemRules(tktItems, skipRecommendedRuleAction);
    }

    

    @TestVisible
    static void RunTicketItemRules(Set<Id> tktItemIds, Boolean skipRecommendedRuleAction)
    {
        Map<Id, Ticket_Item__c> tktItems = new Map<Id, Ticket_Item__c>([SELECT Id, Price_Book_Item__c, Ticket__c, Auto_Added__c, Rule_Required_Item__c, PBI_Required_Item__c,
             (SELECT Id, Price_Book_Item__c, Ticket__c, Auto_Added__c, Rule_Required_Item__c, PBI_Required_Item__c FROM Ticket_Items__r ORDER BY Auto_Added__c ASC)
             FROM Ticket_Item__c 
             WHERE Id IN :tktItemIds AND Ticket__r.Sync__c = false ORDER BY Auto_Added__c ASC]);

        RunTicketItemRules(tktItems, skipRecommendedRuleAction);

    }

    static Ticket_Item__c CreateTicketItem(Id tktId, Price_Book_Item__c  pbi)
    {
        RecordTypeInfo recordInfo = null;

        String recordTypeName = pbi.Ticket_Item_Record_Type__c;
        recordInfo = String.isBlank(recordTypeName)? null: Schema.SObjectType.Ticket_Item__c.getRecordTypeInfosByName().get(recordTypeName);
     
        Ticket_Item__c ti =  (recordInfo != null) ? (Ticket_Item__c)Ticket_Item__c.sObjectType.newSObject(recordInfo.getRecordTypeId(), true) : (Ticket_Item__c)Ticket_Item__c.sObjectType.newSObject();  
     
        ti.Ticket__c = tktId;
        ti.Price_Book_Item__c = pbi.Id;
        ti.SyncID__c = StringUtility.newGuid();
        return ti;
    }

    @TestVisible
    static void RunTicketItemRules(Map<Id, Ticket_Item__c> tktItems, Boolean skipRecommendedRuleAction)
    {  
       
        if(tktItems.isEmpty()) return;
        Set<Id> priceBookItemIds = new Set<Id>();
        Set<Id> tktItemIds = tktItems.keySet();

        Map<Id, Set<Id>> pbiToTktItems = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> tiChildItems = new Map<Id, Set<Id>>();
        Map<String, Ticket_Item__c> childTktItems = new Map<String, Ticket_Item__c>();
        Map<String, Ticket_Item__c> ruleRequiredTktItems = new Map<String, Ticket_Item__c>();

        for(Ticket_Item__c ti : tktItems.values())
        {
            priceBookItemIds.add(ti.Price_Book_Item__c);
            if(!pbiToTktItems.containsKey(ti.Price_Book_Item__c))
            {
                pbiToTktItems.put(ti.Price_Book_Item__c, new Set<Id>());
            }
            pbiToTktItems.get(ti.Price_Book_Item__c).add(ti.Id);

            if(!ti.Ticket_Items__r.isEmpty())
            {                
                for(Ticket_Item__c c : ti.Ticket_Items__r)
                {                    
                    priceBookItemIds.add(c.Price_Book_Item__c);

                    String tktItemKey = String.valueOf(ti.Id) + String.valueOf(c.Price_Book_Item__c);
                    childTktItems.put(tktItemKey, c);
                    if(c.Auto_Added__c == true && c.Rule_Required_Item__c == true && c.PBI_Required_Item__c != true)
                    {
                        ruleRequiredTktItems.put(tktItemKey, c);
                    }
                }
            }
        }        

        List<Price_Book_Rule__c> rules = skipRecommendedRuleAction? [SELECT Id, Price_Book__c, Price_Book_Item__c, Criteria__c, CriteriaStack__c, CriteriaQueryFields__c, 
                (SELECT Id, Price_Book_Item__c, Type__c FROM Rule_Actions__r WHERE IsDeleted=false AND IsActive__c=true AND Type__c!='Recommended')
                FROM Price_Book_Rule__c 
                WHERE IsDeleted=false AND Active_Actions__c>0 AND IsActive__c=true AND Price_Book_Item__c IN :priceBookItemIds AND Applies_To__c INCLUDES ('Ticket__c') ]
            :
            [SELECT Id, Price_Book__c, Price_Book_Item__c, Criteria__c, CriteriaStack__c, CriteriaQueryFields__c,
                (SELECT Id, Price_Book_Item__c, Type__c FROM Rule_Actions__r WHERE IsDeleted=false AND IsActive__c=true)
                FROM Price_Book_Rule__c 
                WHERE IsDeleted=false AND Active_Actions__c>0 AND IsActive__c=true AND Price_Book_Item__c IN :priceBookItemIds AND Applies_To__c INCLUDES ('Ticket__c')];

        //System.debug('rules count =' + rules.size());
        Set<Id> pbiIdsFromRules = new Set<Id>();

        for(Price_Book_Rule__c r: rules)
        {
            pbiIdsFromRules.add(r.Price_Book_Item__c);

            for(Price_Book_Rule_Action__c a : r.Rule_Actions__r)
            {                
                pbiIdsFromRules.add(a.Price_Book_Item__c);
            }
        }

        Map<Id, Price_Book_Item__c> priceBookItemsLookup = 
            new Map<Id, Price_Book_Item__c>(
                [SELECT Id, Ticket_Item_Record_Type__c
                FROM Price_Book_Item__c WHERE Id IN :pbiIdsFromRules]);

        if(rules.isEmpty()) return;

        String ns = StringUtility.FXNamespace();


        String tktItemSoql = GetTicketItemSoql(rules, 'tktItemIds');
        Map<Id, List<Ticket_Item__c>> tktItemsForRuleEval = new Map<Id, List<Ticket_Item__c>>();

        Map<Id, List<Id>> ruleApplicable = new Map<Id, List<Id>>();   
        
        for(Ticket_Item__c ti : Database.query(tktItemSoql))
        {
            Id pli = ti.Price_Book_Item__c;
            if(!tktItemsForRuleEval.containsKey(pli))
            {
                tktItemsForRuleEval.put(pli, new List<Ticket_Item__c>());
            }
            tktItemsForRuleEval.get(pli).add(ti);
        }

        for(Price_Book_Rule__c r: rules)
        {
            if(String.isBlank(r.CriteriaStack__c)) continue;

            Id pli = r.Price_Book_Item__c;
            for(TIcket_Item__c ti : tktItemsForRuleEval.get(pli))
            {
                if(!RuleExpression.Eval(r.CriteriaStack__c, ti)) continue;
                if(!ruleApplicable.containsKey(r.Id))
                {
                    ruleApplicable.put(r.Id, new List<Id>());
                }
                ruleApplicable.get(r.Id).add(ti.Id);
            }
        }           
        
        Map<Id, Price_Book_Rule__c> ruleMap = new Map<Id, Price_Book_Rule__c>(rules);

        List<Ticket_Item__c> newItems = new List<Ticket_Item__c>();
        List<Ticket_Item__c> updateItems = new List<Ticket_Item__c>();
        List<TIcket_Item__c> disallowedItems = new List<Ticket_Item__c>();
        
        Map<String, Ticket_Item__c> newChildTktItemsLookup = new Map<String, Ticket_Item__c>();

        for(Id ruleId : ruleApplicable.keySet())
        {
            Price_Book_Rule__c rule = ruleMap.get(ruleId);
            List<Id> parentTktItemIds = ruleApplicable.get(ruleId);

            for(Price_Book_Rule_Action__c a : rule.Rule_Actions__r)
            {                
                Id pbi = a.Price_Book_Item__c;
                for(Id parentId : parentTktItemIds)
                {     
                    //Ticket_Item__c p = tktItems.get(parentId);
                    Ticket_Item__c tktItem = tktItems.get(parentId);
                    String childItemKey = String.valueOf(tktItem.Id) + String.valueOf(pbi);

                    if(a.Type__c == 'Disallowed')
                    {
                        if(newChildTktItemsLookup.containsKey(childItemKey))
                        {
                            newChildTktItemsLookup.remove(childItemKey);
                        }
                        else if(childTktItems.containsKey(childItemKey))
                        {
                            disallowedItems.add(childTktItems.get(childItemKey));
                            if(ruleRequiredTktItems.containsKey(childItemKey))
                            {
                                ruleRequiredTktItems.remove(childItemKey);
                            } 
                        }
                    }
                    else
                    {  
                        if(newChildTktItemsLookup.containsKey(childItemKey)) continue;
                        
                        if(childTktItems.containsKey(childItemKey))
                        {
                            Ticket_Item__c childItem = childTktItems.get(childItemKey);
                            if(childItem.Auto_Added__c != true) 
                            {
                                childItem.Auto_Added__c = true;
                                childItem.Rule_Required_Item__c = (a.Type__c =='Required');
                                updateItems.add(childItem);
                            }   
                            if(ruleRequiredTktItems.containsKey(childItemKey))
                            {
                                ruleRequiredTktItems.remove(childItemKey);
                            }
                            continue;
                        }                        

                        Price_Book_Item__c pbiObj = priceBookItemsLookup.get(pbi);
                        Ticket_Item__c ti = CreateTicketItem(tktItem.Ticket__c, pbiObj);

                        ti.Parent_Ticket_Item__c = parentId;
                        ti.Auto_Added__c = true;
                        ti.Rule_Required_Item__c = (a.Type__c =='Required');
                        newItems.add(ti);
                        newChildTktItemsLookup.put(childItemKey, ti);
                    }                                           
                } 
            }
        }
        //System.debug('RunTicketItemRules childItems size=' + newItems.size());
        insert newItems;
        if(!updateItems.isEmpty()) update updateItems;
        if(!ruleRequiredTktItems.isEmpty())
        {
            disallowedItems.addAll(ruleRequiredTktItems.values());
        }
        delete disallowedItems;

    }
    
    
     @TestVisible
    static void EnforceTicketItemRules_DisallowedItems(List<Ticket_Item__c> tktItems)
    {         
        if(tktItems==null || tktItems.isEmpty()) return;
        Set<Id> parentTktItemIds = new Set<Id>();
        Map<String, Ticket_Item__c> childItemsLookup = new Map<String, Ticket_Item__c>();
        Set<Id> childItemPriceBookItemIds = new Set<Id>();
        List<Ticket_Item__c> itemsOfInterest = new List<Ticket_Item__c>();
        for(Ticket_Item__c ti : tktItems)
        {
            if(ti.Auto_Added__c == true || String.isBlank(ti.Parent_Ticket_Item__c)) continue;
            parentTktItemIds.add(ti.Parent_Ticket_Item__c);
            itemsOfInterest.add(ti);
        }
        if(itemsOfInterest.isEmpty()) return;

        Map<Id, Ticket_Item__c> parentTktItems =
            new Map<Id, Ticket_Item__c>([SELECT Id, Price_Book_Item__c FROM Ticket_Item__c WHERE Id IN :parentTktItemIds AND IsDeleted=false]);

        for(Ticket_Item__c ti : itemsOfInterest)
        {
            String key = String.valueOf(ti.Parent_Ticket_Item__c) 
                + String.valueOf(parentTktItems.get(ti.Parent_Ticket_Item__c).Price_Book_Item__c)
                + String.valueOf(ti.Price_Book_Item__c);
            childItemsLookup.put(key, ti);
            childItemPriceBookItemIds.add(ti.Price_Book_Item__c);
        }

        Set<Id> rulePriceBookItemIds = new Set<Id>();
        for(Ticket_Item__c ti: parentTktItems.values())
        {
            rulePriceBookItemIds.add(ti.Price_Book_Item__c);
        }        

        List<Price_Book_Rule__c> rules = [SELECT Id, Name, Price_Book__c, Criteria__c, CriteriaStack__c, CriteriaQueryFields__c, 
                Price_Book_Item__c, 
                (SELECT Id, Price_Book_Item__c FROM Rule_Actions__r 
                    WHERE IsDeleted=false AND Type__c = 'Disallowed' AND Price_Book_Item__c IN :childItemPriceBookItemIds)
            FROM Price_Book_Rule__c 
            WHERE IsDeleted=false AND Price_Book_Item__c IN :rulePriceBookItemIds AND Active_Actions__c>0 AND Applies_To__c INCLUDES ('Ticket__c')];

     

        if(rules.isEmpty()) return;

        String ns = StringUtility.FXNamespace(); 

        Map<Id, List<Ticket_Item__c>> dbTicketItems = GetTicketItems(rules, parentTktItemIds);    

        Map<Id, Set<Id>> ruleApplicable = new Map<Id, Set<Id>>();  
        Map<String, String> disallowRuleActionInfo = new Map<String, String>();      
        for(Price_Book_Rule__c r: rules)
        {
            if(String.isBlank(r.CriteriaStack__c)) continue;
            
            String msg = 'Disallowed by Rule - ' + r.Name;

            Id pbId = r.Price_Book__c;            
            String ruleStack = r.CriteriaStack__c;
            for(Ticket_Item__c ti : dbTicketItems.get(pbId))
            {
                if(!RuleExpression.Eval(ruleStack, ti)) continue;
                String key = String.valueOf(ti.Id) + String.valueOf(ti.Price_Book_Item__c);
                for(Price_Book_Rule_Action__c action : r.Rule_Actions__r)
                {
                    String itemKey = key + String.valueOf(action.Price_Book_Item__c);

                    String itemMsg = disallowRuleActionInfo.containsKey(itemKey)? disallowRuleActionInfo.get(itemKey) + '; ' + msg : msg;
                    disallowRuleActionInfo.put(itemKey, itemMsg);
                } 
               
            }
            
        }
        for(String key : disallowRuleActionInfo.keySet())
        {
            if(!childItemsLookup.containsKey(key)) continue;
            childItemsLookup.get(key).addError(disallowRuleActionInfo.get(key));
        }
    }


    static void ExecuteInternal(Set<Id> tktIds, Boolean skipRecommendedRuleAction)
    {    
        
        if(IsActive()!= true) return;       
        
        List<Ticket__c> tickets = [SELECT Id, Job__r.Price_Book__c, Status__c, Status__r.Read_Only_Apps__c, (SELECT Id, Price_Book_Item__c, Auto_Added__c, Rule_Required_Item__c, SyncID__c FROM Ticket_Items__r ORDER BY Auto_Added__c ASC) FROM Ticket__c WHERE Id IN :tktIds];       

        Map<Id, Id> tktPriceBookLookup = new Map<Id, Id>();
        Map<Id, Set<Id>> priceBookToTickets = new Map<Id, Set<Id>>();
        Set<Id> priceBookIds = new Set<Id>();

        for(Ticket__c t: tickets)
        {
            if(!String.isEmpty(t.Status__c) && !String.isEmpty(t.Status__r.Read_Only_Apps__c) && t.Status__r.Read_Only_Apps__c.contains('Console')) continue;
            Id priceBookId = t.Job__r.Price_Book__c;
            tktPriceBookLookup.put(t.Id, priceBookId);
            priceBookIds.add(priceBookId);
            if(!priceBookToTickets.containsKey(priceBookId))
            {
                priceBookToTickets.put(priceBookId, new Set<Id>());
            }
            priceBookToTickets.get(priceBookId).add(t.Id);
        }

        //Tickets are all in readyOnly status, no need to run RuleEngine
        if(priceBookToTickets.isEmpty()) return;

        Map<Id, Price_Book__c>  pbWithRequiredItems = new Map<Id, Price_Book__c>([SELECT Id, Name, (SELECT Id, Parent_Price_Book_Item__c,Requires_Parent_Item__c FROM Price_Book_Items__r WHERE Required_Item__c=true AND Requires_Parent_Item__c=false ORDER BY Parent_Price_Book_Item__c) FROM Price_Book__c WHERE Id IN :priceBookIds]);

       
        List<Price_Book_Rule__c> rules = skipRecommendedRuleAction? 
            [SELECT Id, Price_Book__c, Criteria__c, CriteriaStack__c, CriteriaQueryFields__c, Price_Book_Item__c, (SELECT Id, Price_Book_Item__c, Type__c FROM Rule_Actions__r WHERE IsActive__c=true AND Type__c!='Recommended') FROM Price_Book_Rule__c WHERE IsActive__c=true AND Active_Actions__c>0 AND Price_Book__c IN :priceBookIds AND Applies_To__c INCLUDES ('Ticket__c')]
            :[SELECT Id, Price_Book__c, Criteria__c, CriteriaStack__c, CriteriaQueryFields__c,Price_Book_Item__c, (SELECT Id, Price_Book_Item__c, Type__c FROM Rule_Actions__r WHERE IsActive__c=true) FROM Price_Book_Rule__c WHERE IsActive__c=true AND Active_Actions__c>0 AND Price_Book__c IN :priceBookIds AND Applies_To__c INCLUDES ('Ticket__c')];
     
        

        Map<Id, List<Price_Book_Rule__c>> pbRulesLookup = new Map<Id, List<Price_Book_Rule__c>>();

        for(Price_Book_Rule__c r: rules)
        {
            //skip TicketItem rules : r.Price_Book_Item__c != null 
            if(r.Price_Book_Item__c != null || r.Rule_Actions__r.isEmpty()) continue;
            if(!pbRulesLookup.containsKey(r.Price_Book__c))
            {
                pbRulesLookup.put(r.Price_Book__c, new List<Price_Book_Rule__c>());
            }
            pbRulesLookup.get(r.Price_Book__c).add(r);
        }

        Map<Id, TicketSnapshot> tktSnapshots = BuildTicketSnapshot(priceBookToTickets, pbWithRequiredItems, pbRulesLookup);

        List<Ticket_Item__c> itemsToDelete = new List<Ticket_Item__c>(); 

        Map<Id, Set<Id>> mapItemsOnTicket = new Map<Id, Set<Id>>();

        //Ticket.Id + Price_Book_Item as key
        Map<String, Ticket_Item__c> tktItemsLookup = new Map<String, Ticket_Item__c>();

        Map<Id, String> priceBookItemToTicketItemSyncID = new Map<Id, String>();

        for(Ticket__c t: tickets)
        {            
            if(!tktSnapshots.containsKey(t.Id)) continue;
            
            TicketSnapshot snapshot = tktSnapshots.get(t.Id);

            mapItemsOnTicket.put(t.Id, new Set<Id>());
            for(Ticket_Item__c ti : t.Ticket_Items__r)
            {
                if(snapshot.IsDisallowed(ti.Price_Book_Item__c) || (ti.Rule_Required_Item__c == true && !snapshot.IsRuleRequired(ti.Price_Book_Item__c)))
                {
                    itemsToDelete.add(ti);                                  
                }   
                else
                {
                    mapItemsOnTicket.get(t.Id).add(ti.Price_Book_Item__c);

                    tktItemsLookup.put(String.valueOf(t.Id) + ti.Price_Book_Item__c, ti);

                    priceBookItemToTicketItemSyncID.put(ti.Price_Book_Item__c, ti.SyncID__c);
                }           
            }
        }
        delete itemsToDelete;

        List<Ticket_Item__c> itemsToInsert = new List<Ticket_Item__c>();
        Set<Id> priceBookItemIds = new Set<Id>();

        for(TicketSnapshot t : tktSnapshots.values())
        {           
            priceBookItemIds.addAll(t.RuleItems.keySet());     
            priceBookItemIds.addAll(t.PriceBookRequiredItems);
        }       
        Map<Id, Price_Book_Item__c> priceBookItems = new Map<Id, Price_Book_Item__c>([SELECT Id, Requires_Parent_Item__c, Parent_Price_Book_Item__c, Ticket_Item_Record_Type__c, (SELECT Id, Requires_Parent_Item__c, Parent_Price_Book_Item__c, Ticket_Item_Record_Type__c FROM Child_Price_Book_Items__r) FROM Price_Book_Item__c WHERE Id IN :priceBookItemIds]);
    

        BuildTickets(tktSnapshots, priceBookItems, mapItemsOnTicket, priceBookItemToTicketItemSyncID, tktItemsLookup);
    }
      

    static void BuildTickets(Map<Id, TicketSnapshot> tktSnapshots, Map<Id, Price_Book_Item__c> priceBookItems,
     Map<Id, Set<Id>> mapItemsOnTicket, Map<Id, String> priceBookItemToTicketItemSyncID,
     Map<String, Ticket_Item__c> dbTktItemLookup)
    { 
        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();
        List<Ticket_Item__c> childTktItems = new List<Ticket_Item__c>();

        Map<Id, Ticket_Item__c> tktItemsUpdate = new Map<Id, Ticket_Item__c>();

        Map<String, Ticket_Item__c> newTktItems = new Map<String, Ticket_Item__c>();

        for(Id tktId : tktSnapshots.keySet())
        {
            TicketSnapshot snapshot = tktSnapshots.get(tktId);
            Set<Id> itemsOnTicket = mapItemsOnTicket.get(tktId);
            Map<Id, Price_Book_Item__c> itemsNeedParant = new Map<Id, Price_Book_Item__c>();

            for(Id pbiId : snapshot.RuleItems.keySet())
            {
                String tktItemKey = String.valueOf(tktId) + pbiId;
                if(itemsOnTicket.contains(pbiId)) 
                {
                    //System.debug('get here items on Ticket');
                    if(dbTktItemLookup.containsKey(tktItemKey))
                    {
                        
                        Ticket_Item__c dbTktItem = dbTktItemLookup.get(tktItemKey);
                        if(dbTktItem.Auto_Added__c == false || snapshot.RuleItems.get(pbiId) == RuleActionType.Required)
                        {
                            dbTktItem.Auto_Added__c = true;
                            dbTktItem.Rule_Required_Item__c = snapshot.RuleItems.get(pbiId) == RuleActionType.Required;
                            tktItemsUpdate.put(dbTktItem.Id, dbTktItem);
                        }                        
                    }
                    else if(newTktItems.containsKey(tktItemKey))
                    {
                        Ticket_Item__c tktItem = newTktItems.get(tktItemKey);
                        tktItem.Auto_Added__c = true;
                        if(snapshot.RuleItems.get(pbiId) == RuleActionType.Required)
                        {
                            tktItem.Rule_Required_Item__c = true;
                        }                       
                    }
                    continue;
                }
                Price_Book_Item__c pbi = priceBookItems.get(pbiId);
                if(pbi.Parent_Price_Book_Item__c!=null) //if(pbi.Requires_Parent_Item__c == true)
                {
                    itemsNeedParant.put(pbi.Id, pbi);
                    continue;
                }
                else
                {
                    Ticket_Item__c ti = CreateTicketItem(tktId, pbi);
                    ti.Auto_Added__c = true;
                    ti.Rule_Required_Item__c = snapshot.RuleItems.get(pbiId) == RuleActionType.Required;

                    itemsOnTicket.add(pbiId);
                    tktItems.add(ti);
                    newTktItems.put(tktItemKey, ti);

                    priceBookItemToTicketItemSyncID.put(pbiId, ti.SyncID__c);
                    for(Price_Book_Item__c c : pbi.Child_Price_Book_Items__r)
                    {
                        if(snapshot.DisallowedItems.contains(c.Id)) continue;

                        String childTktItemKey = String.valueOf(tktId) + c.Id;

                        Ticket_Item__c tiChild = CreateTicketItem(tktId, c);
                        tiChild.Parent_Ticket_Item__r = new Ticket_Item__c(SyncID__c = ti.SyncID__c);

                        itemsOnTicket.add(c.Id); 
                        priceBookItemToTicketItemSyncID.put(pbiId, tiChild.SyncID__c);
                        childTktItems.add(tiChild);
                        newTktItems.put(childTktItemKey, tiChild);
                    }
                }
            }
            for(Price_Book_Item__c c: itemsNeedParant.values())
            {
                if(!itemsOnTicket.contains(c.Parent_Price_Book_Item__c)) continue;

                String key = String.valueOf(tktId) + c.Id;

                if(newTktItems.containsKey(key)) 
                {
                    Ticket_Item__c tiChild = newTktItems.get(key);
                    tiChild.Auto_Added__c = true;
                    if(snapshot.RuleItems.get(c.Id) == RuleActionType.Required)
                    {
                        tiChild.Rule_Required_Item__c = true;
                    }
                }
                else
                {
                    Ticket_Item__c tiChild = CreateTicketItem(tktId, c);
                    if(itemsOnTicket.contains(c.Parent_Price_Book_Item__c))           
                    {
                        tiChild.Parent_Ticket_Item__r = new Ticket_Item__c(SyncID__c = priceBookItemToTicketItemSyncID.get(c.Parent_Price_Book_Item__c));
                    }

                    tiChild.Auto_Added__c = true;
                    tiChild.Rule_Required_Item__c = snapshot.RuleItems.get(c.Id) == RuleActionType.Required;

                    itemsOnTicket.add(c.Id);
                    tktItems.add(tiChild);
                    newTktItems.put(key, tiChild);
                }                
            }
        }
        if(!tktItemsUpdate.isEmpty())
        {
            update tktItemsUpdate.values();    
        }
        insert tktItems;
        insert childTktItems;

    }
    
    
    public static Map<Id, TicketSnapshot> BuildTicketSnapshot(Map<Id, Set<Id>> priceBookTickets, 
        Map<Id, Price_Book__c> pbWithRequiredItems, 
        Map<Id, List<Price_Book_Rule__c>> pbRules)
    {
        Map<Id, TicketSnapshot>  tktSnapshots = new Map<Id, TicketSnapshot>();

         String ns = UtilityGetNamespace.CurrentNamespace();
        for(Id priceBookId : pbWithRequiredItems.keySet())
        {
            Set<Id> tkts = priceBookTickets.get(priceBookId);
            Price_Book__c pb = pbWithRequiredItems.get(priceBookId);
            Set<Id> priceBookItemIds = new Map<Id, Price_Book_Item__c>(pb.Price_Book_Items__r).keySet();

            for(Id tktId: tkts)
            {
                if(!tktSnapshots.containsKey(tktId))
                {
                    tktSnapshots.put(tktId, new TicketSnapshot(tktId));
                }
                tktSnapshots.get(tktId).AddRuleItems(priceBookItemIds, RuleActionType.PriceBookRequired);
            }           
        }

        Set<Id> allTktIds = new Set<Id>();
        for(Id pbId : priceBookTickets.keySet())
        {
            allTktIds.addAll(priceBookTickets.get(pbId));
        }

        List<Price_Book_Rule__c> allRules = new List<Price_Book_Rule__c>();
        for(Id pbId: pbRules.keySet())
        {
            allRules.addAll(pbRules.get(pbId));
        }

        Map<Id, List<Ticket__c>> ticketsByPriceBooks = GetTickets(allRules, allTktIds);

        for(Id priceBookId : pbRules.keySet())
        {
            List<Price_Book_Rule__c> rules = pbRules.get(priceBookId);
            Set<Id> tktIds = priceBookTickets.get(priceBookId);
            for(Price_Book_Rule__c r: rules)
            {       
                if(String.isBlank(r.CriteriaStack__c)) continue;
                         
                List<Ticket__c> ruleTkts = EvalRule(ticketsByPriceBooks.get(r.Price_Book__c), r.CriteriaStack__c);

                if(ruleTkts.isEmpty()) continue;

                for(Ticket__c t: ruleTkts)
                {
                    if(!tktSnapshots.containsKey(t.Id))
                    {
                        tktSnapshots.put(t.Id, new TicketSnapshot(t.Id));
                    }   
                    tktSnapshots.get(t.Id).AddRuleItems(r.Rule_Actions__r);                      
                }
            }
        }
        return tktSnapshots;
    }

    static List<Ticket__c> EvalRule(List<Ticket__c> tkts, String ruleStack)
    {
        List<Ticket__c> results = new List<Ticket__c>();
        for(Ticket__c t: tkts)
        {
            if(RuleExpression.Eval(ruleStack, t))
            {
                results.add(t);
            }
        }
        return results;

    }

    static Set<String> GetQueryFields(List<Price_Book_Rule__c> rules)
    {
        Set<String> queryFields = new Set<String>();
        for(Price_Book_Rule__c r: rules)
        {
            if(String.isBlank(r.CriteriaQueryFields__c)) continue;
            queryFields.addAll(r.CriteriaQueryFields__c.split(','));
        }
        return queryFields;
    }

    static Set<String> GetTicketQueryFields(List<Price_Book_Rule__c> rules)
    {
        Set<String> queryFields = GetQueryFields(rules);
        String ns = StringUtility.FXNamespace();
        queryFields.add( ns + 'Job__r.' + ns + 'Price_Book__c');
        return queryFields;
    }

    static String GetTicketSoql(List<Price_Book_Rule__c> rules, String pNameTktIds)
    {
        Set<String> queryFields = GetQueryFields(rules);
        String ns = StringUtility.FXNamespace();
        queryFields.add( ns + 'Job__r.' + ns + 'Price_Book__c');
        return String.format('SELECT {1} FROM {0}Ticket__c WHERE Id IN :{2}', 
            new String[]{ns, 
                String.join(new List<String>(queryFields), ','),
                pNameTktIds});
    }

    static String GetTicketItemSoql(List<Price_Book_Rule__c> rules, String pNameTktItemIds)
    {
        Set<String> queryFields = GetQueryFields(rules);
        String ns = StringUtility.FXNamespace();
        queryFields.add( ns + 'Ticket__r.' + ns + 'Job__r.' + ns + 'Price_Book__c');
        queryFields.add(ns + 'Price_Book_Item__c');
        queryFields.add(ns + 'Ticket__c');
        return String.format('SELECT {1} FROM {0}Ticket_Item__c WHERE Id IN :{2}', 
            new String[]{ns, 
                String.join(new List<String>(queryFields), ','),
                pNameTktItemIds});
    }


   static Map<Id, List<Ticket__c>> GetTickets(List<Price_Book_Rule__c> rules, Set<Id> tktIds)
   {
        String tktSoql = GetTicketSoql(rules, 'tktIds');
        Map<Id, List<Ticket__c>> tickets = new Map<Id, List<Ticket__c>>();
        for(Ticket__c t : Database.query(tktSoql))
        {
            Ticket__c tkt = (Ticket__c)t;
            Id pbId  = tkt.Job__r.Price_Book__c;
            if(!tickets.containsKey(pbId))
            {
                tickets.put(pbId, new List<TIcket__c>());
            }
            tickets.get(pbId).add(tkt);
        }
        return tickets;
   }


   static Map<Id, List<Ticket_Item__c>> GetTicketItems(List<Price_Book_Rule__c> rules, Set<Id> tktItemIds)
   {
        String tktSoql = GetTicketItemSoql(rules, 'tktItemIds');
        Map<Id, List<Ticket_Item__c>> tktItems = new Map<Id, List<Ticket_Item__c>>();
        for(Ticket_Item__c obj : Database.query(tktSoql))
        {
            Ticket_Item__c ti = (Ticket_Item__c)obj;
            Id pbId  = ti.Ticket__r.Job__r.Price_Book__c;
            if(!tktItems.containsKey(pbId))
            {
                tktItems.put(pbId, new List<Ticket_Item__c>());
            }
            tktItems.get(pbId).add(ti);
        }
        return tktItems;
   }

    public static Map<Id, Set<Id>> GetDisallowedPriceBookItemsForTickets(Set<Id> tktIds, Set<Id> priceBookItemIds,  Map<String, String> disallowedRuleNames)
    {  
        Map<Id, Set<Id>> tktDisallowItems = new Map<Id, Set<Id>>();
        List<Price_Book_Rule_Action__c> actions = [SELECT Id, Price_Book_Item__c, Price_Book_Rule__c, Price_Book_Rule__r.Price_Book__c, Price_Book_Rule__r.Criteria__c, Price_Book_Rule__r.CriteriaStack__c, Price_Book_Rule__r.CriteriaQueryFields__c, Price_Book_Rule__r.Name FROM Price_Book_Rule_Action__c WHERE IsActive__c=true AND Type__c='Disallowed' AND Price_Book_Rule__r.IsActive__c=true AND Price_Book_Item__c IN :priceBookItemIds AND Price_Book_Rule__r.Applies_To__c INCLUDES ('Ticket__c') AND Price_Book_Rule__r.Price_Book_Item__c=null];
        
        if(actions.isEmpty()) return tktDisallowItems;        

        List<Price_Book_Rule__c> rules = new List<Price_Book_Rule__c>();
        Map<Id, List<Price_Book_Rule_Action__c>> ruleActions = new Map<Id, List<Price_Book_Rule_Action__c>>();
        for(Price_Book_Rule_Action__c a : actions)
        {
            rules.add(a.Price_Book_Rule__r);
            if(!ruleActions.containsKey(a.Price_Book_Rule__c))
            {
                ruleActions.put(a.Price_Book_Rule__c, new List<Price_Book_Rule_Action__c>());
            }
            ruleActions.get(a.Price_Book_Rule__c).add(a);
        }


        Map<Id, List<Ticket__c>> tickets = GetTickets(rules, tktIds);
        for(Price_Book_Rule__c r : rules)
        {
            Id pbId = r.Price_Book__c;
            List<Ticket__c> ruleTkts = EvalRule(tickets.get(pbId), r.CriteriaStack__c);
            if(ruleTkts.isEmpty()) continue;

            String ruleMsg = 'Item is disallowed by Rule "' + r.Name + '".';
            for(Ticket__c t : ruleTkts)
            {
                if(!tktDisallowItems.containsKey(t.Id))     
                {
                    tktDisallowItems.put(t.Id, new Set<Id>());
                }
                for(Price_Book_Rule_Action__c a : ruleActions.get(r.Id))
                {
                    String key = String.valueOf(t.Id) + a.Price_Book_Item__c;

                    tktDisallowItems.get(t.Id).add(a.Price_Book_Item__c);
                    disallowedRuleNames.put(key, ruleMsg);
                }               
            }
        }
        return tktDisallowItems;
    }


    public static void ValdiateDisallowRules(List<Ticket_Item__c> tktItems)
    {
        Set<Id> priceBookItemIds = new Set<Id>();
        Set<Id> tktIds = new Set<Id>();
        Map<String, List<Ticket_Item__c>> tktItemLookup = new Map<String, List<Ticket_Item__c>>();
        
        List<Ticket_Item__c> manaullChildItems = new List<Ticket_Item__c>();
      
        for(Ticket_Item__c ti: tktItems)
        {      
            if(ti.Auto_Added__c == true) continue;
            tktIds.add(ti.Ticket__c);
            
            if(!String.isBlank(ti.Parent_Ticket_Item__c))
            {
                manaullChildItems.add(ti);
            }
            priceBookItemIds.add(ti.Price_Book_Item__c);   
            String tktItemKey= ti.Ticket__c + '' + ti.Price_Book_Item__c;
            if(!tktItemLookup.containsKey(tktItemKey))      
            {
                tktItemLookup.put(tktItemKey, new List<Ticket_Item__c>());
            }
            tktItemLookup.get(tktItemKey).add(ti);
        }

        if(!tktIds.isEmpty())
        {
            Map<String, String> ruleMsgs = new Map<String, String>();
    
            Map<Id, Set<Id>> disallowedPriceBookItems = GetDisallowedPriceBookItemsForTickets(tktIds, priceBookItemIds, ruleMsgs);
    
            for(Ticket_Item__c ti : tktItems)
            {
                String key = String.valueOf(ti.Ticket__c) + ti.Price_Book_Item__c;
                if(!ruleMsgs.containsKey(key)) continue;
                ti.addError(ruleMsgs.get(key));
            }
        }
        if(!manaullChildItems.isEmpty())
        {
            EnforceTicketItemRules_DisallowedItems(manaullChildItems);
        }   
    }

    public static Map<String, Set<String>> GetPriceBookRuleCriteriaFields(Set<Id> priceBooks)
    {      
        Map<String, Set<String>> ruleFields = new Map<String, Set<String>>();
        if(priceBooks==null || priceBooks.isEmpty()) return ruleFields;

        List<Price_Book_Rule__c> rules = [SELECT Id, Price_Book__c, Price_Book_Item__c, Criteria__c FROM Price_Book_Rule__c WHERE IsDeleted=false AND Active_Actions__c>0 AND IsActive__c=true AND Price_Book__c IN :priceBooks AND Applies_To__c INCLUDES ('Ticket__c')];
       
        
        String ns = UtilityGetNamespace.CurrentNamespace();

        /* ***********************
        //DO NOT REMOVE THIS SESSION 
        //RUN THIS at workbench to see the matching groups
        // A: str with _  :    ([a-z0-9]+(_)?)*[a-z0-9]+
        // NS: namespace  -> NS__
        // FK: (NS)?A__r.  ->  {NS}([a-z0-9]+(_)?)*[a-z0-9]+__r\\.
        // FD: fieldName ((FK)*)(({NS}A)+__c)
        //              or ((FK)+)(({NS}A)+)    


        //Pattern myPattern = Pattern.compile('((([a-zA-Z][a-zA-Z0-9]*(_)?[a-zA-Z0-9]+__)?[a-zA-Z][a-zA-Z0-9]*(_)?[a-zA-Z0-9]+__r\\.)*)(([a-zA-Z][a-zA-Z0-9]*(_)?[a-zA-Z0-9]+__)?[a-zA-Z][a-zA-Z0-9]*(_)?[a-zA-Z0-9]+__c)|((([a-zA-Z][a-zA-Z0-9]*(_)?[a-zA-Z0-9]+__)?[a-zA-Z][a-zA-Z0-9]*(_)?[a-zA-Z0-9]+__r\\.)+)(([a-zA-Z][a-zA-Z0-9]*(_)?[a-zA-Z0-9]+__)?[a-zA-Z][a-zA-Z0-9]*(_)?[a-zA-Z0-9]+)'); 
        
        String ns = UtilityGetNamespace.CurrentNamespace();
        String nsregex = String.isBlank(ns)? '(FX5__)?' : '(' + ns + ')?';      


        String reg = '(?i)(((({NS}[a-z0-9_]+__r\\.)*)({NS}[a-z0-9_]+__c))|((({NS}[a-z0-9_]+__r\\.)+([a-z0-9_]+))))';      

        Pattern fieldPattern = Pattern.compile(reg.replace('{NS}', nsregex));

        String[] strs = new String[]{'FX5__Job__r.FX5__Ticket__r.Deep__c>120 AND FX5__Height__c=40', 'Job__r.Office__r.Name=\'Lubbock\''};
        for(String str : strs)
        {
            System.debug('source Str = ' + str );
            System.debug('===========================');
            Matcher myMatcher = fieldPattern.matcher(str);
            while(myMatcher.find()) 
            {    
                String matchStr = myMatcher.group(); 
                System.debug('found : ' + matchStr);
                List<String> fieldItems = matchStr.split('\\.', 0);
                String f = fieldItems.get(fieldItems.size()-1);
                
                fieldItems.remove(fieldItems.size()-1);

                String fkChain = String.join(fieldItems, '.');
                System.debug('FK chain:' + fkChain);
                System.debug('field:' + f);

            }
        }
        **************************/        

        //the first half of the pattern is to find custom fields ending with __c and the second half is to accomodate standard field as Job__r.Office__r.Name
        String nsregex = String.isBlank(ns)? '(FX5__)?' : '(' + ns + ')?';      

        String reg = '(?i)(((({NS}[a-z0-9_]+__r\\.)*)({NS}[a-z0-9_]+__c))|((({NS}[a-z0-9_]+__r\\.)+([a-z0-9_]+))))';      

        Pattern fieldPattern = Pattern.compile(reg.replace('{NS}', nsregex));
        
        for(Price_Book_Rule__c r : rules)
        {   
            
            Boolean isTktItemRule = r.Price_Book_Item__c!=null;

            Id pb = r.Price_Book__c;
            String jobKey = 'job' + pb;
            String tktKey = 'tkt' + pb;
            String tktItemKey = 'tktitem' + pb;
            
            String c = PriceBookRuleHandler.ParseRuleCriterion(r.Criteria__c);
            
            Matcher fieldMatcher = fieldPattern.matcher(c);
                

            String ownerKey = '';

            while(fieldMatcher.find()) 
            {
                String matchStr = fieldMatcher.group(); 
                List<String> fkFields = matchStr.split('\\.', 0);
                String f = fkFields.get(fkFields.size()-1);

                if(fkFields.size()>1)                
                {
                    for(Integer i=0; i<fkFields.size()-1; i++)
                    {
                        ownerKey = '';
                        String fk = fkFields.get(i);
                        String field = fkFields.get(i+1).replace('__r', '__c');
                       
                        if(fk.endsWith('Job__r'))
                        {
                            ownerKey = jobKey;
                        }
                        else if(fk.endsWith('Ticket__r'))
                        {
                            ownerKey = tktKey;
                        }
                        else if(fk.endsWith('Ticket_Item__r'))
                        {
                            ownerKey = tktItemKey;
                        }
                        else
                        {
                            ownerKey = isTktItemRule? tktItemKey : tktKey;                               
                            field = fk.replace('__r', '__c');
                        }
                        if(!ruleFields.containsKey(ownerKey))
                        {
                            ruleFields.put(ownerKey, new Set<String>());
                        }
                        if(!String.isBlank(ownerKey))
                        {
                            ruleFields.get(ownerKey).add(field);
                        }

                        System.debug(ownerKey + ' ****************** ' + field);

                    }
                }
                else
                {
                    ownerKey = isTktItemRule? tktItemKey : tktKey;  
                    if(!ruleFields.containsKey(ownerKey))
                    {
                        ruleFields.put(ownerKey, new Set<String>());
                    }
                    ruleFields.get(ownerKey).add(fkFields.get(0));
                     System.debug(ownerKey + ' ****************** ' + fkFields.get(0));
                }
            }  
                    
        }
        return ruleFields;
    }

    
    
    public static List<Id> GetDisallowedPriceBookItems(String objId)
    {
        if(objId.startsWith(Ticket__c.sObjectType.getDescribe().getKeyPrefix()))
        {
            return GetDisallowedPriceBookItemsForTicket(objId);
        }
        
        if(objId.startsWith(Ticket_Item__c.sObjectType.getDescribe().getKeyPrefix()))
        {
            return GetDisallowedPriceBookItemsForTicketItem(objId);
        }
        return new List<Id>();
    }
    
    @TestVisible
    static List<Id> GetDisallowedPriceBookItemsForTicket(String tktID)
    {
        Ticket__c tkt = [SELECT Id, Job__r.Price_Book__c FROM Ticket__c WHERE Id=:tktID];
        Id pbId = tkt.Job__r.Price_Book__c;
        List<Price_Book_Rule__c> rules = [SELECT Id, Price_Book__c, Criteria__c, CriteriaStack__c, CriteriaQueryFields__c, (SELECT Id, Price_Book_Item__c FROM Rule_Actions__r WHERE IsActive__c=true AND Type__c='Disallowed' AND IsDeleted=false) FROM Price_Book_Rule__c WHERE IsDeleted=false AND Price_Book_Item__c=null AND Active_Actions__c>0 AND Price_Book__c=:pbId AND Applies_To__c INCLUDES ('Ticket__c')];

        Set<Id> pbItemIds = new Set<Id>();

        String ns = UtilityGetNamespace.CurrentNamespace();
        Set<Id> tktIds = new Set<Id>();
        tktIds.add(tkt.Id);

        Map<Id, List<Ticket__c>> ticketsByPriceBooks = GetTickets(rules, tktIds);

        for(Price_Book_Rule__c r : rules)
        {     
            if(r.Rule_Actions__r.isEmpty() ||String.isBlank(r.Criteria__c))  continue;  
            
            List<Ticket__c> ruleTkts = EvalRule(ticketsByPriceBooks.get(r.Price_Book__c), r.CriteriaStack__c);
              //[SELECT Id, (SELECT Id FROM Tickets__r WHERE Job__r.Distance__c>150) FROM Job__c WHERE Id='a0IF000000O1n9I'];
            if(ruleTkts.isEmpty()) continue;

            for(Price_Book_Rule_Action__c a : r.Rule_Actions__r)
            {
                pbItemIds.add(a.Price_Book_Item__c);
            }
        }
        return new List<Id>(pbItemIds);
    }
    
    @TestVisible
    static List<Id> GetDisallowedPriceBookItemsForTicketItem(String objId)
    {
        List<Ticket_Item__c> tktItems = [SELECT Id, Price_Book_Item__c FROM Ticket_Item__c WHERE Id=:objId AND IsDeleted=false];
        
        //System.debug('tktItems.size()=' + tktItems.size());
        if(tktItems.isEmpty()) return null;

        Ticket_Item__c tktItem = tktItems.get(0);

        Id priceBookItemId = tktItem.Price_Book_Item__c;

        List<Price_Book_Rule__c> rules = [SELECT Id, Name, Price_Book__c, Criteria__c, CriteriaStack__c, CriteriaQueryFields__c, 
                Price_Book_Item__c, 
                (SELECT Id, Price_Book_Item__c FROM Rule_Actions__r WHERE IsDeleted=false AND Type__c = 'Disallowed')
            FROM Price_Book_Rule__c 
            WHERE IsDeleted=false AND Active_Actions__c>0 AND Price_Book_Item__c=:priceBookItemId AND Applies_To__c INCLUDES ('Ticket__c')];

        Set<Id> tktItemIds = new Set<Id>();
        tktItemIds.add(objId);

        tktItems = GetTicketItems(rules, tktItemIds).values()[0];
        tktItem  = tktItems.get(0);
        
        Set<Id> disallowedItemIds = new Set<Id>();     
        String soql = '';
        String ns = UtilityGetNamespace.CurrentNamespace();

        for(Price_Book_Rule__c r: rules)
        {
            if(String.isBlank(r.CriteriaStack__c) || !RuleExpression.Eval(r.CriteriaStack__c, tktItem)) continue;
            for(Price_Book_Rule_Action__c action : r.Rule_Actions__r)
            {
                disallowedItemIds.add(action.Price_Book_Item__c);
            }   
        }
        return new List<Id>(disallowedItemIds);
    }

    

    class TicketSnapshot
    {   
        public TicketSnapshot(Id tktId0)
        {
            TktId = tktId0;
            DisallowedItems = new Set<Id>();
            RuleItems = new Map<Id, RuleActionType>();
            PriceBookRequiredItems = new Set<Id>();
        }
        public Id TktId {get; set;}
        public Set<Id> DisallowedItems {get; set;}
        public Map<Id, RuleActionType> RuleItems {get; set;}
        public Set<Id> PriceBookRequiredItems {get;set;}

        public Boolean IsDisallowed(Id priceBookItemId)
        {
            return DisallowedItems.contains(priceBookItemId);
        }

        public Boolean IsRuleRequired(Id priceBookItemId)
        {
            return RuleItems.containsKey(priceBookItemId) && RuleItems.get(priceBookItemId) == RuleActionType.Required;
        }

        public void AddRuleItems(Set<Id> pbItems, RuleActionType type)
        {
            for(Id pbi: pbItems)
            {
                AddRuleItem(pbi, type);
            }
        }

        public void AddRuleItem(Id priceBookItemId, RuleActionType type)
        {
            if(type == RuleActionType.Disallowed)
            {
                DisallowedItems.add(priceBookItemId);
                if(RuleItems.containsKey(priceBookItemId))
                {
                    RuleItems.remove(priceBookItemId);
                }
                if(PriceBookRequiredItems.contains(priceBookItemId))
                {
                    PriceBookRequiredItems.remove(priceBookItemId);
                }
            }
            else if(!DisallowedItems.contains(priceBookItemId))
            {
                if(type == RuleActionType.PriceBookRequired)
                {
                    PriceBookRequiredItems.add(priceBookItemId);
                    RuleItems.put(priceBookItemId, RuleActionType.Required);
                }
                else if(!RuleItems.containsKey(priceBookItemId) || type == RuleActionType.Required)
                {
                    RuleItems.put(priceBookItemId, type);
                }               
            }
        }

        public void AddRuleItems(List<Price_Book_Rule_Action__c> items)
        {
            for(Price_Book_Rule_Action__c item: items)
            {
                RuleActionType type = RuleActionType.Required;              
                if(item.Type__c == 'Recommended')
                {
                    type = RuleActionType.Recommended;  
                }
                else if(item.Type__c == 'Disallowed')
                {
                    type = RuleActionType.Disallowed;   
                }
                AddRuleItem(item.Price_Book_Item__c, type);
            }
        }
    }    
}
