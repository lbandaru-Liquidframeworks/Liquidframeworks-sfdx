@isTest
private class RuleEngine_TicketItemRule_Test {
    
    static Price_Book_Rule__c CreateNullRule(String ruleName, Id pbId, String field, String op)
    {
        return CreateRule(ruleName, pbId, field, '', op, true);
    }

    static Price_Book_Rule__c CreateNullRule(String ruleName, Id pbId, String field, String op, Boolean saveNow)
    {
        return CreateRule(ruleName, pbId, field, '', op, saveNow);
    }
    static Price_Book_Rule__c CreateRule(String ruleName, Id pbId, String field, 
        String value, String op, Boolean saveNow)
    {
        String ns = UtilityGetNamespace.CurrentNamespace();

        field = field.replace('[ns]', ns);

        String criteria = String.isBlank(value)? field + ' ' + op + ' null ' : field + ' ' + op + '\'' + value + '\'';

        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"[op]\\",\\"left\\":{\\"type\\":\\"[expType]\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"[value]\\"}}"]';

        String valueStr = String.isBlank(value)? 'null' : value;

        criteriaStack = criteriaStack.replace('[fieldName]', field).replace('[value]', valueStr).replace('[op]', op);

        if(field.indexOf('.')>0)
        {
            criteriaStack = criteriaStack.replace('[expType]', 'MemberExpression');
        }
        else
        {
            criteriaStack = criteriaStack.replace('[expType]', 'Identifier');
        }

        Price_Book_Rule__c rule = new Price_Book_Rule__c(Price_Book__c = pbId, IsActive__c=true, 
            Criteria__c=criteria,
            CriteriaStack__c = criteriaStack);
        if(!String.isBlank(ruleName))
        {
            rule.Name = ruleName;
        }
        System.debug('Criteria: ' + rule.Criteria__c);
        System.debug('Stack: ' + rule.CriteriaStack__c);
        if(saveNow) insert rule;
        return rule;
    }

    
    static TestMethod void GetDisallowedPriceBookItemsForTicketItem_Test()
    {
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id pbId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, pbId , 'Equipment', true);   
        Price_Book_Item__c rootItem = pbItems.get(0);
       
        Price_Book_Rule__c rule = CreateNullRule('Unit Test TicketItem child Disallowed Rule',
            pbId, '[ns]Ticket__r.[ns]Tracking_Number__c', '!=', false);
        rule.Price_Book_Item__c = rootItem.Id;
        insert rule;
     
        Price_Book_Item__c disallowedItem = pbItems.get(1);

        Price_Book_Rule_Action__c tktItemRuleAction = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, 
            Price_Book_Item__c = disallowedItem.Id, 
            IsActive__c = true, 
            Type__c='Disallowed');
       

        insert tktItemRuleAction;      


        Test.startTest();

        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, false).get(0);


        String newGuid = StringUtility.newGuid();
         
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  

        string statusName = 'Status ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st;
        
        tkt.Status__c = st.Id;
        insert tkt;

        Ticket_Item__c ti = (Ticket_Item__c)Ticket_Item__c.sObjectType.newSObject();
        ti.Ticket__c = tkt.Id;
        ti.Price_Book_Item__c = rootItem.Id;

        insert ti;       
      
        
        List<Id> disallowedItems = RuleEngineCore.GetDisallowedPriceBookItems(ti.Id);
        Test.StopTest();
        
        System.assert(disallowedItems.size()==1,  'Should have one disallowed item');
        System.assert(disallowedItems.get(0) == disallowedItem.Id,  'return ' + disallowedItems.get(0) + ' instead of ' + disallowedItem.Id);
    }
    
   
    static TestMethod void ManuallyAddDisallowedItem_Test()
    {
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id pbId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, pbId , 'Equipment', true);   
        Price_Book_Item__c rootItem = pbItems.get(0);       

        Price_Book_Rule__c rule = CreateNullRule('Unit Test TicketItem child Disallowed Rule',
            pbId, '[ns]Ticket__r.[ns]Tracking_Number__c', '!=', false);
        rule.Price_Book_Item__c = rootItem.Id;
        insert rule;
     
    
     
        Price_Book_Item__c disallowedItem = pbItems.get(1);

        Price_Book_Rule_Action__c tktItemRuleAction = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, 
            Price_Book_Item__c = disallowedItem.Id, 
            IsActive__c = true, 
            Type__c='Disallowed');
       

        insert tktItemRuleAction;      


        Test.startTest();

        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, false).get(0);


        String newGuid = StringUtility.newGuid();
         
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  

        string statusName = 'Status ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st;
        
        tkt.Status__c = st.Id;
        insert tkt;

        Ticket_Item__c ti = (Ticket_Item__c)Ticket_Item__c.sObjectType.newSObject();
        ti.Ticket__c = tkt.Id;
        ti.Price_Book_Item__c = rootItem.Id;

        insert ti;
        
        Ticket_Item__c childItem = (Ticket_Item__c)Ticket_Item__c.sObjectType.newSObject();
        childItem.Ticket__c = tkt.Id;
        childItem.Price_Book_Item__c = disallowedItem.Id;
        childItem.Parent_Ticket_Item__c = ti.Id;
        
        try
        {
            Database.SaveResult sr = Database.insert(childItem);
             System.assert(sr.isSuccess() == false,  'Manually adding disallowd item should fail');
        }
        catch(System.DmlException e)
        {
            String msg = '';
            for (Integer i = 0; i < e.getNumDml(); i++) 
            {
            
                msg += e.getDmlMessage(i); 
            }
            System.assert(msg.contains('Disallowed by Rule -'), 'Manually adding disallowd item should fail with DmlException');
        }     
    }
    
    static TestMethod void TwoRulesOnTheSameItem_Test()
    {
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id pbId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, pbId , 'Equipment', true);   
        Price_Book_Item__c requiredItem = pbItems.get(0);

        Price_Book_Rule__c rule1 = CreateNullRule('',
            pbId, '[ns]Ticket__r.[ns]Tracking_Number__c', '!=', false);
        rule1.Price_Book_Item__c = requiredItem.Id;
        insert rule1;
        
        Price_Book_Rule__c rule2 = CreateNullRule('',
            pbId, '[ns]Ticket__r.[ns]SyncID__c', '!=', false);
        rule2.Price_Book_Item__c = requiredItem.Id;
        insert rule2;
     
        List<Price_Book_Rule_Action__c > ruleActions = new List<Price_Book_Rule_Action__c>();

        ruleActions.add(new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule1.Id, 
            Price_Book_Item__c = pbItems.get(1).Id, 
            IsActive__c = true, 
            Type__c='Required'));
            
        ruleActions.add(new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule2.Id, 
            Price_Book_Item__c = pbItems.get(1).Id, 
            IsActive__c = true, 
            Type__c='Required'));       

        insert ruleActions;      


        Test.startTest();

        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, false).get(0);


        String newGuid = StringUtility.newGuid();
         
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  

        string statusName = 'Status ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st;
        
        tkt.Status__c = st.Id;
        insert tkt;

        Ticket_Item__c ti = (Ticket_Item__c)Ticket_Item__c.sObjectType.newSObject();
        ti.Ticket__c = tkt.Id;
        ti.Price_Book_Item__c = requiredItem.Id;

        insert ti;

        Test.stopTest();

        List<Ticket_Item__c> tktItems = [SELECT Id FROM Ticket_Item__c WHERE Parent_Ticket_Item__c = :ti.Id];

        System.assert(tktItems.size() == 1, 'should have one child tkt items, but instead has ' + tktItems.size());


    }


   static TestMethod void InsertTicketItem_Test()
    {
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id pbId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, pbId , 'Equipment', true);   
        Price_Book_Item__c requiredItem = pbItems.get(0);

        Price_Book_Rule__c tiRule = CreateNullRule('',
            pbId, '[ns]Ticket__r.[ns]Tracking_Number__c', '!=', false);
        tiRule.Price_Book_Item__c= requiredItem.Id;
        insert tiRule;

        Price_Book_Rule_Action__c tktItemRuleAction = new Price_Book_Rule_Action__c(Price_Book_Rule__c = tiRule.Id, 
            Price_Book_Item__c = pbItems.get(1).Id, 
            IsActive__c = true, 
            Type__c='Required');
       

        insert tktItemRuleAction;      


        Test.startTest();

        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, false).get(0);


        String newGuid = StringUtility.newGuid();
         
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  

        string statusName = 'Status ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st;
        
        tkt.Status__c = st.Id;
        insert tkt;

        Ticket_Item__c ti = (Ticket_Item__c)Ticket_Item__c.sObjectType.newSObject();
        ti.Ticket__c = tkt.Id;
        ti.Price_Book_Item__c = requiredItem.Id;

        insert ti;

        Test.stopTest();

        List<Ticket_Item__c> tktItems = [SELECT Id FROM Ticket_Item__c WHERE Parent_Ticket_Item__c = :ti.Id];

        System.assert(tktItems.size() == 1, 'should have one child tkt items, but instead has ' + tktItems.size());


    }


    static TestMethod void InsertTicket_Test()
    {
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id pbId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(2, pbId , 'Equipment', true);   
        Price_Book_Item__c requiredItem = pbItems.get(0);
        Price_Book_Item__c tktItemRuleChildItem = pbItems.get(1);
        
        Price_Book_Rule__c rule = CreateNullRule('', pbId, '[ns]Tracking_Number__c', '!=');

        Price_Book_Rule__c tiRule = CreateNullRule('',
            pbId, '[ns]Ticket__r.[ns]Tracking_Number__c', '!=', false);
        tiRule.Price_Book_Item__c= requiredItem.Id;
        insert tiRule;

        
        List<Price_Book_Rule_Action__c> actions = new List<Price_Book_Rule_Action__c>();
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = requiredItem.Id, IsActive__c = true, Type__c='Required');
        actions.add(action);



        Price_Book_Rule_Action__c tktItemRuleAction = new Price_Book_Rule_Action__c(Price_Book_Rule__c = tiRule.Id, 
            Price_Book_Item__c =tktItemRuleChildItem.Id, 
            IsActive__c = true, 
            Type__c='Required');
        actions.add(tktItemRuleAction);

        insert actions;      


        Test.startTest();

        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, false).get(0);

        String newGuid = StringUtility.newGuid();
         
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  

        string statusName = 'Status ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st;
        
        tkt.Status__c = st.Id;
        insert tkt;


        Test.stopTest();

        List<Ticket_Item__c> tktItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c = :tkt.Id];

        System.assert(tktItems.size() == 2, 'should have two tkt items, but instead has ' + tktItems.size());


    }


    static TestMethod void UpdateTicket_Test()
    {
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id pbId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(2, pbId , 'Equipment', true);   
        Price_Book_Item__c requiredItem = pbItems.get(0);
        Price_Book_Item__c tktItemRuleChildItem = pbItems.get(1);

        String newGuid = StringUtility.newGuid();

      

        Price_Book_Rule__c rule = CreateNullRule('',
            pbId, '[ns]Tracking_Number__c', '!=');   


        Price_Book_Rule__c tiRule  = CreateRule('', pbId, '[ns]Ticket__r.[ns]Status__r.Name', 's2'+ newGuid, '==', false);
        tiRule.Price_Book_Item__c= requiredItem.Id;
        insert tiRule;

        
        List<Price_Book_Rule_Action__c> actions = new List<Price_Book_Rule_Action__c>();
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, 
            Price_Book_Item__c = requiredItem.Id, IsActive__c = true, 
            Type__c='Required');
        actions.add(action);



        Price_Book_Rule_Action__c tktItemRuleAction = new Price_Book_Rule_Action__c(Price_Book_Rule__c = tiRule.Id, 
            Price_Book_Item__c = tktItemRuleChildItem.Id, 
            IsActive__c = true, 
            Type__c='Required');
        actions.add(tktItemRuleAction);

        insert actions;      


        Test.startTest();

        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, false).get(0);

      
         
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  

        List<Status__c> tktStatus = new List<Status__c>();
        String statusName = 'Status ' + newGuid;
        Status__c st = new Status__c(Name = statusName, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        tktStatus.add(st);

        Status__c st2 = new Status__c(Name = 's2'+newGuid, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        tktStatus.add(st2);

        insert tktStatus;
        
        tkt.Status__c = st.Id;
        insert tkt;

        List<Ticket_Item__c> tktItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c=:tkt.Id AND Price_Book_Item__c=:requiredItem.Id];
        System.assert(tktItems.size()==1, 'Ticket should have ONE tkt items');

        tkt.Customer_Survey_Satisfaction__c = 'Disappointed';
        update tkt;

        tktItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c=:tkt.Id];
        System.assert(tktItems.size()==1, 'Ticket should have not add child tkt items upon update on non-criteria field');

        tkt.Status__c = st2.Id;
        update tkt;

        Test.stopTest();

        tktItems = [SELECT Id, Price_Book_Item__c, Auto_Added__c, Rule_Required_Item__c FROM Ticket_Item__c 
            WHERE Ticket__c=:tkt.Id 
                AND Price_Book_Item__c =:tktItemRuleChildItem.Id
                AND Parent_Ticket_Item__r.Price_Book_Item__c =:requiredItem.Id];

        System.assert(tktItems.size()==1, 'Ticket should have ONE child tkt items upon update on criteria field');

        Ticket_Item__c ti = tktItems.get(0);

        System.assert(ti.Auto_Added__c ==true, 'Ticket Item should have  Auto_Added__c=true');
        System.assert(ti.Rule_Required_Item__c == true, 'Ticket Item should have  Rule_Required_Item__c=true');    


    }

    static TestMethod void UpdateJob_Test()
    {
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id pbId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(2, pbId , 'Equipment', true);   
        Price_Book_Item__c requiredItem = pbItems.get(0);
        Price_Book_Item__c tktItemRuleChildItem = pbItems.get(1);

        String newGuid = StringUtility.newGuid();

      
        Price_Book_Rule__c rule = CreateNullRule('', pbId, '[ns]Tracking_Number__c', '!=');          


        Price_Book_Rule__c tiRule  = CreateRule('', pbId, '[ns]Ticket__r.[ns]Job__r.[ns]Status__r.Name', 's2'+ newGuid, '==', false);
        tiRule.Price_Book_Item__c= requiredItem.Id;
        insert tiRule;
        
        List<Price_Book_Rule_Action__c> actions = new List<Price_Book_Rule_Action__c>();
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, 
            Price_Book_Item__c = requiredItem.Id, IsActive__c = true, 
            Type__c='Required');
        actions.add(action);



        Price_Book_Rule_Action__c tktItemRuleAction = new Price_Book_Rule_Action__c(Price_Book_Rule__c = tiRule.Id, 
            Price_Book_Item__c = tktItemRuleChildItem.Id, 
            IsActive__c = true, 
            Type__c='Required');
        actions.add(tktItemRuleAction);

        insert actions;      


        Test.startTest();

        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, false).get(0);

      
         
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  

        List<Status__c> statusItems = new List<Status__c>();
        Status__c tktStatus  = new Status__c(Name = 's1' + newGuid, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        statusItems.add(tktStatus);

        Status__c jobStatus = new Status__c(Name = 's2'+newGuid, SObject__c='Job__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        statusItems.add(jobStatus);

        insert statusItems;
        
        tkt.Status__c = tktStatus.Id;
        insert tkt;

        List<Ticket_Item__c> tktItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c=:tkt.Id AND Price_Book_Item__c=:requiredItem.Id];
        System.assert(tktItems.size()==1, 'Ticket should have ONE tkt items');

        Job__c dbJob = [SELECT Id, Notes__c, Status__c FROM Job__c WHERE Id=:job.Id];
        dbJob.Notes__c ='Unit test updating Notes';
        update dbJob;

        tktItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c=:tkt.Id];
        System.assert(tktItems.size()==1, 'Should not add child tkt items upon update on non-criteria field');

        dbJob.Status__c = jobStatus.Id;
        update dbJob;

        Test.stopTest();

        tktItems = [SELECT Id, Price_Book_Item__c, Auto_Added__c, Rule_Required_Item__c FROM Ticket_Item__c 
            WHERE Ticket__c=:tkt.Id 
                AND Price_Book_Item__c =:tktItemRuleChildItem.Id
                AND Parent_Ticket_Item__r.Price_Book_Item__c =:requiredItem.Id];

        System.assert(tktItems.size()==1, 'Ticket should have ONE child tkt items upon update on criteria field');

        Ticket_Item__c ti = tktItems.get(0);

        System.assert(ti.Auto_Added__c ==true, 'Ticket Item should have  Auto_Added__c=true');
        System.assert(ti.Rule_Required_Item__c == true, 'Ticket Item should have  Rule_Required_Item__c=true');    


    }




    static void InitTest(Id pbId)
    {     
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, pbId , 'Equipment', true);   
        Price_Book_Item__c requiredItem = pbItems.get(0);      
        Price_Book_Rule__c rule = CreateNullRule('', pbId, '[ns]Tracking_Number__c', '!=');          

        Price_Book_Rule__c tiRule  = CreateNullRule('', pbId, '[ns]Ticket__r..[ns]Tracking_Number__c', '!=');        
        List<Price_Book_Rule_Action__c> actions = new List<Price_Book_Rule_Action__c>();
        Price_Book_Rule_Action__c action = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = requiredItem.Id, IsActive__c = true, Type__c='Required');
        actions.add(action);

        Price_Book_Rule_Action__c tktItemRuleAction = new Price_Book_Rule_Action__c(Price_Book_Rule__c = tiRule.Id, 
            Price_Book_Item__c = pbItems.get(1).Id, 
            IsActive__c = true, 
            Type__c='Required');
        actions.add(tktItemRuleAction);

        insert actions;      

    }


}
