public class RuleEngineForQuote
{    
    public static void Execute(Set<Id> quoteIds, Boolean skipRecommendedRuleAction)
    { 
        try
        {
            RuleEngineCore.RuleEngineInProgress = true;
            ExecuteInternal(quoteIds, skipRecommendedRuleAction);
            RunQuoteItemRulesOnQuotes(quoteIds, skipRecommendedRuleAction);
        }
        catch(Exception ex)
        {
            throw ex;
        }
        finally
        {
             RuleEngineCore.RuleEngineInProgress = false;
        }
    }

    public static void ExecuteOnQuoteItems(Set<Id> quoteItemsIds, Boolean skipRecommendedRuleAction)
    { 
        try
        {            
            RuleEngineCore.RuleEngineInProgress = true;
            RunQuoteItemRules(quoteItemsIds, skipRecommendedRuleAction);
        }
        catch(Exception ex)
        {
            throw ex;
        }
        finally
        {
            RuleEngineCore.RuleEngineInProgress = false;
        }
    }

   
    @TestVisible
    static void RunQuoteItemRulesOnQuotes(Set<Id> quoteIds, Boolean skipRecommendedRuleAction)
    {
         Map<Id, Quote_Item__c> quoteItems = new Map<Id, Quote_Item__c>([SELECT Id, Price_Book_Item__c, Quote__c,  Auto_Added__c, Rule_Required_Item__c, PBI_Required_Item__c,
             (SELECT Id, Price_Book_Item__c, Quote__c, Auto_Added__c, Rule_Required_Item__c, PBI_Required_Item__c FROM Quote_Items__r ORDER BY Auto_Added__c ASC)
             FROM Quote_Item__c 
             WHERE Quote__c IN :quoteIds]);
        RunQuoteItemRules(quoteItems, skipRecommendedRuleAction);
    }

    

    @TestVisible
    static void RunQuoteItemRules(Set<Id> quoteItemIds, Boolean skipRecommendedRuleAction)
    {
        Map<Id, Quote_Item__c> quoteItems = new Map<Id, Quote_Item__c>([SELECT Id, Price_Book_Item__c, Quote__c, Auto_Added__c, Rule_Required_Item__c, PBI_Required_Item__c,
             (SELECT Id, Price_Book_Item__c, Quote__c, Auto_Added__c, Rule_Required_Item__c, PBI_Required_Item__c FROM Quote_Items__r ORDER BY Auto_Added__c ASC)
             FROM Quote_Item__c 
             WHERE Id IN :quoteItemIds AND Quote__r.Status__r.Sync__c = false AND Quote__r.Status__r.Read_Only_Apps__c EXCLUDES ('Console') ORDER BY Auto_Added__c ASC] );

        RunQuoteItemRules(quoteItems, skipRecommendedRuleAction);

    }

    static Quote_Item__c CreateQuoteItem(Id quoteId, Price_Book_Item__c  pbi)
    {
        RecordTypeInfo recordInfo = null;

        String recordTypeName = pbi.Ticket_Item_Record_Type__c;
        recordInfo = String.isBlank(recordTypeName)? null: Schema.SObjectType.Quote_Item__c.getRecordTypeInfosByName().get(recordTypeName);
     
        Quote_Item__c ti =  (recordInfo != null) ? (Quote_Item__c)Quote_Item__c.sObjectType.newSObject(recordInfo.getRecordTypeId(), true) : (Quote_Item__c)Quote_Item__c.sObjectType.newSObject();  
     
        ti.Quote__c = quoteId;
        ti.Price_Book_Item__c = pbi.Id;
        ti.SyncID__c = StringUtility.newGuid();
        return ti;
    }

    @TestVisible
    static void RunQuoteItemRules(Map<Id, Quote_Item__c> quoteItems, Boolean skipRecommendedRuleAction)
    {         
       
        if(quoteItems.isEmpty()) return;
        Set<Id> priceBookItemIds = new Set<Id>();
        Set<Id> quoteItemIds = quoteItems.keySet();

        Map<Id, Set<Id>> pbiToquoteItems = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> tiChildItems = new Map<Id, Set<Id>>();
        Map<String, Quote_Item__c> childquoteItems = new Map<String, Quote_Item__c>();
        Map<String, Quote_Item__c> ruleRequiredquoteItems = new Map<String, Quote_Item__c>();

        for(Quote_Item__c ti : quoteItems.values())
        {
            priceBookItemIds.add(ti.Price_Book_Item__c);
            if(!pbiToquoteItems.containsKey(ti.Price_Book_Item__c))
            {
                pbiToquoteItems.put(ti.Price_Book_Item__c, new Set<Id>());
            }
            pbiToquoteItems.get(ti.Price_Book_Item__c).add(ti.Id);

            if(!ti.Quote_Items__r.isEmpty())
            {                
                for(Quote_Item__c c : ti.Quote_Items__r)
                {                    
                    priceBookItemIds.add(c.Price_Book_Item__c);

                    String quoteItemKey = String.valueOf(ti.Id) + String.valueOf(c.Price_Book_Item__c);
                    childquoteItems.put(quoteItemKey, c);
                    if(c.Auto_Added__c == true && c.Rule_Required_Item__c == true && c.PBI_Required_Item__c != true)
                    {
                        ruleRequiredquoteItems.put(quoteItemKey, c);
                    }
                }
            }
        }        

        List<Price_Book_Rule__c> rules = skipRecommendedRuleAction? [SELECT Id, Price_Book__c, Price_Book_Item__c, Criteria__c, CriteriaStack__c, CriteriaQueryFields__c, 
                (SELECT Id, Price_Book_Item__c, Type__c FROM Rule_Actions__r WHERE IsDeleted=false AND IsActive__c=true AND Type__c!='Recommended')
                FROM Price_Book_Rule__c 
                WHERE IsDeleted=false AND Active_Actions__c>0 AND IsActive__c=true AND Price_Book_Item__c IN :priceBookItemIds AND Applies_To__c INCLUDES ('Quote__c') ]
            :
            [SELECT Id, Price_Book__c, Price_Book_Item__c, Criteria__c, CriteriaStack__c, CriteriaQueryFields__c,
                (SELECT Id, Price_Book_Item__c, Type__c FROM Rule_Actions__r WHERE IsDeleted=false AND IsActive__c=true)
                FROM Price_Book_Rule__c 
                WHERE IsDeleted=false AND Active_Actions__c>0 AND IsActive__c=true AND Price_Book_Item__c IN :priceBookItemIds AND Applies_To__c INCLUDES ('Quote__c')];

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


        String quoteItemSoql = GetQuoteItemSoql(rules, 'quoteItemIds');
        Map<Id, List<Quote_Item__c>> quoteItemsForRuleEval = new Map<Id, List<Quote_Item__c>>();

        Map<Id, List<Id>> ruleApplicable = new Map<Id, List<Id>>();   
        
        for(Quote_Item__c ti : Database.query(quoteItemSoql))
        {
            Id pli = ti.Price_Book_Item__c;
            if(!quoteItemsForRuleEval.containsKey(pli))
            {
                quoteItemsForRuleEval.put(pli, new List<Quote_Item__c>());
            }
            quoteItemsForRuleEval.get(pli).add(ti);
        }

        for(Price_Book_Rule__c r: rules)
        {
            if(String.isBlank(r.CriteriaStack__c)) continue;

            Id pli = r.Price_Book_Item__c;
            for(Quote_Item__c ti : quoteItemsForRuleEval.get(pli))
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

        List<Quote_Item__c> newItems = new List<Quote_Item__c>();
        List<Quote_Item__c> updateItems = new List<Quote_Item__c>();
        List<Quote_Item__c> disallowedItems = new List<Quote_Item__c>();
        
        Map<String, Quote_Item__c> newChildquoteItemsLookup = new Map<String, Quote_Item__c>();

        for(Id ruleId : ruleApplicable.keySet())
        {
            Price_Book_Rule__c rule = ruleMap.get(ruleId);
            List<Id> parentquoteItemIds = ruleApplicable.get(ruleId);

            for(Price_Book_Rule_Action__c a : rule.Rule_Actions__r)
            {                
                Id pbi = a.Price_Book_Item__c;
                for(Id parentId : parentquoteItemIds)
                {     
                    //Quote_Item__c p = quoteItems.get(parentId);
                    Quote_Item__c quoteItem = quoteItems.get(parentId);
                    String childItemKey = String.valueOf(quoteItem.Id) + String.valueOf(pbi);

                    if(a.Type__c == 'Disallowed')
                    {
                        if(newChildquoteItemsLookup.containsKey(childItemKey))
                        {
                            newChildquoteItemsLookup.remove(childItemKey);
                        }
                        else if(childquoteItems.containsKey(childItemKey))
                        {
                            disallowedItems.add(childquoteItems.get(childItemKey));
                            if(ruleRequiredquoteItems.containsKey(childItemKey))
                            {
                                ruleRequiredquoteItems.remove(childItemKey);
                            } 
                        }
                    }
                    else
                    {  
                        if(newChildquoteItemsLookup.containsKey(childItemKey)) continue;
                        
                        if(childquoteItems.containsKey(childItemKey))
                        {
                            Quote_Item__c childItem = childquoteItems.get(childItemKey);
                            if(childItem.Auto_Added__c != true) 
                            {
                                childItem.Auto_Added__c = true;
                                childItem.Rule_Required_Item__c = (a.Type__c =='Required');
                                updateItems.add(childItem);
                            }   
                            if(ruleRequiredquoteItems.containsKey(childItemKey))
                            {
                                ruleRequiredquoteItems.remove(childItemKey);
                            }
                            continue;
                        }                        

                        Price_Book_Item__c pbiObj = priceBookItemsLookup.get(pbi);
                        Quote_Item__c ti = CreateQuoteItem(quoteItem.Quote__c, pbiObj);

                        ti.Parent_Quote_Item__c = parentId;
                        ti.Auto_Added__c = true;
                        ti.Rule_Required_Item__c = (a.Type__c =='Required');
                        newItems.add(ti);
                        newChildquoteItemsLookup.put(childItemKey, ti);
                    }                                           
                } 
            }
        }
        //System.debug('RunQuoteItemRules childItems size=' + newItems.size());
        insert newItems;
        if(!updateItems.isEmpty()) update updateItems;
        if(!ruleRequiredquoteItems.isEmpty())
        {
            disallowedItems.addAll(ruleRequiredquoteItems.values());
        }
        delete disallowedItems;

    }
    
    
     @TestVisible
    static void EnforceQuoteItemRules_DisallowedItems(List<Quote_Item__c> quoteItems)
    {         
        if(quoteItems==null || quoteItems.isEmpty()) return;
        Set<Id> parentquoteItemIds = new Set<Id>();
        Map<String, Quote_Item__c> childItemsLookup = new Map<String, Quote_Item__c>();
        Set<Id> childItemPriceBookItemIds = new Set<Id>();
        List<Quote_Item__c> itemsOfInterest = new List<Quote_Item__c>();
        for(Quote_Item__c ti : quoteItems)
        {
            if(ti.Auto_Added__c == true || String.isBlank(ti.Parent_Quote_Item__c)) continue;
            parentquoteItemIds.add(ti.Parent_Quote_Item__c);
            itemsOfInterest.add(ti);
        }
        if(itemsOfInterest.isEmpty()) return;

        Map<Id, Quote_Item__c> parentquoteItems =
            new Map<Id, Quote_Item__c>([SELECT Id, Price_Book_Item__c FROM Quote_Item__c WHERE Id IN :parentquoteItemIds AND IsDeleted=false]);

        for(Quote_Item__c ti : itemsOfInterest)
        {
            String key = String.valueOf(ti.Parent_Quote_Item__c) 
                + String.valueOf(parentquoteItems.get(ti.Parent_Quote_Item__c).Price_Book_Item__c)
                + String.valueOf(ti.Price_Book_Item__c);
            childItemsLookup.put(key, ti);
            childItemPriceBookItemIds.add(ti.Price_Book_Item__c);
        }

        Set<Id> rulePriceBookItemIds = new Set<Id>();
        for(Quote_Item__c ti: parentquoteItems.values())
        {
            rulePriceBookItemIds.add(ti.Price_Book_Item__c);
        }        

        List<Price_Book_Rule__c> rules = [SELECT Id, Name, Price_Book__c, Criteria__c, CriteriaStack__c, CriteriaQueryFields__c, 
                Price_Book_Item__c, 
                (SELECT Id, Price_Book_Item__c FROM Rule_Actions__r 
                    WHERE IsDeleted=false AND Type__c = 'Disallowed' AND Price_Book_Item__c IN :childItemPriceBookItemIds)
            FROM Price_Book_Rule__c 
            WHERE IsDeleted=false AND Price_Book_Item__c IN :rulePriceBookItemIds AND Active_Actions__c>0 AND Applies_To__c INCLUDES ('Quote__c')];

     

        if(rules.isEmpty()) return;

        String ns = StringUtility.FXNamespace(); 

        Map<Id, List<Quote_Item__c>> dbQuoteItems = GetQuoteItems(rules, parentquoteItemIds);    

        Map<Id, Set<Id>> ruleApplicable = new Map<Id, Set<Id>>();  
        Map<String, String> disallowRuleActionInfo = new Map<String, String>();      
        for(Price_Book_Rule__c r: rules)
        {
            if(String.isBlank(r.CriteriaStack__c)) continue;
            
            String msg = 'Disallowed by Rule - ' + r.Name;

            Id pbId = r.Price_Book__c;            
            String ruleStack = r.CriteriaStack__c;
            for(Quote_Item__c ti : dbQuoteItems.get(pbId))
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


    static void ExecuteInternal(Set<Id> quoteIds, Boolean skipRecommendedRuleAction)
    {   
        if(RuleEngineCore.IsActive()!= true) return;                  
            

        List<Quote__c> Quotes = [SELECT Id, Price_Book__c, Status__c, Status__r.Read_Only_Apps__c, (SELECT Id, Price_Book_Item__c, Auto_Added__c, Rule_Required_Item__c, SyncID__c FROM Quote_Items__r ORDER BY Auto_Added__c ASC) FROM Quote__c WHERE Id IN :quoteIds AND Status__c!=null AND Status__r.Sync__c=false AND Status__r.Read_Only_Apps__c EXCLUDES ('Console')];

        Map<Id, Id> quotePriceBookLookup = new Map<Id, Id>();
        Map<Id, Set<Id>> priceBookToQuotes = new Map<Id, Set<Id>>();
        Set<Id> priceBookIds = new Set<Id>();

        for(Quote__c t: Quotes)
        {
            if(!String.isEmpty(t.Status__c) && !String.isEmpty(t.Status__r.Read_Only_Apps__c) && t.Status__r.Read_Only_Apps__c.contains('Console')) continue;
            Id priceBookId = t.Price_Book__c;
            quotePriceBookLookup.put(t.Id, priceBookId);
            priceBookIds.add(priceBookId);
            if(!priceBookToQuotes.containsKey(priceBookId))
            {
                priceBookToQuotes.put(priceBookId, new Set<Id>());
            }
            priceBookToQuotes.get(priceBookId).add(t.Id);
        }

            //Quotes are all in readyOnly status, no need to run RuleEngine
            if(priceBookToQuotes.isEmpty()) return;

            Map<Id, Price_Book__c>  pbWithRequiredItems = new Map<Id, Price_Book__c>([SELECT Id, Name, (SELECT Id, Parent_Price_Book_Item__c,Requires_Parent_Item__c FROM Price_Book_Items__r WHERE Required_Item__c=true AND Requires_Parent_Item__c=false ORDER BY Parent_Price_Book_Item__c) FROM Price_Book__c WHERE Id IN :priceBookIds]);

           
            List<Price_Book_Rule__c> rules = skipRecommendedRuleAction? 
                [SELECT Id, Price_Book__c, Criteria__c, CriteriaStack__c, CriteriaQueryFields__c, Price_Book_Item__c, (SELECT Id, Price_Book_Item__c, Type__c FROM Rule_Actions__r WHERE IsActive__c=true AND Type__c!='Recommended') FROM Price_Book_Rule__c WHERE IsActive__c=true AND Active_Actions__c>0 AND Price_Book__c IN :priceBookIds AND Applies_To__c INCLUDES ('Quote__c')]
                :[SELECT Id, Price_Book__c, Criteria__c, CriteriaStack__c, CriteriaQueryFields__c,Price_Book_Item__c, (SELECT Id, Price_Book_Item__c, Type__c FROM Rule_Actions__r WHERE IsActive__c=true) FROM Price_Book_Rule__c WHERE IsActive__c=true AND Active_Actions__c>0 AND Price_Book__c IN :priceBookIds AND Applies_To__c INCLUDES ('Quote__c')];
         
            

            Map<Id, List<Price_Book_Rule__c>> pbRulesLookup = new Map<Id, List<Price_Book_Rule__c>>();

            for(Price_Book_Rule__c r: rules)
            {
                //skip QuoteItem rules : r.Price_Book_Item__c != null 
                if(r.Price_Book_Item__c != null || r.Rule_Actions__r.isEmpty()) continue;
                if(!pbRulesLookup.containsKey(r.Price_Book__c))
                {
                    pbRulesLookup.put(r.Price_Book__c, new List<Price_Book_Rule__c>());
                }
                pbRulesLookup.get(r.Price_Book__c).add(r);
            }

            Map<Id, QuoteSnapshot> quoteSnapshots = BuildQuoteSnapshot(priceBookToQuotes, pbWithRequiredItems, pbRulesLookup);

            List<Quote_Item__c> itemsToDelete = new List<Quote_Item__c>(); 

            Map<Id, Set<Id>> mapItemsOnQuote = new Map<Id, Set<Id>>();

            //Quote.Id + Price_Book_Item as key
            Map<String, Quote_Item__c> quoteItemsLookup = new Map<String, Quote_Item__c>();

            Map<Id, String> priceBookItemToQuoteItemSyncID = new Map<Id, String>();

            for(Quote__c t: Quotes)
            {            
                if(!quoteSnapshots.containsKey(t.Id)) continue;
                
                QuoteSnapshot snapshot = quoteSnapshots.get(t.Id);

                mapItemsOnQuote.put(t.Id, new Set<Id>());
                for(Quote_Item__c ti : t.Quote_Items__r)
                {
                    if(snapshot.IsDisallowed(ti.Price_Book_Item__c) || (ti.Rule_Required_Item__c == true && !snapshot.IsRuleRequired(ti.Price_Book_Item__c)))
                    {
                        itemsToDelete.add(ti);                                  
                    }   
                    else
                    {
                        mapItemsOnQuote.get(t.Id).add(ti.Price_Book_Item__c);

                        quoteItemsLookup.put(String.valueOf(t.Id) + ti.Price_Book_Item__c, ti);

                        priceBookItemToQuoteItemSyncID.put(ti.Price_Book_Item__c, ti.SyncID__c);
                    }           
                }
            }
            delete itemsToDelete;

            List<Quote_Item__c> itemsToInsert = new List<Quote_Item__c>();
            Set<Id> priceBookItemIds = new Set<Id>();

            for(QuoteSnapshot t : quoteSnapshots.values())
            {           
                priceBookItemIds.addAll(t.RuleItems.keySet());     
                priceBookItemIds.addAll(t.PriceBookRequiredItems);
            }       
        Map<Id, Price_Book_Item__c> priceBookItems = new Map<Id, Price_Book_Item__c>([SELECT Id, Requires_Parent_Item__c, Parent_Price_Book_Item__c, Ticket_Item_Record_Type__c, (SELECT Id, Requires_Parent_Item__c, Parent_Price_Book_Item__c, Ticket_Item_Record_Type__c FROM Child_Price_Book_Items__r) FROM Price_Book_Item__c WHERE Id IN :priceBookItemIds]);
        

        BuildQuotes(quoteSnapshots, priceBookItems, mapItemsOnQuote, priceBookItemToQuoteItemSyncID, quoteItemsLookup);
        
    }
      

    static void BuildQuotes(Map<Id, QuoteSnapshot> quoteSnapshots, Map<Id, Price_Book_Item__c> priceBookItems,
     Map<Id, Set<Id>> mapItemsOnQuote, Map<Id, String> priceBookItemToQuoteItemSyncID,
     Map<String, Quote_Item__c> dbquoteItemLookup)
    { 
        List<Quote_Item__c> quoteItems = new List<Quote_Item__c>();
        List<Quote_Item__c> childquoteItems = new List<Quote_Item__c>();

        Map<Id, Quote_Item__c> quoteItemsUpdate = new Map<Id, Quote_Item__c>();

        Map<String, Quote_Item__c> newquoteItems = new Map<String, Quote_Item__c>();

        for(Id quoteId : quoteSnapshots.keySet())
        {
            QuoteSnapshot snapshot = quoteSnapshots.get(quoteId);
            Set<Id> itemsOnQuote = mapItemsOnQuote.get(quoteId);
            Map<Id, Price_Book_Item__c> itemsNeedParant = new Map<Id, Price_Book_Item__c>();

            for(Id pbiId : snapshot.RuleItems.keySet())
            {
                String quoteItemKey = String.valueOf(quoteId) + pbiId;
                if(itemsOnQuote.contains(pbiId)) 
                {
                    //System.debug('get here items on Quote');
                    if(dbquoteItemLookup.containsKey(quoteItemKey))
                    {
                        
                        Quote_Item__c dbquoteItem = dbquoteItemLookup.get(quoteItemKey);
                        if(dbquoteItem.Auto_Added__c == false || snapshot.RuleItems.get(pbiId) == RuleEngineCore.RuleActionType.Required)
                        {
                            dbquoteItem.Auto_Added__c = true;
                            dbquoteItem.Rule_Required_Item__c = snapshot.RuleItems.get(pbiId) == RuleEngineCore.RuleActionType.Required;
                            quoteItemsUpdate.put(dbquoteItem.Id, dbquoteItem);
                        }                        
                    }
                    else if(newquoteItems.containsKey(quoteItemKey))
                    {
                        Quote_Item__c quoteItem = newquoteItems.get(quoteItemKey);
                        quoteItem.Auto_Added__c = true;
                        if(snapshot.RuleItems.get(pbiId) == RuleEngineCore.RuleActionType.Required)
                        {
                            quoteItem.Rule_Required_Item__c = true;
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
                    Quote_Item__c ti = CreateQuoteItem(quoteId, pbi);
                    ti.Auto_Added__c = true;
                    ti.Rule_Required_Item__c = snapshot.RuleItems.get(pbiId) == RuleEngineCore.RuleActionType.Required;

                    itemsOnQuote.add(pbiId);
                    quoteItems.add(ti);
                    newquoteItems.put(quoteItemKey, ti);

                    priceBookItemToQuoteItemSyncID.put(pbiId, ti.SyncID__c);
                    for(Price_Book_Item__c c : pbi.Child_Price_Book_Items__r)
                    {
                        if(snapshot.DisallowedItems.contains(c.Id)) continue;

                        String childquoteItemKey = String.valueOf(quoteId) + c.Id;

                        Quote_Item__c tiChild = CreateQuoteItem(quoteId, c);
                        tiChild.Parent_Quote_Item__r = new Quote_Item__c(SyncID__c = ti.SyncID__c);

                        itemsOnQuote.add(c.Id); 
                        priceBookItemToQuoteItemSyncID.put(pbiId, tiChild.SyncID__c);
                        childquoteItems.add(tiChild);
                        newquoteItems.put(childquoteItemKey, tiChild);
                    }
                }
            }
            for(Price_Book_Item__c c: itemsNeedParant.values())
            {
                if(!itemsOnQuote.contains(c.Parent_Price_Book_Item__c)) continue;

                String key = String.valueOf(quoteId) + c.Id;

                if(newquoteItems.containsKey(key)) 
                {
                    Quote_Item__c tiChild = newquoteItems.get(key);
                    tiChild.Auto_Added__c = true;
                    if(snapshot.RuleItems.get(c.Id) == RuleEngineCore.RuleActionType.Required)
                    {
                        tiChild.Rule_Required_Item__c = true;
                    }
                }
                else
                {
                    Quote_Item__c tiChild = CreateQuoteItem(quoteId, c);
                    if(itemsOnQuote.contains(c.Parent_Price_Book_Item__c))           
                    {
                        tiChild.Parent_Quote_Item__r = new Quote_Item__c(SyncID__c = priceBookItemToQuoteItemSyncID.get(c.Parent_Price_Book_Item__c));
                    }

                    tiChild.Auto_Added__c = true;
                    tiChild.Rule_Required_Item__c = snapshot.RuleItems.get(c.Id) == RuleEngineCore.RuleActionType.Required;

                    itemsOnQuote.add(c.Id);
                    quoteItems.add(tiChild);
                    newquoteItems.put(key, tiChild);
                }                
            }
        }
        if(!quoteItemsUpdate.isEmpty())
        {
            update quoteItemsUpdate.values();    
        }
        insert quoteItems;
        insert childquoteItems;

    }
    
    
    public static Map<Id, QuoteSnapshot> BuildQuoteSnapshot(Map<Id, Set<Id>> priceBookQuotes, 
        Map<Id, Price_Book__c> pbWithRequiredItems, 
        Map<Id, List<Price_Book_Rule__c>> pbRules)
    {
        Map<Id, QuoteSnapshot>  quoteSnapshots = new Map<Id, QuoteSnapshot>();

         String ns = UtilityGetNamespace.CurrentNamespace();
        for(Id priceBookId : pbWithRequiredItems.keySet())
        {
            Set<Id> quotes = priceBookQuotes.get(priceBookId);
            Price_Book__c pb = pbWithRequiredItems.get(priceBookId);
            Set<Id> priceBookItemIds = new Map<Id, Price_Book_Item__c>(pb.Price_Book_Items__r).keySet();

            for(Id quoteId: quotes)
            {
                if(!quoteSnapshots.containsKey(quoteId))
                {
                    quoteSnapshots.put(quoteId, new QuoteSnapshot(quoteId));
                }
                quoteSnapshots.get(quoteId).AddRuleItems(priceBookItemIds, RuleEngineCore.RuleActionType.PriceBookRequired);
            }           
        }

        Set<Id> allquoteIds = new Set<Id>();
        for(Id pbId : priceBookQuotes.keySet())
        {
            allquoteIds.addAll(priceBookQuotes.get(pbId));
        }

        List<Price_Book_Rule__c> allRules = new List<Price_Book_Rule__c>();
        for(Id pbId: pbRules.keySet())
        {
            allRules.addAll(pbRules.get(pbId));
        }

        Map<Id, List<Quote__c>> QuotesByPriceBooks = GetQuotes(allRules, allquoteIds);

        for(Id priceBookId : pbRules.keySet())
        {
            List<Price_Book_Rule__c> rules = pbRules.get(priceBookId);
            Set<Id> quoteIds = priceBookQuotes.get(priceBookId);
            for(Price_Book_Rule__c r: rules)
            {       
                if(String.isBlank(r.CriteriaStack__c)) continue;
                     
                System.debug('Rule: ' + r.Criteria__c);
                System.debug('Eval for Quotes: ' + JSON.serializePretty(QuotesByPriceBooks.get(r.Price_Book__c)));
                List<Quote__c> rulequotes = EvalRule(QuotesByPriceBooks.get(r.Price_Book__c), r.CriteriaStack__c);
                
                if(rulequotes.isEmpty()) continue;

                System.debug('Eval true for Quotes: ' + JSON.serializePretty(rulequotes));


                for(Quote__c t: rulequotes)
                {
                    if(!quoteSnapshots.containsKey(t.Id))
                    {
                        quoteSnapshots.put(t.Id, new QuoteSnapshot(t.Id));
                    }   
                    quoteSnapshots.get(t.Id).AddRuleItems(r.Rule_Actions__r);                      
                }
            }
        }
        return quoteSnapshots;
    }

    static List<Quote__c> EvalRule(List<Quote__c> quotes, String ruleStack)
    {
        List<Quote__c> results = new List<Quote__c>();
        for(Quote__c t: quotes)
        {
            if(RuleExpression.Eval(ruleStack, t))
            {
                results.add(t);
            }
            else
            {
                System.debug('eval false for rule Stack: ' + ruleStack);
                System.debug(JSON.serializePretty(t));
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

    static Set<String> GetQuoteQueryFields(List<Price_Book_Rule__c> rules)
    {
        Set<String> queryFields = GetQueryFields(rules);
        String ns = StringUtility.FXNamespace();
        queryFields.add(ns + 'Price_Book__c');
        return queryFields;
    }

    static String GetQuoteSoql(List<Price_Book_Rule__c> rules, String pNamequoteIds)
    {
        Set<String> queryFields = GetQueryFields(rules);
        String ns = StringUtility.FXNamespace();
        queryFields.add( ns + 'Price_Book__c');
        return String.format('SELECT {1} FROM {0}Quote__c WHERE Id IN :{2}', 
            new String[]{ns, 
                String.join(new List<String>(queryFields), ','),
                pNamequoteIds});
    }

    static String GetQuoteItemSoql(List<Price_Book_Rule__c> rules, String pNamequoteItemIds)
    {
        Set<String> queryFields = GetQueryFields(rules);
        String ns = StringUtility.FXNamespace();
        queryFields.add( ns + 'Quote__r.' +  ns + 'Price_Book__c');
        queryFields.add(ns + 'Price_Book_Item__c');
        queryFields.add(ns + 'Quote__c');
        return String.format('SELECT {1} FROM {0}Quote_Item__c WHERE Id IN :{2}', 
            new String[]{ns, 
                String.join(new List<String>(queryFields), ','),
                pNamequoteItemIds});
    }


   static Map<Id, List<Quote__c>> GetQuotes(List<Price_Book_Rule__c> rules, Set<Id> quoteIds)
   {
        String quoteSoql = GetQuoteSoql(rules, 'quoteIds');
        Map<Id, List<Quote__c>> Quotes = new Map<Id, List<Quote__c>>();
        for(Quote__c t : Database.query(quoteSoql))
        {
            Quote__c quote = (Quote__c)t;
            Id pbId  = quote.Price_Book__c;
            if(!Quotes.containsKey(pbId))
            {
                Quotes.put(pbId, new List<Quote__c>());
            }
            Quotes.get(pbId).add(quote);
        }
        return Quotes;
   }


   static Map<Id, List<Quote_Item__c>> GetQuoteItems(List<Price_Book_Rule__c> rules, Set<Id> quoteItemIds)
   {
        String quoteSoql = GetQuoteItemSoql(rules, 'quoteItemIds');
        Map<Id, List<Quote_Item__c>> quoteItems = new Map<Id, List<Quote_Item__c>>();
        for(Quote_Item__c obj : Database.query(quoteSoql))
        {
            Quote_Item__c ti = (Quote_Item__c)obj;
            Id pbId  = ti.Quote__r.Price_Book__c;
            if(!quoteItems.containsKey(pbId))
            {
                quoteItems.put(pbId, new List<Quote_Item__c>());
            }
            quoteItems.get(pbId).add(ti);
        }
        return quoteItems;
   }

    public static Map<Id, Set<Id>> GetDisallowedPriceBookItemsForQuotes(Set<Id> quoteIds, Set<Id> priceBookItemIds,  Map<String, String> disallowedRuleNames)
    {  
        Map<Id, Set<Id>> quoteDisallowItems = new Map<Id, Set<Id>>();
        List<Price_Book_Rule_Action__c> actions = [SELECT Id, Price_Book_Item__c, Price_Book_Rule__c, Price_Book_Rule__r.Price_Book__c, Price_Book_Rule__r.Criteria__c, Price_Book_Rule__r.CriteriaStack__c, Price_Book_Rule__r.CriteriaQueryFields__c, Price_Book_Rule__r.Name FROM Price_Book_Rule_Action__c WHERE IsActive__c=true AND Type__c='Disallowed' AND Price_Book_Rule__r.IsActive__c=true AND Price_Book_Item__c IN :priceBookItemIds AND Price_Book_Rule__r.Applies_To__c INCLUDES ('Quote__c') AND Price_Book_Rule__r.Price_Book_Item__c=null];
        
        if(actions.isEmpty()) return quoteDisallowItems;        

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


        Map<Id, List<Quote__c>> Quotes = GetQuotes(rules, quoteIds);
        for(Price_Book_Rule__c r : rules)
        {
            Id pbId = r.Price_Book__c;
            
            System.debug('Rule Criteria: ' + r.Criteria__c);
            List<Quote__c> rulequotes = EvalRule(Quotes.get(pbId), r.CriteriaStack__c);
            System.debug('True for Quotes: ' + ruleQuotes);
            if(rulequotes.isEmpty()) continue;

            String ruleMsg = 'Item is disallowed by Rule "' + r.Name + '".';
            for(Quote__c t : rulequotes)
            {
                if(!quoteDisallowItems.containsKey(t.Id))     
                {
                    quoteDisallowItems.put(t.Id, new Set<Id>());
                }
                for(Price_Book_Rule_Action__c a : ruleActions.get(r.Id))
                {
                    String key = String.valueOf(t.Id) + a.Price_Book_Item__c;

                    quoteDisallowItems.get(t.Id).add(a.Price_Book_Item__c);
                    disallowedRuleNames.put(key, ruleMsg);
                }               
            }
        }
        return quoteDisallowItems;
    }


    public static void ValdiateDisallowRules(List<Quote_Item__c> quoteItems)
    {
        Set<Id> priceBookItemIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();
        Map<String, List<Quote_Item__c>> quoteItemLookup = new Map<String, List<Quote_Item__c>>();
        
        List<Quote_Item__c> manaullChildItems = new List<Quote_Item__c>();
      
        for(Quote_Item__c ti: quoteItems)
        {      
            if(ti.Auto_Added__c == true) continue;
            quoteIds.add(ti.Quote__c);
            
            if(!String.isBlank(ti.Parent_Quote_Item__c))
            {
                manaullChildItems.add(ti);
            }
            priceBookItemIds.add(ti.Price_Book_Item__c);   
            String quoteItemKey= ti.Quote__c + '' + ti.Price_Book_Item__c;
            if(!quoteItemLookup.containsKey(quoteItemKey))      
            {
                quoteItemLookup.put(quoteItemKey, new List<Quote_Item__c>());
            }
            quoteItemLookup.get(quoteItemKey).add(ti);
        }

        if(!quoteIds.isEmpty())
        {
            Map<String, String> ruleMsgs = new Map<String, String>();
    
            Map<Id, Set<Id>> disallowedPriceBookItems = GetDisallowedPriceBookItemsForQuotes(quoteIds, priceBookItemIds, ruleMsgs);
    
            for(Quote_Item__c ti : quoteItems)
            {
                String key = String.valueOf(ti.Quote__c) + ti.Price_Book_Item__c;
                if(!ruleMsgs.containsKey(key)) continue;
                ti.addError(ruleMsgs.get(key));
            }
        }
        if(!manaullChildItems.isEmpty())
        {
            EnforceQuoteItemRules_DisallowedItems(manaullChildItems);
        }   
    }

    public static Map<String, Set<String>> GetPriceBookRuleCriteriaFields(Set<Id> priceBooks)
    {      
        Map<String, Set<String>> ruleFields = new Map<String, Set<String>>();
        if(priceBooks==null || priceBooks.isEmpty()) return ruleFields;

        List<Price_Book_Rule__c> rules = [SELECT Id, Price_Book__c, Price_Book_Item__c, Criteria__c FROM Price_Book_Rule__c WHERE IsDeleted=false AND Active_Actions__c>0 AND IsActive__c=true AND Price_Book__c IN :priceBooks AND Applies_To__c INCLUDES ('Quote__c')];
       
        
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

        String[] strs = new String[]{'FX5__Job__r.FX5__Quote__r.Deep__c>120 AND FX5__Height__c=40', 'Job__r.Office__r.Name=\'Lubbock\''};
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
            
            Boolean isquoteItemRule = r.Price_Book_Item__c!=null;

            Id pb = r.Price_Book__c;
            String quoteKey = 'quote' + pb;
            String quoteItemKey = 'quoteitem' + pb;
            
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
                       
                        if(fk.endsWith('Quote__r'))
                        {
                            ownerKey = quoteKey;
                        }
                        else if(fk.endsWith('Quote_Item__r'))
                        {
                            ownerKey = quoteItemKey;
                        }
                        else
                        {
                            ownerKey = isquoteItemRule? quoteItemKey : quoteKey;                               
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

                        //System.debug(ownerKey + ' ****************** ' + field);

                    }
                }
                else
                {
                    ownerKey = isquoteItemRule? quoteItemKey : quoteKey;  
                    if(!ruleFields.containsKey(ownerKey))
                    {
                        ruleFields.put(ownerKey, new Set<String>());
                    }
                    ruleFields.get(ownerKey).add(fkFields.get(0));
                    // System.debug(ownerKey + ' ****************** ' + fkFields.get(0));
                }
            }  
                    
        }
        return ruleFields;
    }

    
    
    public static List<Id> GetDisallowedPriceBookItems(String objId)
    {
        if(objId.startsWith(Quote__c.sObjectType.getDescribe().getKeyPrefix()))
        {
            return GetDisallowedPriceBookItemsForQuote(objId);
        }
        
        if(objId.startsWith(Quote_Item__c.sObjectType.getDescribe().getKeyPrefix()))
        {
            return GetDisallowedPriceBookItemsForQuoteItem(objId);
        }
        return new List<Id>();
    }
    
    @TestVisible
    static List<Id> GetDisallowedPriceBookItemsForQuote(String quoteID)
    {
        Quote__c quote = [SELECT Id, Price_Book__c FROM Quote__c WHERE Id=:quoteID];
        Id pbId = quote.Price_Book__c;
        List<Price_Book_Rule__c> rules = [SELECT Id, Price_Book__c, Criteria__c, CriteriaStack__c, CriteriaQueryFields__c, (SELECT Id, Price_Book_Item__c FROM Rule_Actions__r WHERE IsActive__c=true AND Type__c='Disallowed' AND IsDeleted=false) FROM Price_Book_Rule__c WHERE IsDeleted=false AND Price_Book_Item__c=null AND Active_Actions__c>0 AND Price_Book__c=:pbId AND Applies_To__c INCLUDES ('Quote__c')];

        Set<Id> pbItemIds = new Set<Id>();

        String ns = UtilityGetNamespace.CurrentNamespace();
        Set<Id> quoteIds = new Set<Id>();
        quoteIds.add(quote.Id);

        Map<Id, List<Quote__c>> QuotesByPriceBooks = GetQuotes(rules, quoteIds);

        for(Price_Book_Rule__c r : rules)
        {     
            if(r.Rule_Actions__r.isEmpty() ||String.isBlank(r.Criteria__c))  continue;  
            
            List<Quote__c> rulequotes = EvalRule(QuotesByPriceBooks.get(r.Price_Book__c), r.CriteriaStack__c);
              //[SELECT Id, (SELECT Id FROM Quotes__r WHERE Job__r.Distance__c>150) FROM Job__c WHERE Id='a0IF000000O1n9I'];
            if(rulequotes.isEmpty()) continue;

            for(Price_Book_Rule_Action__c a : r.Rule_Actions__r)
            {
                pbItemIds.add(a.Price_Book_Item__c);
            }
        }
        return new List<Id>(pbItemIds);
    }
    
    @TestVisible
    static List<Id> GetDisallowedPriceBookItemsForQuoteItem(String objId)
    {
        List<Quote_Item__c> quoteItems = [SELECT Id, Price_Book_Item__c FROM Quote_Item__c WHERE Id=:objId AND IsDeleted=false];
        
        //System.debug('quoteItems.size()=' + quoteItems.size());
        if(quoteItems.isEmpty()) return null;

        Quote_Item__c quoteItem = quoteItems.get(0);

        Id priceBookItemId = quoteItem.Price_Book_Item__c;

        List<Price_Book_Rule__c> rules = [SELECT Id, Name, Price_Book__c, Criteria__c, CriteriaStack__c, CriteriaQueryFields__c, 
                Price_Book_Item__c, 
                (SELECT Id, Price_Book_Item__c FROM Rule_Actions__r WHERE IsDeleted=false AND Type__c = 'Disallowed')
            FROM Price_Book_Rule__c 
            WHERE IsDeleted=false AND Active_Actions__c>0 AND Price_Book_Item__c=:priceBookItemId AND Applies_To__c INCLUDES ('Quote__c')];

        Set<Id> quoteItemIds = new Set<Id>();
        quoteItemIds.add(objId);

        quoteItems = GetQuoteItems(rules, quoteItemIds).values()[0];
        quoteItem  = quoteItems.get(0);
        
        Set<Id> disallowedItemIds = new Set<Id>();     
        String soql = '';
        String ns = UtilityGetNamespace.CurrentNamespace();

        for(Price_Book_Rule__c r: rules)
        {
            if(String.isBlank(r.CriteriaStack__c) || !RuleExpression.Eval(r.CriteriaStack__c, quoteItem)) continue;
            for(Price_Book_Rule_Action__c action : r.Rule_Actions__r)
            {
                disallowedItemIds.add(action.Price_Book_Item__c);
            }   
        }
        return new List<Id>(disallowedItemIds);
    }

    

    class QuoteSnapshot
    {   
        public QuoteSnapshot(Id quoteId0)
        {
            quoteId = quoteId0;
            DisallowedItems = new Set<Id>();
            RuleItems = new Map<Id, RuleEngineCore.RuleActionType>();
            PriceBookRequiredItems = new Set<Id>();
        }
        public Id quoteId {get; set;}
        public Set<Id> DisallowedItems {get; set;}
        public Map<Id, RuleEngineCore.RuleActionType> RuleItems {get; set;}
        public Set<Id> PriceBookRequiredItems {get;set;}

        public Boolean IsDisallowed(Id priceBookItemId)
        {
            return DisallowedItems.contains(priceBookItemId);
        }

        public Boolean IsRuleRequired(Id priceBookItemId)
        {
            return RuleItems.containsKey(priceBookItemId) && RuleItems.get(priceBookItemId) == RuleEngineCore.RuleActionType.Required;
        }

        public void AddRuleItems(Set<Id> pbItems, RuleEngineCore.RuleActionType type)
        {
            for(Id pbi: pbItems)
            {
                AddRuleItem(pbi, type);
            }
        }

        public void AddRuleItem(Id priceBookItemId, RuleEngineCore.RuleActionType type)
        {
            if(type == RuleEngineCore.RuleActionType.Disallowed)
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
                if(type == RuleEngineCore.RuleActionType.PriceBookRequired)
                {
                    PriceBookRequiredItems.add(priceBookItemId);
                    RuleItems.put(priceBookItemId, RuleEngineCore.RuleActionType.Required);
                }
                else if(!RuleItems.containsKey(priceBookItemId) || type == RuleEngineCore.RuleActionType.Required)
                {
                    RuleItems.put(priceBookItemId, type);
                }               
            }
        }

        public void AddRuleItems(List<Price_Book_Rule_Action__c> items)
        {
            for(Price_Book_Rule_Action__c item: items)
            {
                RuleEngineCore.RuleActionType type = RuleEngineCore.RuleActionType.Required;              
                if(item.Type__c == 'Recommended')
                {
                    type = RuleEngineCore.RuleActionType.Recommended;  
                }
                else if(item.Type__c == 'Disallowed')
                {
                    type = RuleEngineCore.RuleActionType.Disallowed;   
                }
                AddRuleItem(item.Price_Book_Item__c, type);
            }
        }
    }    
}