@isTest
private class RuleExpression_Test
{
     static testmethod void EvalTrue_Test()
    {   
        
        //ns__Job__c!=null && ns__Tracking_Number__c!=null 
        //&& (ns__SyncID__c == 'syncId1' || ns__SyncID__c == 'syncId2' || ns__SyncID__c == 'syncId3')
        String syncId1 = StringUtility.newGuid();
        String syncId2 = StringUtility.newGuid();
        String syncId3 = StringUtility.newGuid();

        String ruleStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"!=\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Job__c\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"null\\"}}","{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"!=\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Tracking_Number__c\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"null\\"}}","&&","{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__SyncID__c\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"\'syncId1\'\\"}}","{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__SyncID__c\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"\'syncId2\'\\"}}","||","{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__SyncID__c\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"\'syncId3\'\\"}}","||","&&"]';
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace()).replace('syncId1', syncId1).replace('syncId2', syncId2).replace('syncId3', syncId3);
            
        System.debug(ruleStack);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(1, false).get(0);
        tkt.SyncID__c = syncId3;
        
        insert tkt;

        Ticket__c dbTkt = [SELECT Id, Tracking_Number__c, SyncID__c, Job__c FROM Ticket__c WHERE Id=:tkt.Id];

        Boolean r = RuleExpression.Eval(ruleStack, dbTkt);
        System.assert(r==true, 'true && true && (false || false || true) should eval to true');
    }


    static testmethod void EvalFalse_Test()
    {   
        
        //ns__Job__c!=null && ns__Tracking_Number__c!=null 
        //&& (ns__SyncID__c == 'syncId1' || ns__SyncID__c == 'syncId2' || ns__SyncID__c == 'syncId3')
        String syncId1 = StringUtility.newGuid();
        String syncId2 = StringUtility.newGuid();
        String syncId3 = StringUtility.newGuid();

        String ruleStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"!=\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Job__c\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"null\\"}}","{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"!=\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Tracking_Number__c\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"null\\"}}","&&","{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__SyncID__c\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"\'syncId1\'\\"}}","{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__SyncID__c\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"\'syncId2\'\\"}}","||","{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__SyncID__c\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"\'syncId3\'\\"}}","||","&&"]';
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace()).replace('syncId1', syncId1).replace('syncId2', syncId2).replace('syncId3', syncId3);
            
        Ticket__c tkt = AlpineTestHelper.CreateTickets(1, false).get(0);
        tkt.SyncID__c = StringUtility.newGuid();
        
        insert tkt;

        Ticket__c dbTkt = [SELECT Id, Tracking_Number__c, SyncID__c, Job__c FROM Ticket__c WHERE Id=:tkt.Id];

        Boolean r = RuleExpression.Eval(ruleStack, dbTkt);
        System.assert(r==false, 'true && true && (false || false || false) should eval to false');
    }

    static testmethod void EvalDatetimeTrue_Test()
    {   
        
        //ns__Work_Start_Date__c>'2017-03-17T11:00:00.000Z'

        String ruleStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\">\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Work_Start_Date__c\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"\'2017-03-17T11:00:00.000Z\'\\"}}"]';
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace());
              
        Ticket__c obj = new Ticket__c();
        obj.Work_Start_Date__c = Datetime.now(); 
        
        Boolean r = RuleExpression.Eval(ruleStack, obj);
        System.assert(r==true, 'Datetime comparison true');
    }

    static testmethod void EvalDatetimeFalse_Test()
    {   
        
        //ns__Work_Start_Date__c>'2017-03-17T11:00:00.000Z'

        String ruleStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\">\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Work_Start_Date__c\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"\'2017-03-17T11:00:00.000Z\'\\"}}"]';
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace());
              
        Ticket__c obj = new Ticket__c();
        obj.Work_Start_Date__c = Datetime.valueOfGmt('2017-03-17 11:00:00.000Z').addDays(-10); 
        
        Boolean r = RuleExpression.Eval(ruleStack, obj);
        System.assert(r==false, 'Datetime comparison false');
    }


    static testmethod void EvalBooleanTrue_Test()
    {   
        
        //rule ns__Sync__c == true
        String ruleStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Sync__c\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"true\\"}}"]';
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace());

        Ticket__c obj = new Ticket__c();
        obj.Sync__c = true; 
        
        Boolean r = RuleExpression.Eval(ruleStack, obj);
        System.assert(r==true, 'Boolean comparison true');
    }

    static testmethod void EvalBooleanFalse_Test()
    {   
        
        //rule ns__Sync__c == true
        String ruleStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"==\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Sync__c\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"true\\"}}"]';
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace());
              
        Ticket__c obj = new Ticket__c();
        obj.Sync__c = false; 
        
        Boolean r = RuleExpression.Eval(ruleStack, obj);
        System.assert(r==false, 'Boolean comparison false');
    }


    
    static testmethod void EvalDateFalse_Test()
    {   
        
        //rule ns__Ticket_Date__c > '2017-03-17'
        String ruleStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\">\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Ticket_Date__c\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"\'2017-03-17\'\\"}}"]';
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace());
              
        Ticket__c obj = new Ticket__c();
        obj.Ticket_Date__c = Date.valueOf('2017-03-17').addDays(-10);
        
        Boolean r = RuleExpression.Eval(ruleStack, obj);
        System.assert(r==false, 'Date comparison false');
    }
    
    static testmethod void EvalDateTrue_Test()
    {        
        //rule ns__Ticket_Date__c > '2017-03-17'
        String ruleStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\">\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Ticket_Date__c\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":\\"\'2017-03-17\'\\"}}"]';
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace());
              
        Ticket__c obj = new Ticket__c();
        obj.Ticket_Date__c = Date.valueOf('2017-03-17').addDays(20);
        
        Boolean r = RuleExpression.Eval(ruleStack, obj);
        System.assert(r==true, 'Date comparison true');
    }
    
    static testmethod void EvalCurrencyFalse_Test()
    {
        //rule criteria Price__c>100
        
        String ruleStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\">\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Price__c\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":100}}"]';
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace());
        Ticket_Item__c obj = new Ticket_Item__c();
        obj.Price__c = 50;
        
        Boolean r = RuleExpression.Eval(ruleStack, obj);
        System.assert(r==false, 'Currency comparison false');
    }
    
    static testmethod void EvalCurrencyTrue_Test()
    {
        //rule criteria Price__c>100
        
        String ruleStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\">\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Price__c\\"},\\"right\\":{\\"type\\":\\"Literal\\",\\"value\\":100}}"]';
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace());
        Ticket_Item__c obj= new Ticket_Item__c();
        obj.Price__c = 200;
        
        Boolean r = RuleExpression.Eval(ruleStack, obj);
        System.assert(r==true, 'Currency comparison true');
    }

    static testmethod void EvalIncludes_True_Test()
    {
        //rule criteria: includes(Applied_To__c, 'Ticket__c')
        
        String ruleStack = '["{\\"type\\":\\"CallExpression\\",\\"args\\":[{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Applies_To__c\\"},{\\"type\\":\\"Literal\\",\\"value\\":\\"\'Ticket__c\'\\"}],\\"callee\\":{\\"type\\":\\"Identifier\\",\\"name\\":\\"includes\\"}}"]';
       
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace());
        
        Price_Book_Rule__c r = new Price_Book_Rule__c();
        r.Applies_To__c = 'Ticket__c;Quote__c';
        
        Boolean result = RuleExpression.Eval(ruleStack, r);
        System.assert(result==true, 'MuiltiSelect picklist true');
    }


    static testmethod void EvalIncludes_false_Test()
    {
        //rule criteria: includes(Applied_To__c, 'Ticket__c')
        
        String ruleStack = '["{\\"type\\":\\"CallExpression\\",\\"args\\":[{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Applies_To__c\\"},{\\"type\\":\\"Literal\\",\\"value\\":\\"\'Ticket__c\'\\"}],\\"callee\\":{\\"type\\":\\"Identifier\\",\\"name\\":\\"includes\\"}}"]';
       
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace());
        
        Price_Book_Rule__c r = new Price_Book_Rule__c();
        r.Applies_To__c = 'Quote__c';
        
        Boolean result = RuleExpression.Eval(ruleStack, r);
        System.assert(result==false, 'MuiltiSelect picklist false');
    }
   
    static testmethod void EvalExcludes_true_Test()
    {
        //rule criteria: excludes(Applied_To__c, 'Ticket__c')
        
        String ruleStack = '["{\\"type\\":\\"CallExpression\\",\\"args\\":[{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Applies_To__c\\"},{\\"type\\":\\"Literal\\",\\"value\\":\\"\'Ticket__c\'\\"}],\\"callee\\":{\\"type\\":\\"Identifier\\",\\"name\\":\\"excludes\\"}}"]';
       
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace());
        
        Price_Book_Rule__c r = new Price_Book_Rule__c();
        r.Applies_To__c = 'Quote__c';
        
        Boolean result = RuleExpression.Eval(ruleStack, r);
        System.assert(result==true, 'MuiltiSelect picklist excludes true');
    }

    static testmethod void EvalExcludes_false_Test()
    {
        //rule criteria: excludes(Applied_To__c, 'Ticket__c')
        
        String ruleStack = '["{\\"type\\":\\"CallExpression\\",\\"args\\":[{\\"type\\":\\"Identifier\\",\\"value\\":\\"ns__Applies_To__c\\"},{\\"type\\":\\"Literal\\",\\"value\\":\\"\'Ticket__c\'\\"}],\\"callee\\":{\\"type\\":\\"Identifier\\",\\"name\\":\\"excludes\\"}}"]';
       
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace());
        
        Price_Book_Rule__c r = new Price_Book_Rule__c();
        r.Applies_To__c = 'Ticket__c;Quote__c';
        
        Boolean result = RuleExpression.Eval(ruleStack, r);
        System.assert(result==false, 'MuiltiSelect picklist excludes false');
    }


    static testmethod void EvalContains_true_Test()
    {
        //rule criteria: excludes(Job__r.Name, 'LFW Test Job')
        
        
        String ruleStack = '["{\\"type\\":\\"CallExpression\\",\\"args\\":[{\\"type\\":\\"MemberExpression\\",\\"value\\":\\"ns__Job__r.Name\\"},{\\"type\\":\\"Literal\\",\\"value\\":\\"\'LFW Test Job\'\\"}],\\"callee\\":{\\"type\\":\\"Identifier\\",\\"name\\":\\"contains\\"}}"]';
       
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace());

        Job__c j = AlpineTestHelper.CreateJobs(1, false).get(0);
        j.Name = 'LFW Test Job' + StringUtility.newGuid();       
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(1, false).get(0);
        tkt.Job__r = j;
        
        Boolean result = RuleExpression.Eval(ruleStack, tkt);
        System.assert(result==true, 'Contains string true');
    }

    static testmethod void EvalContains_false_Test()
    {
        //rule criteria: excludes(Job__r.Name, 'LFW Test Job')
        
        String ruleStack = '["{\\"type\\":\\"CallExpression\\",\\"args\\":[{\\"type\\":\\"MemberExpression\\",\\"value\\":\\"ns__Job__r.Name\\"},{\\"type\\":\\"Literal\\",\\"value\\":\\"\'LFW Test Job\'\\"}],\\"callee\\":{\\"type\\":\\"Identifier\\",\\"name\\":\\"contains\\"}}"]';
       
        ruleStack = ruleStack.replace('ns__', StringUtility.FXNamespace());

        Job__c j = AlpineTestHelper.CreateJobs(1, false).get(0);
        j.Name = 'Job' + StringUtility.newGuid();       
       
        Ticket__c tkt = AlpineTestHelper.CreateTickets(1, false).get(0);
        tkt.Job__r = j;
        
        Boolean result = RuleExpression.Eval(ruleStack, tkt);
        System.assert(result==false, 'Contains string false');
    }
}