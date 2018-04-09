@isTest
private class RuleEngineForQuote_Test
{
    static Integer groupSize = 6;

    @testSetup
     static void setup()
    {
        Quote__c q = AlpineTestHelper.CreateQuotes(1, false).get(0);

        Status__c s = [SELECT Id FROM Status__c WHERE Sync__c=false AND SObject__c='Quote__c' LIMIT 1];
        q.Status__c = s.Id;
        insert q;


        Id priceBookId = q.Price_Book__c;

        String ns = StringUtility.FXNamespace();        

        List<Price_Book_Item__c> priceBookItems = AlpineTestHelper.CreatePriceBookItems(6* groupSize, priceBookId, 'Equipment');

        String criteria = ns + 'Status__c!=null';
        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"!=\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"null\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', ns + 'Status__c');
        
        Price_Book_Rule__c rule = new Price_Book_Rule__c(Price_Book__c = priceBookId, 
            IsActive__c=true, Criteria__c=criteria, Applies_To__c='Quote__c',
            CriteriaQueryFields__c = ns + 'Status__c',
            CriteriaStack__c=criteriaStack);        
        insert rule;
        
        String segmentCriteria = ns + 'Segment__c==\'UnitTestSegment\'';
        criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"UnitTestSegment\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', ns + 'Segment__c');
        
        Price_Book_Rule__c segmentRule = new Price_Book_Rule__c(Price_Book__c = priceBookId, 
            IsActive__c=true, Criteria__c=segmentCriteria,
            Applies_To__c='Quote__c',
            CriteriaQueryFields__c = ns + 'Segment__c',
            CriteriaStack__c=criteriaStack);        
        insert segmentRule ;

        List<Price_Book_Rule_Action__c> ruleActions = new List<Price_Book_Rule_Action__c>();

        for(Integer i=0; i<groupSize; i++)
        {
            ruleActions.add(new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, 
                Price_Book_Item__c = priceBookItems.get(i).Id, 
                IsActive__c = true, 
                Type__c='Required'));

            ruleActions.add(new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, 
                Price_Book_Item__c = priceBookItems.get(i+groupSize).Id, 
                IsActive__c = true, 
                Type__c='Recommended'));

            ruleActions.add(new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, 
                Price_Book_Item__c = priceBookItems.get(i+2*groupSize).Id, 
                IsActive__c = true, 
                Type__c='Disallowed'));
        }

        Price_Book_Item__c rootItem = priceBookItems.get(0);

        Integer index = groupSize * 3 + 1;

        String itemRuleCriteria = String.format('{0}Quote__r.{0}Status__c!=null', new String[]{ns});

        criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"!=\\",\\"left\\":{\\"type\\":\\"MemberExpression\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"null\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', ns + 'Quote__r.' + ns + 'Status__c');

        Price_Book_Rule__c quoteItemRule = new Price_Book_Rule__c(Price_Book__c = priceBookId, 
            IsActive__c=true, Criteria__c= itemRuleCriteria , 
            CriteriaStack__c = criteriaStack,
            Applies_To__c='Quote__c',
            CriteriaQueryFields__c = ns + 'Quote__r.' +  ns + 'Status__c', 
            Price_Book_Item__c=rootItem.Id);  

         insert quoteItemRule;


        ruleActions.add(new Price_Book_Rule_Action__c(Price_Book_Rule__c = quoteItemRule.Id, 
                Price_Book_Item__c = priceBookItems.get(index).Id, 
                IsActive__c = true, 
                Type__c='Required'));

        ruleActions.add(new Price_Book_Rule_Action__c(Price_Book_Rule__c = quoteItemRule.Id, 
                Price_Book_Item__c = priceBookItems.get(index+1).Id, 
                IsActive__c = true, 
                Type__c='Recommended'));

        ruleActions.add(new Price_Book_Rule_Action__c(Price_Book_Rule__c = quoteItemRule.Id, 
                Price_Book_Item__c = priceBookItems.get(index+2).Id, 
                IsActive__c = true, 
                Type__c='Disallowed'));
                
        
        //6 segment rule action items
        index = groupSize * 4 + 1;
        for(Integer i=0; i<groupSize; i++)
        {
            ruleActions.add(new Price_Book_Rule_Action__c(Price_Book_Rule__c = segmentRule.Id, 
                Price_Book_Item__c = priceBookItems.get(index + i).Id, 
                IsActive__c = true, 
                Type__c='Required'));           
        }

        insert ruleActions;

    } 

    static testmethod void OnQuoteCreate_Test()
    {       
        Test.startTest();

        System.debug('OnQuoteCreate_Test ');
        Quote__c q = [SELECT Id, Price_Book__c, Price_Book__r.Name, Status__r.RecordTypeId, RecordType.DeveloperName FROM Quote__c LIMIT 1];
        List<Quote_Item__c> items = [SELECT Id, Price_Book_Item__c, Parent_Quote_Item__c, Item_Code__c FROM Quote_Item__c];
        System.assert(items.isEmpty(), 'should have no quoteItem in the system');

        Quote__c newQuote = AlpineTestHelper.CreateQuotes(q.Price_Book__r, 1, false).get(0);
        String statusName = 'Status' + StringUtility.newGuid();
        Status__c st = new Status__c(Name = statusName, SObject__c='Quote__c', 
            SObject_Record_Type__c= q.RecordType.DeveloperName, 
            Sync__c=false, Initial_Status_Console__c =false,
            RecordTypeId=q.Status__r.RecordTypeId);

        insert st;
        newQuote.Status__c = st.Id;
        insert newQuote;

        Test.stopTest();


        List<Quote_Item__c> childItems = [SELECT Id, Price_Book_Item__c, Parent_Quote_Item__c, Item_Code__c FROM Quote_Item__c WHERE Quote__c = :newQuote.Id AND Parent_Quote_Item__c!=null ORDER BY Item_Code__c];

        System.debug('childItems count = ' + childItems.size());
        items = [SELECT Id, Price_Book_Item__c, Parent_Quote_Item__c, Item_Code__c FROM Quote_Item__c WHERE Quote__c = :newQuote.Id ORDER BY Item_Code__c];

        Integer expectedResult = groupSize * 2 + 2; //required + recommended + ItemRule child items

        System.assert(items.size()==expectedResult, 'should have ' + expectedResult + ' auto added items, instead have ' + items.size());
    }




    static testmethod void OnQuoteUpdate_Test()
    {
        
        Test.startTest();

        Quote__c q = [SELECT Id, Status__c FROM Quote__c LIMIT 1];  
        Integer count = [SELECT COUNT() FROM Quote_Item__c WHERE Auto_Added__c = true AND Quote__c = :q.Id];
        System.assert(count==0, 'should have no auto added item before Quote update');

        Status__c s = [SELECT Id FROM Status__c WHERE Sync__c=true AND SObject__c='Quote__c' LIMIT 1];
        q.Status__c = s.Id;
        update q;

        s = [SELECT Id FROM Status__c WHERE Sync__c=false AND SObject__c='Quote__c' LIMIT 1];
        q.Status__c = s.Id;
        update q;

        Test.stopTest();
        Integer expectedResult = groupSize + 1; // required + 1 child item (require), recommended items skipped on update
        count = [SELECT COUNT() FROM Quote_Item__c WHERE Auto_Added__c = true AND Quote__c = :q.Id];
        System.assert(count== expectedResult, 'should have ' + expectedResult + ' auto added required items after update (Recommended items skipped on update), instead have ' + count);
        
    }   

    static testmethod void QuoteItemRule_Test()
    {
        
       
        String ns = StringUtility.FXNamespace();

        Quote__c q = [SELECT Id, Price_Book__c, Price_Book__r.Name FROM Quote__c LIMIT 1];  
        List<Price_Book_Item__c> priceBookItems = AlpineTestHelper.CreatePriceBookItems(5, q.Price_Book__c, 'Equipment');

        Integer count = [SELECT COUNT() FROM Quote_Item__c WHERE Auto_Added__c = true AND Quote__c = :q.Id];
        System.assert(count==0, 'should have no auto added item before Quote update');

        Status__c s = [SELECT Id FROM Status__c WHERE Sync__c=false AND SObject__c='Quote__c' LIMIT 1];
        Quote__c newQuote = AlpineTestHelper.CreateQuotes(q.Price_Book__r, 1, false).get(0);
        newQuote.Status__c = s.Id;
        insert newQuote;

        Id priceBookId = q.Price_Book__c;

        String itemRuleCriteria = String.format('{0}Qty__c>100', new String[]{ns});

        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\">\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"100\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', ns + 'Qty__c');

        Price_Book_Item__c rootItem = priceBookItems.get(0);
        Price_Book_Rule__c quoteItemRule = new Price_Book_Rule__c(Price_Book__c = priceBookId, 
            IsActive__c=true,
            Criteria__c=itemRuleCriteria, 
            CriteriaQueryFields__c = ns + 'Qty__c',
            CriteriaStack__c=criteriaStack,
            Applies_To__c='Quote__c', Price_Book_Item__c=rootItem.Id);
        insert quoteItemRule;

        List<Price_Book_Rule_Action__c> ruleActions = new List<Price_Book_Rule_Action__c>();


        ruleActions.add(new Price_Book_Rule_Action__c(Price_Book_Rule__c = quoteItemRule.Id, 
                Price_Book_Item__c = priceBookItems.get(1).Id, 
                IsActive__c = true, 
                Type__c='Required'));

        ruleActions.add(new Price_Book_Rule_Action__c(Price_Book_Rule__c = quoteItemRule.Id, 
                Price_Book_Item__c = priceBookItems.get(2).Id, 
                IsActive__c = true, 
                Type__c='Recommended'));

        ruleActions.add(new Price_Book_Rule_Action__c(Price_Book_Rule__c = quoteItemRule.Id, 
                Price_Book_Item__c = priceBookItems.get(3).Id, 
                IsActive__c = true, 
                Type__c='Disallowed'));

        insert ruleActions;

        Test.startTest();

        Quote_Item__c qi = new Quote_Item__c(Quote__c = newQuote.Id, Price_Book_Item__c = rootItem.Id, Qty__c=200);
        insert qi;
        Test.stopTest();

        Integer expectedResult = 2; //one required + one recommended
        List<Quote_Item__c> childItems = [SELECT Id FROM Quote_Item__c WHERE Parent_Quote_Item__c = :qi.Id];

        System.assert(childItems.size()== 2, 'should have ' + expectedResult + ' child items from RuleActions, instead have ' + childItems.size());
        
    }   

    static testmethod void DisallowedItem_Test()
    {
        Test.startTest();  

        Price_Book_Rule_Action__c disallowedItem = [SELECT Id, Price_Book_Item__c FROM Price_Book_Rule_Action__c WHERE Type__c='Disallowed' AND Price_Book_Rule__r.Price_Book_Item__c=null LIMIT 1];
       
        Quote__c q = [SELECT Id FROM Quote__c LIMIT 1];
        Quote_Item__c qi = new Quote_Item__c(Quote__c = q.Id, Price_Book_Item__c = disallowedItem.Price_Book_Item__c);
        try {
            insert qi;
        }
        catch ( System.DmlException ex) {

            System.assert(ex.getMessage().contains('Item is disallowed by Rule'), 'error should contains "Item is disallowed", instead of :' + ex);
        }
        finally {
           Test.stopTest(); 
        }          
    }

    static testmethod void GetDisallowedPriceBookItems_OnQuote_Test()
    {
        Test.startTest();
        Quote__c q = [SELECT Id, Status__c, Price_Book__c FROM Quote__c WHERE Status__r.Sync__c = false LIMIT 1];
        Quote__c newQuote = q.clone(false, false, false, false);
        insert newQuote;
        List<Id> items = RuleEngineForQuote.GetDisallowedPriceBookItems(newQuote.Id);       
        Test.stopTest();

        System.assert(items.size() == groupSize, 'should have ' + groupSize + ' disallowed items, instead of have ' + items.size());
    }

    

    static testmethod void GetDisallowedPriceBookItems_OnQuoteItem_Test()
    {
        Test.startTest();
        Quote__c q = [SELECT Id, Status__c, Price_Book__c FROM Quote__c WHERE Status__r.Sync__c = false LIMIT 1];
        Quote__c newQuote = q.clone(false, false, false, false);
        insert newQuote;

        List<Quote_Item__c> quoteItems = [SELECT Id, Price_Book_Item__c FROM Quote_Item__c WHERE Quote__c =:newQuote.Id];
        Map<Id, Id> pbiToQuoteItem = new Map<Id, Id>();
        for(Quote_Item__c qi:quoteItems)
        {
            pbiToQuoteItem.put(qi.Price_Book_Item__c, qi.Id);
        }
        Set<Id> priceBookItemIds = pbiToQuoteItem.keySet();
        
        List<Price_Book_Rule__c> rules = [SELECT Id, Price_Book_Item__c, (SELECT Id, Price_Book_Item__c FROM Rule_Actions__r WHERE Type__c='Disallowed') FROM Price_Book_Rule__c WHERE Price_Book_Item__c IN :priceBookItemIds];
        Map<Id, Set<Id>> disallowedChildItems = new  Map<Id, Set<Id>>();
        for(Price_Book_Rule__c r : rules)
        {
            if(r.Rule_Actions__r.isEmpty()) continue;
            if(!disallowedChildItems.containsKey(r.Price_Book_Item__c))
            {
                disallowedChildItems.put(r.Price_Book_Item__c, new Set<Id>());
            }
            for(Price_Book_Rule_Action__c a : r.Rule_Actions__r)
            {
                disallowedChildItems.get(r.Price_Book_Item__c).add(a.Price_Book_Item__c);
            }
        }
        for(Id pbi : disallowedChildItems.keySet())
        {
            List<Id> items = RuleEngineForQuote.GetDisallowedPriceBookItems(pbiToQuoteItem.get(pbi));
            Set<Id> disallowedItems = disallowedChildItems.get(pbi);
            System.assert(items.size() == disallowedItems.size(), 'should have ' + disallowedItems.size() + ' disallowed items, instead have ' + items.size());
            for(Id itemId : items)
            {
                System.assert(disallowedItems.contains(itemId), 'returnging extra (wrong) item');
            }
        }       
        Test.stopTest();    
    }    

    static testmethod void AddDisallowedChildItem_Test()
    {
        Test.startTest();
        Quote__c q = [SELECT Id, Status__c, Price_Book__c FROM Quote__c WHERE Status__r.Sync__c = false LIMIT 1];
        Quote__c newQuote = q.clone(false, false, false, false);
        insert newQuote;

        List<Quote_Item__c> quoteItems = [SELECT Id, Price_Book_Item__c FROM Quote_Item__c WHERE Quote__c =:newQuote.Id];
        Map<Id, Id> pbiToQuoteItem = new Map<Id, Id>();
        for(Quote_Item__c qi:quoteItems)
        {
            pbiToQuoteItem.put(qi.Price_Book_Item__c, qi.Id);
        }
        Set<Id> priceBookItemIds = pbiToQuoteItem.keySet();
        
        List<Price_Book_Rule__c> rules = [SELECT Id, Price_Book_Item__c, (SELECT Id, Price_Book_Item__c FROM Rule_Actions__r WHERE Type__c='Disallowed') FROM Price_Book_Rule__c WHERE Price_Book_Item__c IN :priceBookItemIds];
        Map<Id, Set<Id>> disallowedChildItems = new  Map<Id, Set<Id>>();
        for(Price_Book_Rule__c r : rules)
        {
            if(r.Rule_Actions__r.isEmpty()) continue;
            if(!disallowedChildItems.containsKey(r.Price_Book_Item__c))
            {
                disallowedChildItems.put(r.Price_Book_Item__c, new Set<Id>());
            }
            for(Price_Book_Rule_Action__c a : r.Rule_Actions__r)
            {
                disallowedChildItems.get(r.Price_Book_Item__c).add(a.Price_Book_Item__c);
            }
        }
        List<Quote_Item__c> newItems = new List<Quote_Item__c>();

        for(Id pbi : disallowedChildItems.keySet())
        {
            Id parentQuoteItem = pbiToQuoteItem.get(pbi);

            for(Id pbiChild : disallowedChildItems.get(pbi))
            {
                Quote_Item__c qi = new Quote_Item__c(Quote__c = newQuote.Id, Parent_Quote_Item__c = parentQuoteItem, Price_Book_Item__c=pbiChild);
                newItems.add(qi);
            }
        }       
        Database.SaveResult[] results = Database.insert(newItems, false);
        Test.stopTest();    
        
        Integer errorCount = 0;
        for (Database.SaveResult sr : results) {
            if(sr.isSuccess()) continue;
            ++errorCount;
        }
        System.assert(newItems.size() == errorCount, 'all save should fail, instead ' + errorCount + ' out of ' + newItems.size() + ' failed.');

        
    }    
    static testmethod void SegmentRule_RemoveRuleAddedItemUponUpdate_Test()
    {
        Quote__c q = [SELECT Id, Status__c, Price_Book__c FROM Quote__c WHERE Status__r.Sync__c = false LIMIT 1];
        Quote__c newQuote = q.clone(false, false, false, false);
        newQuote.Segment__c = 'UnitTestSegment';
        insert newQuote;
        Test.startTest();

        
        List<Quote_Item__c> items = [SELECT Id FROM Quote_Item__c where Quote__c = :newQuote.Id];
        
        Integer expectedResult = groupSize * 3 + 2; //required + recommended + segmentRuleItems + ItemRule child items 
        System.assert(items.size() == expectedResult , 'should ' + expectedResult + 'quote items, instead have ' + items.size());
        
        Quote__c dbQuote = [SELECT Id, Segment__c FROM Quote__c WHERE Id=:newQuote.Id];
        dbQuote.Segment__c = null;
        update dbQuote ;
        Test.stopTest();
        
        items = [SELECT Id FROM Quote_Item__c where Quote__c = :newQuote.Id];
        expectedResult = groupSize * 2 + 2; //required + recommended + ItemRule child items //segment rule now is false
        System.assert(items.size() == expectedResult , 'should ' + expectedResult + 'quote items, instead have ' + items.size());
        
        
    }
    
}