@isTest
private class PriceBookRuleHandler_Test
{    
    static testmethod void HappyPath()
    {
        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id pbId = j.Price_Book__c;
        
        Test.startTest();
        String ns= UtilityGetNamespace.CurrentNamespace();
        
        String criteria = '[ns]Status__r.Name=\'In Progress\'';
        criteria = criteria.replace('[ns]', ns);
        Price_Book_Rule__c r = new Price_Book_Rule__c(Price_Book__c = pbId, IsActive__c=true, Criteria__c = criteria);
        insert r;
        Test.stopTest();
    }
    
    static testmethod void BulkInsert_Test()
    {
        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id pbId = j.Price_Book__c;
        
        Test.startTest();
        String ns= UtilityGetNamespace.CurrentNamespace();
        
        List<Price_Book_Rule__c> rules = new List<Price_Book_Rule__c>();
        for(Integer i=0; i<50; i++)
        {
            String criteria = '[ns]Status__r.Name=\'Status ' + i + '\'';
            criteria = criteria.replace('[ns]', ns);
            Price_Book_Rule__c r = new Price_Book_Rule__c(Price_Book__c = pbId, IsActive__c=true, Criteria__c = criteria);
            rules.add(r);
        }
        insert rules;
       
        Test.stopTest();
    }
    
    
    
    
    
    
    
    static testmethod void SadPath_UnknowField()
    {
        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id pbId = j.Price_Book__c;
        
        Test.startTest();
        String ns= UtilityGetNamespace.CurrentNamespace();
        
        List<Price_Book_Rule__c> rules = new List<Price_Book_Rule__c>();
        for(Integer i=0; i<50; i++)
        {
            String criteria = 'CustomFieldNotThere=\'[v]\')';
            criteria = criteria.replace('[v]', 'Category ' + i);
            Price_Book_Rule__c r = new Price_Book_Rule__c(Price_Book__c = pbId, IsActive__c=true, Criteria__c = criteria);
            rules.add(r);
        }
        
        Database.SaveResult [] results = Database.insert(rules, false);       
                  
        Test.stopTest();
        
        for (Database.SaveResult r : results)
        {  
            System.assert(!r.isSuccess(), 'insert should fail for invalid criteria');        
           
        }    

        
    }
    
    
    static testmethod void SadPath_ISPICKBAL()
    {
        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id pbId = j.Price_Book__c;
        
        Test.startTest();
        String ns= UtilityGetNamespace.CurrentNamespace();
        
        List<Price_Book_Rule__c> rules = new List<Price_Book_Rule__c>();
        for(Integer i=0; i<50; i++)
        {
            String criteria = ns + 'ISPICKVAL([ns]Job__r.Category456__c, \'[v]\')';
            criteria = criteria.replace('[v]', 'Category ' + i).replace('[ns]', ns);
            Price_Book_Rule__c r = new Price_Book_Rule__c(Price_Book__c = pbId, IsActive__c=true, Criteria__c = criteria);
            rules.add(r);
        }
        
        Database.SaveResult [] results = Database.insert(rules, false);       
                  
        Test.stopTest();
        
        for (Database.SaveResult r : results)
        {  
            System.assert(!r.isSuccess(), 'insert should fail for invalid criteria');        
           
        }    

        
    }
    
    
    //for code coverage PriceBookRuleActionTriggerHandler.OnBeforeUpdate
    static testmethod void UpdateRuleAction_ForCodeCoverage()
    {
           
        
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);
       
        
        Price_Book_Item__c disallowedItem = pbItems.get(0);
        
        String ns = UtilityGetNamespace.CurrentNamespace();
        
        String criteria = ns + 'Job__c=\'' + job.Id + '\'';
        
        Price_Book_Rule__c rule = new Price_Book_Rule__c(Price_Book__c = priceBookId, IsActive__c=true, Criteria__c=criteria);
        insert rule;
        
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = disallowedItem.Id, IsActive__c = true, Type__c='Required');
        insert action;
        Test.startTest();  
        action.Type__c = 'Disallowed';
        update action;
        Test.stopTest();
    }


     static testmethod void IsRuleCriteriaValid_Includes_True_Test()
    {
        String ns = UtilityGetNamespace.CurrentNamespace();
        String criteria = 'includes([ns]Applies_To__c, \'Ticket__c\')'.replace('[ns]', ns);
        String objContext = ns + 'Price_Book_Rule__c';
        String result = PriceBookRuleHandler.IsRuleCriteriaValid(criteria, objContext);
        System.assert(String.isBlank(result), 'Includes valid');
    }

    static testmethod void IsRuleCriteriaValid_Excludes_True_Test()
    {
        String ns = UtilityGetNamespace.CurrentNamespace();
        String criteria = 'excludes([ns]Applies_To__c, \'Ticket__c\')'.replace('[ns]', ns);
        String objContext = ns + 'Price_Book_Rule__c';
        String result = PriceBookRuleHandler.IsRuleCriteriaValid(criteria, objContext);
        System.assert(String.isBlank(result), 'Excludes valid, instead of ' + result);
    }

    static testmethod void IsRuleCriteriaValid_Includes_false_Test()
    {
        String ns = UtilityGetNamespace.CurrentNamespace();
        String criteria = 'includes([ns]Segment__c, \'SegmentABC\')'.replace('[ns]', ns);
        String objContext = ns + 'Job__c';
        String result = PriceBookRuleHandler.IsRuleCriteriaValid(criteria, objContext);
        System.assert(!String.isBlank(result), 'Includes invalid, instead of ' + result);
    }
    
    //IsRuleCriteriaValid_Includes_false_Test
    static testmethod void Includes_CaseInsensitive_Test()
    {
        String ns = UtilityGetNamespace.CurrentNamespace();
        String criteria = 'INclUdEs([ns]Segment__c, \'SegmentABC\')'.replace('[ns]', ns);
        String objContext = ns + 'Job__c';
        String result = PriceBookRuleHandler.IsRuleCriteriaValid(criteria, objContext);
        System.assert(!String.isBlank(result), 'Includes invalid, instead of ' + result);
    }
}