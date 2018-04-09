@isTest
private class RuleEngine_Test
{
    static Price_Book_Rule__c GetRule(Id pbId, String criteria, String criteriaStack)
    {
        Price_Book_Rule__c rule = new Price_Book_Rule__c(Price_Book__c = pbId, IsActive__c=true, 
            Criteria__c=criteria,
            CriteriaStack__c = criteriaStack);
        insert rule;
        return rule;
    }

    static Price_Book_Rule__c GetRule(Id pbId, String field, 
        String value, String op)
    {
        return GetRule(pbId, field, value, op, true);
    }


    static Price_Book_Rule__c GetRule(Id pbId, String field, 
        String value, String op, Boolean saveNow)
    {
        String ns = UtilityGetNamespace.CurrentNamespace();
        
        field = field.replace('[ns]', ns);

        String criteria = field + op + '\'' + value + '\'';
        System.debug('criteria: ' + criteria);

         
        String criteriaStack =  '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"[op]\\",\\"left\\":{\\"type\\":\\"MemberExpression\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"[value]\\"}}"]';
        
        System.debug('criteriaStack: ' + criteriaStack);
        criteriaStack = criteriaStack.replace('[fieldName]', field).replace('[op]', op).replace('[value]', value);
        Price_Book_Rule__c rule = new Price_Book_Rule__c(Price_Book__c = pbId, IsActive__c=true, 
            Criteria__c=criteria,
            CriteriaStack__c = criteriaStack);
        if(saveNow) insert rule;
        return rule;

    }

    static Integer groupSize = 6;
    static void setupTicketItemRules()
    {
        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = j.Price_Book__c;

        String newGuid = StringUtility.newGuid();
      
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');       
        RecordType qtRecordType = AlpineTestHelper.GetRecordType('Job__c');   

        string statusName = 'JobNoSyncStatus ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Job__c', 
            SObject_Record_Type__c=qtRecordType.DeveloperName, 
            Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);

        insert st;


        String ns = StringUtility.FXNamespace();


        

        List<Price_Book_Item__c> priceBookItems = AlpineTestHelper.CreatePriceBookItems(4* groupSize, priceBookId, 'Equipment');

        String criteria = ns + 'Status__c!=null';
        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"!=\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"null\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', ns + 'Status__c');
        Price_Book_Rule__c rule = new Price_Book_Rule__c(Price_Book__c = priceBookId, 
            IsActive__c=true, Criteria__c=criteria, Applies_To__c='Ticket__c',
            CriteriaQueryFields__c = ns + 'Status__c',
            CriteriaStack__c=criteriaStack);        
        insert rule;

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

        criteria = String.format('{0}Ticket__r.{0}Status__c!=null', new String[]{ns});
        criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"!=\\",\\"left\\":{\\"type\\":\\"MemberExpression\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"null\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', ns + 'Ticket__r.' + ns + 'Status__c');

        Price_Book_Rule__c quoteItemRule = new Price_Book_Rule__c(Price_Book__c = priceBookId, 
            IsActive__c=true, Criteria__c=criteria, 
            CriteriaStack__c = criteriaStack,
            Applies_To__c='Ticket__c', 
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

        insert ruleActions;

    }

    static testmethod void Ticket_AndRuleTrueTest()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', false);
        insert pbItems;

        String ns = StringUtility.FXNamespace();

        String criteria = 'Job__r.Sync__c == true && Sync__c == true';
        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"MemberExpression\\",\\"value\\":\\"Job__r.Sync__c\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"true\\"}}","{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"Sync__c\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"true\\"}}","&&"]';
        criteriaStack = criteriaStack.replace('Job__r', ns + 'Job__r').replace('Sync__c', ns+ 'Sync__c');

        Price_Book_Rule__c rule = GetRule(priceBookId, criteria, criteriaStack);

        Price_Book_Item__c pbItem = pbItems.get(0);

        insert new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, 
                Price_Book_Item__c = pbItem.Id, 
                IsActive__c = true, 
                Type__c='Recommended');
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);        
        Test.stopTest();
        List<Ticket_Item__c> tktItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:pbItem.Id];
        System.assertEquals(1, tktItems.size());
    }

    static testmethod void Ticket_AndRuleFalseTest()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', false);
        insert pbItems;

        String ns = StringUtility.FXNamespace();

        String criteria = 'Job__r.Sync__c == false && Sync__c == true';
        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"MemberExpression\\",\\"value\\":\\"Job__r.Sync__c\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"false\\"}}","{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"Sync__c\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"true\\"}}","&&"]';
        criteriaStack = criteriaStack.replace('Job__r', ns + 'Job__r').replace('Sync__c', ns+ 'Sync__c');

        Price_Book_Rule__c rule = GetRule(priceBookId, criteria, criteriaStack);

        Price_Book_Item__c pbItem = pbItems.get(0);

        insert new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, 
                Price_Book_Item__c = pbItem.Id, 
                IsActive__c = true, 
                Type__c='Recommended');
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);        
        Test.stopTest();
        List<Ticket_Item__c> tktItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:pbItem.Id];
        System.assertEquals(0, tktItems.size());
    }


    static testmethod void Ticket_OrRuleTrueTest()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', false);
        insert pbItems;

        String ns = StringUtility.FXNamespace();
        String criteria = 'Job__r.Sync__c == true || Sync__c == true';
        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"MemberExpression\\",\\"value\\":\\"Job__r.Sync__c\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"true\\"}}","{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"Sync__c\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"false\\"}}","||"]';
        criteriaStack = criteriaStack.replace('Job__r', ns + 'Job__r').replace('Sync__c', ns+ 'Sync__c');

        Price_Book_Rule__c rule = GetRule(priceBookId, criteria, criteriaStack);

        Price_Book_Item__c pbItem = pbItems.get(0);

        insert new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, 
                Price_Book_Item__c = pbItem.Id, 
                IsActive__c = true, 
                Type__c='Recommended');
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);        
        Test.stopTest();
        List<Ticket_Item__c> tktItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:pbItem.Id];
        System.assertEquals(1, tktItems.size());
    }

    static testmethod void Ticket_OrRuleFalseTest()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', false);
        insert pbItems;

        String ns = StringUtility.FXNamespace();
        String criteria = 'Job__r.Sync__c == true || Sync__c == true';
        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"MemberExpression\\",\\"value\\":\\"Job__r.Sync__c\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"false\\"}}","{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"Sync__c\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"false\\"}}","||"]';
        criteriaStack = criteriaStack.replace('Job__r', ns + 'Job__r').replace('Sync__c', ns+ 'Sync__c');

        Price_Book_Rule__c rule = GetRule(priceBookId, criteria, criteriaStack);

        Price_Book_Item__c pbItem = pbItems.get(0);

        insert new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, 
                Price_Book_Item__c = pbItem.Id, 
                IsActive__c = true, 
                Type__c='Recommended');
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);        
        Test.stopTest();
        List<Ticket_Item__c> tktItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:pbItem.Id];
        System.assertEquals(0, tktItems.size());
    }

    static testmethod void TicketItemRule_Test()
    {
        setupTicketItemRules();
        Test.startTest();
        Job__c j = [SELECT Id, Price_Book__c, Price_Book__r.Name FROM Job__c LIMIT 1];        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(j, 1, false).get(0);

        Status__c noSyncStatus = [SELECT Id FROM Status__c WHERE Sync__c=false AND SObject__c='Ticket__c' LIMIT 1];

        tkt.Status__c = noSyncStatus.Id;
        insert tkt;
        Test.stopTest();


        List<Ticket_Item__c> childItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c = :tkt.Id AND Parent_Ticket_Item__c!=null];
        System.assert(childItems.size()==2, 'should have ' + 2 + ' child items, instead have ' + childItems.size());
        
        List<Ticket_Item__c> items = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c = :tkt.Id];

        Integer expectedResult = groupSize * 2 + 2; //required + recommended + ItemRule child items

        System.assert(items.size()==expectedResult, 'should have ' + expectedResult + ' auto added items, instead have ' + items.size());

    }
    static testmethod void TicketRulesOnly_JobUpdate_RequiredItems()
    {
        Test.startTest();  
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        
        List<Ticket__c> tkts = AlpineTestHelper.CreateTickets(job,5,true);
          
        Ticket__c syncTkt = tkts[0];
        Ticket__c noSyncTkt = tkts[1];
        
        String newGuid = 'E9E05272-5AD1-BD9A-D351-9194DCC7AB27';
         
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  
        
        string jobStatusName = 'Job Status ' + newGuid;
        Status__c jobStatus = new Status__c(Name = jobStatusName , SObject__c='Job__c', Sync__c=true, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert jobStatus ;
        

        string syncStatusName = 'Status Sync ' + newGuid;
        Status__c syncStatus = new Status__c(Name = syncStatusName , SObject__c='Ticket__c', Sync__c=true, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert syncStatus ;
        
        string noSyncStatusName = 'Status NOT Sync ' + newGuid;
        Status__c noSyncStatus = new Status__c(Name = noSyncStatusName , SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert noSyncStatus ;
        
        syncTkt.Status__c = syncStatus.Id;
        noSyncTkt.Status__c = noSyncStatus.Id;
        
        update syncTkt;
        update noSyncTkt;        
        
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);   
        Price_Book_Item__c requiredItem = pbItems.get(0);

        Price_Book_Item__c quoteRequiredItem = pbItems.get(1);
        
        
        String ns = UtilityGetNamespace.CurrentNamespace();
        
        //String criteria = ns + 'Job__r.' + ns + 'Status__r.Name ==\'' + jobStatusName  + '\'';    
      

       
        Price_Book_Rule__c rule = GetRule(priceBookId, '[ns]Job__r.[ns]Status__r.Name', jobStatusName, '==');
      

       
        //Price_Book_Rule__c rule2 = new Price_Book_Rule__c(Price_Book__c = priceBookId, IsActive__c=true, Criteria__c=criteria, Applies_To__c='Quote__c');
        //insert rule2;

        Price_Book_Rule__c dbRule = [SELECT Id, Applies_To__c FROM Price_Book_Rule__c WHERE Id=:rule.Id];
        System.assert(dbRule.Applies_To__c == 'Ticket__c', 'Applies_To__c should be Ticket__c');
        
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = requiredItem.Id, IsActive__c = true, Type__c='Required');
        insert action;
        
        //Price_Book_Rule_Action__c action2 = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule2.Id, Price_Book_Item__c = quoteRequiredItem.Id, IsActive__c = true, Type__c='Required');
        //insert action2;

        job.Status__c = jobStatus.Id;
        update job;
        Test.stopTest();        
        
        List<Ticket_Item__c> tktItems = [SELECT Id, Auto_Added__c, Rule_Required_Item__c  FROM Ticket_Item__c WHERE Ticket__c =:noSyncTkt.Id AND Rule_Required_Item__c=true];
        System.assertEquals(1, tktItems.size());
        
        Ticket_Item__c tktItem = tktItems.get(0);        
        System.assert(tktItem.Auto_Added__c == true, 'Auto_Added should be true');
        System.assert(tktItem.Rule_Required_Item__c == true, 'Rule_Required_Item__c should be true');        
        
        
    }

    static testmethod void JobUpdate_RequiredItems()
    {
        Test.startTest();  
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        
        List<Ticket__c> tkts = AlpineTestHelper.CreateTickets(job,5,true);
          
        Ticket__c syncTkt = tkts[0];
        Ticket__c noSyncTkt = tkts[1];
        
        String newGuid = 'E9E05272-5AD1-BD9A-D351-9194DCC7AB27';
         
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  
        
        string jobStatusName = 'Job Status E9E05272-5AD1-BD9A-D351-9194DCC7AB27';
        Status__c jobStatus = new Status__c(Name = jobStatusName , SObject__c='Job__c', Sync__c=true, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert jobStatus ;
        

        string syncStatusName = 'Status Sync E9E05272-5AD1-BD9A-D351-9194DCC7AB27';
        Status__c syncStatus = new Status__c(Name = syncStatusName , SObject__c='Ticket__c', Sync__c=true, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert syncStatus ;
        
        string noSyncStatusName = 'Status NOT Sync E9E05272-5AD1-BD9A-D351-9194DCC7AB27';
        Status__c noSyncStatus = new Status__c(Name = noSyncStatusName , SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert noSyncStatus ;
        
        syncTkt.Status__c = syncStatus.Id;
        noSyncTkt.Status__c = noSyncStatus.Id;
        
        update syncTkt;
        update noSyncTkt;        
        
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);   
        Price_Book_Item__c requiredItem = pbItems.get(0);
        
        
        String ns = UtilityGetNamespace.CurrentNamespace();       
       
        Price_Book_Rule__c rule = GetRule(priceBookId, '[ns]Job__r.[ns]Status__r.Name', jobStatusName, '==');
      


        Price_Book_Rule__c dbRule = [SELECT Id, Applies_To__c FROM Price_Book_Rule__c WHERE Id=:rule.Id];
        System.assert(dbRule.Applies_To__c == 'Ticket__c', 'Applies_To__c should be Ticket__c');
        
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = requiredItem.Id, IsActive__c = true, Type__c='Required');
        insert action;
        
        job.Status__c = jobStatus.Id;
        update job;
        Test.stopTest();  
        
        List<Ticket_Item__c> tktItems = [SELECT Id, Auto_Added__c, Rule_Required_Item__c  FROM Ticket_Item__c WHERE Ticket__c =:noSyncTkt.Id AND Price_Book_Item__c =:requiredItem.Id];
        System.assertEquals(1, tktItems.size());
        
        Ticket_Item__c tktItem = tktItems.get(0);        
        System.assert(tktItem.Auto_Added__c == true, 'Auto_Added should be true');
        System.assert(tktItem.Rule_Required_Item__c == true, 'Rule_Required_Item__c should be true');        
        
        
    }
    
    static testmethod void TicketUpdate_RequiredItems()
    {
        Test.startTest();  
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);   
        
        String newGuid = StringUtility.newGuid();
         
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  

        string statusName = 'Status ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st;
        
        
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);   
        Price_Book_Item__c requiredItem = pbItems.get(0);
        
        
        String ns = UtilityGetNamespace.CurrentNamespace();
        
       // String criteria = ns + 'Status__r.Name ==\'' + statusName  + '\'';      

        Price_Book_Rule__c rule = GetRule(priceBookId, '[ns]Status__r.Name', statusName, '==');
      


        Price_Book_Rule__c dbRule = [SELECT CriteriaQueryFields__c FROM Price_Book_Rule__c WHERE Id=:rule.Id];
        System.assert(dbRule.CriteriaQueryFields__c == ns + 'Status__r.Name', 
            'CriteriaQueryFields should be ' + ns + 'Status__r.Name, instead of ' + dbRule.CriteriaQueryFields__c);
        
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = requiredItem.Id, IsActive__c = true, Type__c='Required');
        insert action;
        
        tkt.Status__c = st.Id;
        update tkt;
        Test.stopTest();  
        
        List<Ticket_Item__c> tktItems = [SELECT Id, Auto_Added__c, Rule_Required_Item__c  FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:requiredItem.Id];
        System.assertEquals(1, tktItems.size());
        
        Ticket_Item__c tktItem = tktItems.get(0);
        
        System.assert(tktItem.Auto_Added__c == true, 'Auto_Added should be true');
        System.assert(tktItem.Rule_Required_Item__c == true, 'Rule_Required_Item__c should be true');
        
        
    }
    
    
    static testmethod void TicketUpdate_NewRuleOnRequiredItems()
    {
        Test.startTest();  
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
         
        
        String newGuid = StringUtility.newGuid();
         
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  

        string statusName = 'Status ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st;
        
        
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(3, priceBookId , 'Equipment', true);  

        List<Price_Book_Item__c> dbItems = [SELECT Id, Parent_Price_Book_Item__c FROM Price_Book_Item__c WHERE Price_Book__c=:priceBookId];
        
        Price_Book_Item__c parent = dbItems.get(0);
        parent.Required_Item__c = true;
        dbItems.get(1).Parent_Price_Book_Item__c = parent.Id;
        Price_Book_Item__c child1 = dbItems.get(1);

        dbItems.get(2).Parent_Price_Book_Item__c = parent.Id;
        Price_Book_Item__c child2 = dbItems.get(2);

        update dbItems;

        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0); 

        
       
        
        
        String ns = UtilityGetNamespace.CurrentNamespace();
        
        //String criteria = ns + 'Status__r.Name ==\'' + statusName  + '\'';
        
        Price_Book_Rule__c rule = GetRule(priceBookId, '[ns]Status__r.Name', statusName, '==');      

        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = child1.Id, IsActive__c = true, Type__c='Required');
        insert action;
        
        tkt.Status__c = st.Id;
        update tkt;

        Test.stopTest();  
        
        List<Ticket_Item__c> tktItems = [SELECT Id, Auto_Added__c, Rule_Required_Item__c  FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:child1.Id];
        System.assertEquals(1, tktItems.size());
        
        Ticket_Item__c tktItem = tktItems.get(0);
        
        System.assert(tktItem.Auto_Added__c == true, 'Auto_Added should be true');
        System.assert(tktItem.Rule_Required_Item__c == true, 'Rule_Required_Item__c should be true');
        
        
    }

    static testmethod void GetDisallowedPriceBookItems_Test()
    {
        Test.startTest();  
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);   
        
        String newGuid = StringUtility.newGuid();
         
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  

        string statusName = 'Status ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st;
        
        tkt.Status__c = st.Id;
        update tkt;
        
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);   
       
        
        
        String ns = UtilityGetNamespace.CurrentNamespace();
        
        //String criteria = ns + 'Status__r.Name ==\'' + statusName  + '\'';     
        
        Price_Book_Rule__c rule = GetRule(priceBookId, '[ns]Status__r.Name', statusName, '==');
      

        Price_Book_Rule_Action__c action1 = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = pbItems.get(0).Id, IsActive__c = true, Type__c='Disallowed');
        insert action1;
        Price_Book_Rule_Action__c action2 = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = pbItems.get(1).Id, IsActive__c = true, Type__c='Disallowed');
        insert action2;
        Price_Book_Rule_Action__c action3= new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = pbItems.get(2).Id, IsActive__c = true, Type__c='Disallowed');
        insert action3;        
      
        
        
        Set<Id> tktIds = new Set<Id>();
        tktIds.add(tkt.Id);
        List<Id> pbIds =  RuleEngineCore.GetDisallowedPriceBookItems(tkt.Id);

        Test.stopTest();  

        Set<Id> disallowedItems = new Set<Id>();
        disallowedItems.addAll(pbIds);
        System.debug('*********************************pbIds ='+ pbIds );
        System.debug('*********************************item 1 ='+ pbItems.get(0).Id );
          System.assert(disallowedItems.size()==3, 'Should have three disallowed items.' + disallowedItems.size());
        
        System.assert(disallowedItems.contains(pbItems.get(0).Id) || disallowedItems.contains(String.valueOf(pbItems.get(0).Id)));
        System.assert(disallowedItems.contains(pbItems.get(1).Id)|| disallowedItems.contains(String.valueOf(pbItems.get(1).Id)));
        System.assert(disallowedItems.contains(pbItems.get(2).Id)|| disallowedItems.contains(String.valueOf(pbItems.get(2).Id)));
        
        
    }
    
    static testmethod void TicketUpdate_ApplyRequiredRuleActionForExistingTicketItems()
    {
        Test.startTest();  
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);   
        
        String newGuid = StringUtility.newGuid();
         
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  

        string statusName = 'Status ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st;
        
        
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);   
        Price_Book_Item__c requiredItem = pbItems.get(0);

        Ticket_Item__c ti = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = requiredItem.Id);
        insert ti;
        
        
        String ns = UtilityGetNamespace.CurrentNamespace();
        
       

        Price_Book_Rule__c rule = GetRule(priceBookId, '[ns]Status__r.Name', statusName, '==');
      

        
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = requiredItem.Id, IsActive__c = true, Type__c='Required');
        insert action;
        
        tkt.Status__c = st.Id;
        update tkt;
        Test.stopTest();  
        
        List<Ticket_Item__c> tktItems = [SELECT Id, Auto_Added__c, Rule_Required_Item__c  FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:requiredItem.Id];
        System.assertEquals(1, tktItems.size());
        
        Ticket_Item__c tktItem = tktItems.get(0);
        
        System.assert(tktItem.Auto_Added__c == true, 'Auto_Added should be true anytime RuleAction is applied');
        System.assert(tktItem.Rule_Required_Item__c == true, 'Rule_Required_Item__c should be true anytime Required RuleActon is applied');
        
        
    }
    
    static testmethod void TicketUpdate_SkipRecommendedItems()
    {
        Test.startTest();  
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);   
        
        String newGuid = StringUtility.newGuid();
         
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  

        string statusName = 'Status ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st;
        
        
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);   
        
        Price_Book_Item__c pbi = pbItems.get(0);
        
        
        String ns = UtilityGetNamespace.CurrentNamespace();
        
          Price_Book_Rule__c rule = GetRule(priceBookId, '[ns]Status__r.Name', statusName, '==');
      
        
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = pbi.Id, IsActive__c = true, Type__c='Recommended');
        insert action;
        
        tkt.Status__c = st.Id;
        update tkt;
        Test.stopTest();  
        
        List<Ticket_Item__c> tktItems = [SELECT Id, Auto_Added__c, Rule_Required_Item__c  FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:pbi.Id];
        System.assert(0==tktItems.size(), 'Ticket Update should skip Recommended (optional) item(s).');
        
        
        
        //System.assert(tktItem.Auto_Added__c == true, 'Auto_Added should be true');
        //System.assert(tktItem.Rule_Required_Item__c == true, 'Rule_Required_Item__c should be true');
        
        
    }
    
    static testmethod void TicketUpdate_DisallowedItems()
    {
        Test.startTest();  
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c; 
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', false);           
        Price_Book_Item__c pbi = pbItems.get(0);
        pbi.Required_Item__c = true;
        insert pbItems;
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);   
        
        List<Ticket_Item__c> tktItems = [SELECT Id, Auto_Added__c, Rule_Required_Item__c  FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:pbi.Id];
        System.assert(1==tktItems.size(), 'Should have one PBRequired Item.');
        Ticket_Item__c tktItem = tktItems.get(0);
        System.assert(tktItem.Auto_Added__c == true, 'Auto_Added should be true');
        System.assert(tktItem.Rule_Required_Item__c == true, 'Rule_Required_Item__c should be true');
        
        Ticket__c dbTkt = [SELECT Id, Status__r.Name FROM Ticket__c WHERE Id=:tkt.Id];
        
        
        String newGuid = StringUtility.newGuid();
         
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  

        string statusName = 'Status ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st;
        
        
           
        
        String ns = UtilityGetNamespace.CurrentNamespace();
        
         Price_Book_Rule__c rule = GetRule(priceBookId, '[ns]Status__r.Name', statusName, '==');
      
        
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = pbi.Id, IsActive__c = true, Type__c='Disallowed');
        insert action;
        
        tkt.Status__c = st.Id;
        update tkt;
        Test.stopTest();  
        
        tktItems = [SELECT Id, Auto_Added__c, Rule_Required_Item__c  FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:pbi.Id];
        System.assert(0==tktItems.size(), 'Ticket Update should remove Item disalloed by ruleAction.');    
        

        
    }
    
    
    static testmethod void GetPriceBookRuleCriteriaFields_Test()
    {
        Test.startTest();  
        Set<Id> pricebookIds = new Set<Id>();
        
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id pbId = job.Price_Book__c;
        
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, pbId, 'Equipment');


        pricebookIds.add(pbId);
        
        List<Price_Book_Rule__c> rules = new List<Price_Book_Rule__c>();
        
        String ns = UtilityGetNamespace.CurrentNamespace();
        
        //Ticket field - Status__c
        String criteria = ns + 'Status__r.Name==\'In Progress\'';  
        Price_Book_Rule__c rule = GetRule(pbId, '[ns]Status__r.Name', 'In Progress', '==', true);
        insert new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, 
                Price_Book_Item__c = pbItems.get(0).Id, 
                IsActive__c = true, 
                Type__c='Required');



        
        criteria =  ns+ 'Customer_Survey_Satisfaction__c==\'OK\'';  
        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"OK\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', ns+ 'Customer_Survey_Satisfaction__c');
        //rules.add(GetRule(pbId, criteria, criteriaStack));
        rule = GetRule(pbId, criteria, criteriaStack);
        insert new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, 
                Price_Book_Item__c = pbItems.get(1).Id, 
                IsActive__c = true, 
                Type__c='Required');
        
        criteria =  ns+ 'Customer_Survey_Performance__c==\'Excellent\'';                
        criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"Excellent\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', ns+ 'Customer_Survey_Performance__c');        
        rule = GetRule(pbId, criteria, criteriaStack);
        rule.IsActive__c = false;
        update rule;
        insert new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, 
                Price_Book_Item__c = pbItems.get(2).Id, 
                IsActive__c = true, 
                Type__c='Required');

        criteria =  ns+ 'Job__r.' + ns + 'Office__r.Name==\'RuleEngineTestOffice\'';                
        rule = GetRule(pbId, '[ns]Job__r.[ns]Office__r.Name', 'RuleEngineTestOffice', '==', true);
        
        insert new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, 
                Price_Book_Item__c = pbItems.get(3).Id, 
                IsActive__c = true, 
                Type__c='Required');

        
        Test.stopTest();
                
        Map<String, Set<String>> fields = RuleEngineCore.GetPriceBookRuleCriteriaFields(priceBookIds);
        System.debug('all fields: ' + fields);
        Set<String> tktFields = fields.get('tkt' + pbId);
        System.assert(tktFields.contains(ns + 'Status__c'), 'Ticket relation field should have format __c instead of __r');
        System.assert(tktFields.contains(ns + 'Customer_Survey_Satisfaction__c'), 'Ticket field Customer_Survey_Satisfaction__c is missing');
        System.assert(!tktFields.contains(ns+ 'Customer_Survey_Performance__c'), 'Inactive rule for Customer_Survey_Performance__c should be excluded');
        
        Set<String> jobFields = fields.get('job' + pbId);
        
        System.assert(jobFields!=null && jobFields.contains(ns + 'Office__c'), 'Office__c misssing for Job__r.Office__r.Name');
        
    }

    
    static testmethod void InsertDisallowedTicketItem()
    {
        Test.startTest();    
        
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);
       
        
        Price_Book_Item__c disallowedItem = pbItems.get(0);
        
        String ns = UtilityGetNamespace.CurrentNamespace();
        
        String criteria = ns + 'Job__c==\'' + job.Id + '\'';
        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"[value]\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', ns+ 'Job__c').replace('[value]', job.Id);
      

        Price_Book_Rule__c rule = GetRule(priceBookId, criteria, criteriaStack);    
      
        
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = disallowedItem.Id, IsActive__c = true, Type__c='Disallowed');
        insert action;
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);   
        
        Ticket_Item__c ti = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = disallowedItem.Id);
        try
        {
            insert ti;
            System.assert(false, 'Insert should fail by the disallowed rule');
        }
        catch(DMLException e)
        {
            String msg = '';
            String sep ='';
            for (Integer i = 0; i < e.getNumDml(); i++) 
            {
                System.debug(e.getDmlMessage(i)); 
                msg += sep + e.getDmlMessage(i);
                sep =  ' | ';
            }            
            
            System.debug(msg);
            System.assert(msg.contains('Item is disallowed by Rule'), msg);
        }
          
        Test.stopTest();
      
    }
    
    
    static testmethod void RuleEngine_Activate_Test()
    {
        Test.startTest();
        RuleEngineCore.Suspend();
        System.assert(RuleEngineCore.IsSuspended());
        
        RuleEngineCore.Activate();
        System.assert(RuleEngineCore.IsActive());
        
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', false);
        pbItems.get(0).Required_Item__c  = true;
        insert pbItems;
        
        Price_Book_Item__c requiredItem = pbItems.get(0);
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);        
        Test.stopTest();
        List<Ticket_Item__c> tktItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:requiredItem.Id];
        System.assertEquals(1, tktItems.size());
    }
    
    static testmethod void RuleEngine_Suspend_Test()
    {
        Test.startTest();
        RuleEngineCore.Suspend();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', false);
        pbItems.get(0).Required_Item__c  = true;
        insert pbItems;
        
        Price_Book_Item__c requiredItem = pbItems.get(0);
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);        
        Test.stopTest();
        List<Ticket_Item__c> tktItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:requiredItem.Id];
        System.assertEquals(0, tktItems.size());
    }
    
    static testmethod void CreateOneTicket_TestPriceBookRequiredItem()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', false);
        pbItems.get(0).Required_Item__c  = true;
        insert pbItems;
        
        Price_Book_Item__c requiredItem = pbItems.get(0);
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);        
        Test.stopTest();
        List<Ticket_Item__c> tktItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:requiredItem.Id];
        System.assertEquals(1, tktItems.size());
    }
    



    static testmethod void PriceBookRequired_NoChildItemAlone()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);


        Price_Book_Item__c parent = pbItems.get(0);
        Price_Book_Item__c child = pbItems.get(1);
        child.Required_Item__c = true;
        child.Parent_Price_Book_Item__c = parent.Id;
        update child;

        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);        
        Test.stopTest();
        List<Ticket_Item__c> tktItems = [SELECT Id, Auto_Added__c, Rule_Required_Item__c FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:child.Id];
        System.assert(0 == tktItems.size(), 'Child PriceBookItem could not be added to Ticket without the parent item');     

    }

    static testmethod void RuleAction_ChildItemAloneNotAllow()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);
        Price_Book_Item__c parent = pbItems.get(0);
        Price_Book_Item__c child = pbItems.get(1);
        child.Parent_Price_Book_Item__c = parent.Id;
        update child;     

        String ns = UtilityGetNamespace.CurrentNamespace();
        String criteria = ns + 'Job__c==\'' + job.Id + '\''; 
        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"[value]\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', ns+ 'Job__c').replace('[value]', job.Id);
      

        Price_Book_Rule__c rule = GetRule(priceBookId, criteria, criteriaStack);  
        
        
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = child.Id, IsActive__c = true, Type__c='Required');
        insert action;
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);        
        Test.stopTest();
        List<Ticket_Item__c> tktItems = [SELECT Id, Rule_Required_Item__c, Auto_Added__c FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:child.Id];
        
        System.assert(0==tktItems.size(), 'RuleAction on child item should not be added to ticket if its parent is not on the ticket');       
      
    }


    static testmethod void CreateTickets_TestPriceBookRequiredItem()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', false);
        pbItems.get(0).Required_Item__c  = true;
        insert pbItems;
        
        Price_Book_Item__c requiredItem = pbItems.get(0);
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,5,true).get(0);        
        Test.stopTest();
        List<Ticket_Item__c> tktItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:requiredItem.Id];
        System.assertEquals(1, tktItems.size());
    }
    
    static testmethod void CreateTicket_TestRequiredRules()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);
       
        
        Price_Book_Item__c requiredItem = pbItems.get(0);
        
        String ns = UtilityGetNamespace.CurrentNamespace();
        
        String criteria = ns + 'Job__c==\'' + job.Id + '\'';
        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"[value]\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', ns + 'Job__c').replace('[value]', job.Id);

        Price_Book_Rule__c rule = GetRule(priceBookId, criteria, criteriaStack);
        
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = requiredItem.Id, IsActive__c = true, Type__c='Required');
        insert action;
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);        
        Test.stopTest();
        List<Ticket_Item__c> tktItems = [SELECT Id, Rule_Required_Item__c, Auto_Added__c FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:requiredItem.Id];
        
        System.assertEquals(1, tktItems.size());
        
        Ticket_Item__c tktitem = tktItems.get(0);
        System.assert(tktItem.Auto_Added__c == true, 'Auto_Added should be true');
        System.assert(tktItem.Rule_Required_Item__c == true, 'Rule_Required_Item__c should be true');
          
        
        System.debug(tktItems.get(0));
        
    }
    
    static testmethod void CreateTicket_ParentChildPriceBookItems()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);
       
        
        Price_Book_Item__c requiredItem = pbItems.get(0);
        for(Integer i=1; i<pbItems.size(); i++)
        {
            pbItems.get(i).Parent_Price_Book_Item__c = requiredItem.Id;
        }
        update pbItems;
        
        
        String ns = UtilityGetNamespace.CurrentNamespace();
        
        String criteria = ns + 'Job__c==\'' + job.Id + '\'';
        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"[value]\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', ns + 'Job__c').replace('[value]', job.Id);

        Price_Book_Rule__c rule = GetRule(priceBookId, criteria, criteriaStack);
        
      
        
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = requiredItem.Id, IsActive__c = true, Type__c='Required');
        insert action;
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);        
        Test.stopTest();
        List<Ticket_Item__c> tktItems = [SELECT Id, Rule_Required_Item__c, Auto_Added__c FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:requiredItem.Id];
        
        System.assertEquals(1, tktItems.size());
        
        Ticket_Item__c parent = tktItems.get(0);
        
        
         List<Ticket_Item__c> childItems = [SELECT Id, Rule_Required_Item__c, Auto_Added__c FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Parent_Ticket_Item__c =:parent.Id AND Rule_Required_Item__c=false AND Auto_Added__c=false];
        
        System.assertEquals(4, childItems.size());       
        
      
    }
    
    static testmethod void CreateTicket_ChildPriceBookItemDisallowed()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);
       
        
        Price_Book_Item__c requiredItem = pbItems.get(0);
        for(Integer i=1; i<pbItems.size(); i++)
        {
            pbItems.get(i).Parent_Price_Book_Item__c = requiredItem.Id;
        }
        update pbItems;
        
        
        String ns = UtilityGetNamespace.CurrentNamespace();
        
        String criteria = ns + 'Job__c==\'' + job.Id + '\'';
        
        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"[value]\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', ns + 'Job__c').replace('[value]', job.Id);

        Price_Book_Rule__c rule = GetRule(priceBookId, criteria, criteriaStack);
        
        
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = requiredItem.Id, IsActive__c = true, Type__c='Required');
        insert action;
        
        Id disallowedItemId = pbItems.get(1).Id;
        Price_Book_Rule_Action__c disallowed = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = disallowedItemId , IsActive__c = true, Type__c='Disallowed');
        insert disallowed;
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);        
        Test.stopTest();
        List<Ticket_Item__c> tktItems = [SELECT Id, Rule_Required_Item__c, Auto_Added__c FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:requiredItem.Id];
        
        System.assertEquals(1, tktItems.size());
        
        Ticket_Item__c parent = tktItems.get(0);
        
        
         List<Ticket_Item__c> allItems= [SELECT Id, Price_Book_Item__c, Rule_Required_Item__c, Auto_Added__c FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id];
         Set<Id> pbiOnTkt = new Set<Id>();
         for(Ticket_Item__c ti : allItems)
         {
             pbiOnTkt.add(ti.Price_Book_Item__c);
         }       
        
        System.assert(!pbiOnTkt.contains(disallowedItemId ), 'Disallowed child item(s) should not be on ticket');       
        
      
    }

    static testmethod void CreateTicket_ChildPriceBookItemRequired()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(3, priceBookId , 'Equipment', true);
       
        
         Price_Book_Item__c requiredItem = pbItems.get(0);
        for(Integer i=1; i<pbItems.size(); i++)
        {
            pbItems.get(i).Parent_Price_Book_Item__c = requiredItem.Id;
            pbItems.get(i).Description_Override__c = 'Child item ' + i;
        }
        update pbItems;
        String ns = UtilityGetNamespace.CurrentNamespace();
        
        String criteria = ns + 'Job__c=\'' + job.Id + '\'';
        
       String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"[value]\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', ns + 'Job__c').replace('[value]', job.Id);

        Price_Book_Rule__c rule = GetRule(priceBookId, criteria, criteriaStack);
        
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = requiredItem.Id, IsActive__c = true, Type__c='Required');
        insert action;
        
        Id pbiChildRequired = pbItems.get(1).Id;
        Price_Book_Rule_Action__c childRequired = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = pbiChildRequired , IsActive__c = true, Type__c='Required');
        insert childRequired;
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);        
        Test.stopTest();
        List<Ticket_Item__c> tktItems = [SELECT Id, Rule_Required_Item__c, Auto_Added__c FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:pbiChildRequired];
        
        System.assertEquals(1, tktItems.size());    
        System.debug('tktItems.get(0).Auto_Added__c=' + tktItems.get(0).Auto_Added__c);
        System.assert(tktItems.get(0).Auto_Added__c == true, 'RuleAction on Child item should set Auto_Added__c=true');      
        System.assert(tktItems.get(0).Rule_Required_Item__c == true, 'RuleAction on Child item should set Rule_Required_Item__c=true');   

        Id childItemId = pbItems.get(2).Id;
        List<Ticket_Item__c> tktItems2 = [SELECT Id, Rule_Required_Item__c, Auto_Added__c FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Price_Book_Item__c =:childItemId];
        
        System.assertEquals(1, tktItems2.size());   
        System.assert(tktItems2.get(0).Auto_Added__c == false, 'Child item with no RuleAction should have Auto_Added__c=false');       
        System.assert(tktItems2.get(0).Rule_Required_Item__c == false, 'Child item with no RuleAction should have Rule_Required_Item__c=false');       
    }
    
}