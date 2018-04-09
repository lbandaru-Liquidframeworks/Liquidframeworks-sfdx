@isTest
private class SObjectCloner_Test
{

    static testMethod void ClonerWithFilter_Test()
    {
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        List<Ticket__c> tkts = AlpineTestHelper.CreateTickets(job, 2, true);

        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(2, job.Price_Book__c, 'Equipment', true);

        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();

        List<Ticket__c> dbTkts = [SELECT Id FROM Ticket__c WHERE Job__c =:job.Id];
        Ticket__c tkt1 = dbTkts.get(0);
        Ticket__c tkt2 = dbTkts.get(1);
        tkt1.Sync__c = true;
        tkt2.Sync__c = false;
        update dbTkts;


        tktItems.add(new Ticket_Item__c(Ticket__c = tkt1.Id, Price_Book_Item__c = pbItems.get(0).Id));
        tktItems.add(new Ticket_Item__c(Ticket__c = tkt2.Id, Price_Book_Item__c = pbItems.get(1).Id));
        
        insert tktItems;

        Test.startTest();

        Integer count = [SELECT COUNT() FROM Ticket_Item__c WHERE Ticket__c =:tkt2.Id];
        System.assert(count == 1, 'BEFORE: should have 1 ticket item instead of ' + count);

        
        String ns = StringUtility.FXNamespace();

        String sources = job.Id;

        

        String cloningtypes = 'ns__Ticket__c{ns__Sync__c=true},ns__Ticket_Item__c';
        cloningtypes = cloningtypes.replace('ns__', ns); 
        
        System.debug(SObjectCloner.DeepCopy(job.Id, cloningtypes));

        Test.stopTest();
        count = [SELECT COUNT() FROM Ticket_Item__c];
        System.assert(count == 3, 'AFTER: should have total 3 ticket item, instead of ' + count);
        
        count = [SELECT COUNT() FROM Ticket_Item__c WHERE Ticket__c =:tkt1.Id];
        System.assert(count == 1, 'AFTER: should have 1 ticket item on tkt1, instead of ' + count);
        
        count = [SELECT COUNT() FROM Ticket_Item__c WHERE Ticket__c =:tkt2.Id];
        System.assert(count == 1, 'AFTER: should have 1 ticket item on tkt2, instead of ' + count);
    }

    static testMethod void CommandCloner_DryRun_Test()
    {

        List<Job__c> jobs = AlpineTestHelper.CreateJobs(2, true);
        AlpineTestHelper.CreateTickets(jobs.get(0), 20, true);
        Test.startTest();
        Set<Id> jobIds = new Map<Id, Job__c>(jobs).keySet();
        String ns = StringUtility.FXNamespace();

        String sources = StringUtility.GetJoinedString(jobIds);

        Map<String, Object> params = new Map<String, Object>();
        params.put('sources', sources);
        params.put('cloningtypes', String.format('{0}Crew_Planning__c,{0}Equipment_Planning__c,{0}Ticket__c,{0}Ticket_Item__c', new String[]{ns})); 
       

        System.debug(FXBatchableLauncher.Run(ns + 'SObjectClonerBatchable', params, true));

        Test.stopTest();
    }
    
    static testMethod void CommandCloner_Test()
    {
        List<Job__c> jobs = AlpineTestHelper.CreateJobs(2, true);
        AlpineTestHelper.CreateTickets(jobs.get(0), 20, true);
        Test.startTest();
        Set<Id> jobIds = new Map<Id, Job__c>(jobs).keySet();
        String ns = StringUtility.FXNamespace();

        String sources = StringUtility.GetJoinedString(jobIds);

        Map<String, Object> params = new Map<String, Object>();
        params.put('sources', sources);
        params.put('cloningtypes', String.format('{0}Crew_Planning__c,{0}Equipment_Planning__c,{0}Ticket__c,{0}Ticket_Item__c', new String[]{ns}));
 
        FXBatchableLauncher.Run(ns + 'SObjectClonerBatchable', params);

        Test.stopTest();
    }

    static testMethod void SObjectCloner_Test() 
    {
        Test.startTest();

        Integer level1Count = 20;
        Integer level2Count = 20;

        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(level1Count, pb.Id, 'Equipment', true);

        List<Price_Book_Item__c> childPbItems = AlpineTestHelper.CreatePriceBookItems(level2Count, pb.Id, 'Equipment', false);
        Integer i = 0;
        for(Price_Book_Item__c c : childPbItems)
        {
            Price_Book_Item__c parent = pbItems.get(i);
            c.Parent_Price_Book_Item__c = parent.Id;
            i++;
        }
        insert childPbItems;

        Integer sourceCount = [SELECT COUNT() FROM Price_Book_Item__c WHERE Price_Book__c =:pb.Id];
        System.assert(sourceCount == level1Count + level2Count, 'should have ' + (level1Count + level2Count) + ' source items, instead of ' + sourceCount);
        Price_Book_Rule__c r = CreateRule(pb.Id);

        Price_Book_Rule_Action__c ra = new Price_Book_Rule_Action__c(Price_Book_Rule__c = r.Id, Price_Book_Item__c = pbItems.get(0).Id, Type__c = 'Required');
        insert ra;

    
        String cloneTypes = '[ns]Price_Book_Item__c,[ns]Price_Book_Rule__c,[ns]Price_Book_Rule_Action__c'.replace('[ns]', UtilityGetNamespace.CurrentNamespace());

        String newId = SObjectCloner.DeepCopy(pb.Id, cloneTypes, SObjectCloner.ExecMode.Sync);       
        sObject copyItem = SObjectDescribeInfo.GetSObject(Id.valueOf(newId));
       
        Test.stopTest();

        System.debug('copy=' + copyItem);

        
        Price_Book__c pbNew =  (Price_Book__c)copyItem;

        List<Price_Book_Item__c> allItems = [SELECT Id FROM Price_Book_Item__c WHERE Price_Book__c=:pbNew.Id];
        System.assertEquals(level1Count + level2Count, allItems.size());


        List<Price_Book_Item__c> level2Items = [SELECT Id FROM Price_Book_Item__c WHERE Price_Book__c=:pbNew.Id AND Parent_Price_Book_Item__c!=null];
        System.assertEquals(level2Count, level2Items.size());

        List<Price_Book_Rule__c> newRules = [SELECT Id FROM Price_Book_Rule__c WHERE Price_Book__c=:pbNew.Id];
        System.assertEquals(1, newRules.size());

        List<Price_Book_Rule_Action__c> newRuleActions = [SELECT Id FROM Price_Book_Rule_Action__c WHERE Price_Book_Rule__r.Price_Book__c=:pbNew.Id AND Price_Book_Item__r.Price_Book__c =:pbNew.Id];
        System.assertEquals(1, newRuleActions.size());


    }


    static testMethod void SObjectCloner_DryRun_Test() 
    {
        Test.startTest();

        Integer level1Count = 100;
        Integer level2Count = 20;

        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(level1Count, pb.Id, 'Equipment', true);

        List<Price_Book_Item__c> childPbItems = AlpineTestHelper.CreatePriceBookItems(level2Count, pb.Id, 'Equipment', false);
        Integer i = 0;
        for(Price_Book_Item__c c : childPbItems)
        {
            Price_Book_Item__c parent = pbItems.get(i);
            c.Parent_Price_Book_Item__c = parent.Id;
            i++;
        }
        insert childPbItems;

        Price_Book_Rule__c r = CreateRule(pb.Id);

        Price_Book_Rule_Action__c ra = new Price_Book_Rule_Action__c(Price_Book_Rule__c = r.Id, Price_Book_Item__c = pbItems.get(0).Id, Type__c = 'Required');
        insert ra;

    
        String cloneTypes = '[ns]Price_Book__c,[ns]Price_Book_Item__c,[ns]Price_Book_Rule__c,[ns]Price_Book_Rule_Action__c'.replace('[ns]', UtilityGetNamespace.CurrentNamespace());

        String str = SObjectCloner.DryRun(pb.Id, cloneTypes);       
       
        Test.stopTest();
    }


    static testMethod void SObjectCloner_DeepCopyAsync_Test() 
    {
        Test.startTest();

        Integer level1Count = 100;
        Integer level2Count = 20;

        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(level1Count, pb.Id, 'Equipment', true);

        List<Price_Book_Item__c> childPbItems = AlpineTestHelper.CreatePriceBookItems(level2Count, pb.Id, 'Equipment', false);
        Integer i = 0;
        for(Price_Book_Item__c c : childPbItems)
        {
            Price_Book_Item__c parent = pbItems.get(i);
            c.Parent_Price_Book_Item__c = parent.Id;
            i++;
        }
        insert childPbItems;

        Price_Book_Rule__c r = CreateRule(pb.Id);

        Price_Book_Rule_Action__c ra = new Price_Book_Rule_Action__c(Price_Book_Rule__c = r.Id, Price_Book_Item__c = pbItems.get(0).Id, Type__c = 'Required');
        insert ra;
   
        String cloneTypes = '[ns]Price_Book__c,[ns]Price_Book_Item__c,[ns]Price_Book_Rule__c,[ns]Price_Book_Rule_Action__c'.replace('[ns]', UtilityGetNamespace.CurrentNamespace());

        String str = SObjectCloner.DeepCopy(pb.Id, cloneTypes, SObjectCloner.ExecMode.Async);       
       
        Test.stopTest();
    }

    static Price_Book_Rule__c CreateRule(Id pbId)
    {
        String ns = StringUtility.FXNamespace();
        String fieldName = ns + 'Job__r.' + ns + 'Office__r.Name';

        String criteria = fieldName + '!=\'Houston\'';

        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"!=\\",\\"left\\":{\\"type\\":\\"MemberExpression\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"Houston\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', fieldName);
        Price_Book_Rule__c r = new Price_Book_Rule__c(Price_Book__c = pbId, 
            IsActive__c=true, Criteria__c=criteria, Applies_To__c='Ticket__c',
            CriteriaQueryFields__c = fieldName,
            CriteriaStack__c = criteriaStack);

        if (AlpineTestHelper.HasCurrencyIso()) {
            r.put('CurrencyIsoCode', 'USD');
        }
        insert r;
        return r;
    }
    static testMethod void DeepCopyPriceBook_VF_Test() 
    {
        Test.startTest();

        Integer level1Count = 40;
        Integer level2Count = 40;

        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(level1Count, pb.Id, 'Equipment', true);

        List<Price_Book_Item__c> childPbItems = AlpineTestHelper.CreatePriceBookItems(level2Count, pb.Id, 'Equipment', false);
        Integer i = 0;
        for(Price_Book_Item__c c : childPbItems)
        {
            Price_Book_Item__c parent = pbItems.get(i);
            c.Parent_Price_Book_Item__c = parent.Id;
            i++;
        }
        insert childPbItems;

        Price_Book_Rule__c r = CreateRule(pb.Id);

        Price_Book_Rule_Action__c ra = new Price_Book_Rule_Action__c(Price_Book_Rule__c = r.Id, Price_Book_Item__c = pbItems.get(0).Id, Type__c = 'Required');
        insert ra;

        PageReference p = Page.sObjectEntityCloner;
        String ns = StringUtility.FXNamespace();
        String cloneTypes = '[ns]Price_Book__c,[ns]Price_Book_Item__c,[ns]Price_Book_Rule__c,[ns]Price_Book_Rule_Action__c'.replace('[ns]', ns);

        p.getParameters().put('id', pb.Id);
        p.getParameters().put('cloningtypes', cloneTypes);
        p.getParameters().put('sync', '');
        Test.setCurrentPage(p);        
        sObjectCloningController ctrl = new sObjectCloningController();  
        ctrl.redirect();
       
        Test.stopTest();

        System.debug('copy=' + ctrl.EntityCopy);

        
        Price_Book__c pbNew =  (Price_Book__c)ctrl.EntityCopy;

        List<Price_Book_Item__c> allItems = [SELECT Id FROM Price_Book_Item__c WHERE Price_Book__c=:pbNew.Id];
        System.assertEquals(level1Count + level2Count, allItems.size());


        List<Price_Book_Item__c> level2Items = [SELECT Id FROM Price_Book_Item__c WHERE Price_Book__c=:pbNew.Id AND Parent_Price_Book_Item__c!=null];
        System.assertEquals(level2Count, level2Items.size());

        List<Price_Book_Rule__c> newRules = [SELECT Id FROM Price_Book_Rule__c WHERE Price_Book__c=:pbNew.Id];
        System.assertEquals(1, newRules.size());

        List<Price_Book_Rule_Action__c> newRuleActions = [SELECT Id FROM Price_Book_Rule_Action__c WHERE Price_Book_Rule__r.Price_Book__c=:pbNew.Id AND Price_Book_Item__r.Price_Book__c =:pbNew.Id];
        System.assertEquals(1, newRuleActions.size());
 

    }

    static testMethod void DeepCopyPriceBook_VF_WithCustomFilter_Test() 
    {
        Test.startTest();

        Integer level1Count = 5;
        Integer level2Count = 5;

        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(level1Count, pb.Id, 'Equipment', true);

        List<Price_Book_Item__c> childPbItems = AlpineTestHelper.CreatePriceBookItems(level2Count, pb.Id, 'Equipment', false);
        Integer i = 0;
        for(Price_Book_Item__c c : childPbItems)
        {
            Price_Book_Item__c parent = pbItems.get(i);
            c.Parent_Price_Book_Item__c = parent.Id;
            i++;
        }
        insert childPbItems;

        Price_Book_Rule__c r = CreateRule(pb.Id);

        Price_Book_Rule_Action__c ra = new Price_Book_Rule_Action__c(Price_Book_Rule__c = r.Id, Price_Book_Item__c = pbItems.get(0).Id, Type__c = 'Required');
        insert ra;

        PageReference p = Page.sObjectEntityCloner;
        String cloneTypes = '[ns]Price_Book__c,[ns]Price_Book_Item__c{[ns]Parent_Price_Book_Item__c=null},[ns]Price_Book_Rule__c,[ns]Price_Book_Rule_Action__c'.replace('[ns]', UtilityGetNamespace.CurrentNamespace());

        p.getParameters().put('id', pb.Id);
        p.getParameters().put('cloningtypes', cloneTypes);
        p.getParameters().put('sync', cloneTypes);
        Test.setCurrentPage(p);        
        sObjectCloningController ctrl = new sObjectCloningController();         
        ctrl.redirect();
       
        Test.stopTest();

        System.debug('copy=' + ctrl.EntityCopy);

        
        Price_Book__c pbNew =  (Price_Book__c)ctrl.EntityCopy;

        List<Price_Book_Item__c> allItems = [SELECT Id FROM Price_Book_Item__c WHERE Price_Book__c=:pbNew.Id];
        System.assertEquals(level1Count, allItems.size());
    

        List<Price_Book_Rule__c> newRules = [SELECT Id FROM Price_Book_Rule__c WHERE Price_Book__c=:pbNew.Id];
        System.assertEquals(1, newRules.size());

        List<Price_Book_Rule_Action__c> newRuleActions = [SELECT Id FROM Price_Book_Rule_Action__c WHERE Price_Book_Rule__r.Price_Book__c=:pbNew.Id AND Price_Book_Item__r.Price_Book__c =:pbNew.Id];
        System.assertEquals(1, newRuleActions.size());
 

    }

    static testMethod void DeepCopyPriceBook_VF_WithCustomStringFilter_Test() 
    {
        Test.startTest();

        Integer level1Count = 5;
        Integer level2Count = 5;
        Integer supplyCount = 5;


        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(level1Count, pb.Id, 'Equipment', true);
        List<Price_Book_Item__c> supplyItems = AlpineTestHelper.CreatePriceBookItems(supplyCount, pb.Id, 'Supply', true);

        List<Price_Book_Item__c> childPbItems = AlpineTestHelper.CreatePriceBookItems(level2Count, pb.Id, 'Equipment', false);
        Integer i = 0;
        for(Price_Book_Item__c c : childPbItems)
        {
            Price_Book_Item__c parent = pbItems.get(i);
            c.Parent_Price_Book_Item__c = parent.Id;
            i++;
        }
        insert childPbItems;

        Price_Book_Rule__c r = CreateRule(pb.Id);

        Price_Book_Rule_Action__c ra = new Price_Book_Rule_Action__c(Price_Book_Rule__c = r.Id, Price_Book_Item__c = pbItems.get(0).Id, Type__c = 'Required');
        insert ra;

        PageReference p = Page.sObjectEntityCloner;
        String cloneTypes = '[ns]Price_Book__c,[ns]Price_Book_Item__c{[ns]Parent_Price_Book_Item__c=null AND [ns]Ticket_Item_Record_Type__c=\'Equipment\'},[ns]Price_Book_Rule__c,[ns]Price_Book_Rule_Action__c'.replace('[ns]', UtilityGetNamespace.CurrentNamespace());

        p.getParameters().put('id', pb.Id);
        p.getParameters().put('cloningtypes', cloneTypes);
         p.getParameters().put('sync', '');
        Test.setCurrentPage(p);        
        sObjectCloningController ctrl = new sObjectCloningController();         
        ctrl.redirect();
       
        Test.stopTest();

        System.debug('copy=' + ctrl.EntityCopy);

        
        Price_Book__c pbNew =  (Price_Book__c)ctrl.EntityCopy;

        List<Price_Book_Item__c> allItems = [SELECT Id FROM Price_Book_Item__c WHERE Price_Book__c=:pbNew.Id];
        System.assertEquals(level1Count, allItems.size());      
 

    }

}