@isTest
private class JobPropagator_Test
{
    static testmethod void RunForCodeCoverage()
    {
        Map<String, String> formKeySObjs = new Map<String, String>();
        String ns = StringUtility.FXNamespace();
        JobPropagator.GetPathsToJob(Ticket__c.sObjectType.getDescribe());
        formKeySObjs.put(ns + 'Ticket__c', ns + 'Job__c');
        JobPropagator.formKeySObjs = formKeySObjs;
        JobPropagator.GetPathsToJob(Ticket__c.sObjectType.getDescribe());

        Job__c j = AlpineTestHelper.CreateJobs(1, false).get(0);
        insert j;
        Ticket__c tkt = AlpineTestHelper.CreateTickets(j, 1, false).get(0);
        insert tkt;
        Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem;
        Price_Book_Item__c pli1 = new Price_Book_Item__c(Price_Book__c = j.Price_Book__c, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli1;
        Ticket_Item__c tktItem  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pli1.Id);
        insert tktItem;   
        JobPropagator.GetJobID(tktItem, ns + 'Ticket__r.' + ns + 'Job__c');


    }
    static testmethod void TicketLog_TurnOffJobPropagator_Test()
    {
        Test.startTest();
        FX_Settings__c setting = FXSettingHelper.FXSettings; 
        setting.TurnOffJobPropagator__c =  true;
        upsert setting;

        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, true).get(0);
        List<Ticket_Log__c> objs = new List<Ticket_Log__c>();
        insert new Ticket_Log__c(Ticket__c = tkt.Id, Start_Time__c = Datetime.now());
        Test.stopTest();
        List<Ticket_Log__c> dbItems = [SELECT Id FROM Ticket_Log__c WHERE Ticket__c =:tkt.Id AND Job__c = null];
        System.assert(dbItems.size() == 1, 'should NOT have value for Job__c');
    
    }

    static testmethod void TicketItem_Test()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, true).get(0);
        List<Price_Book_Item__c> pbiItems = AlpineTestHelper.CreatePriceBookItems(10, job.Price_Book__c, 'Equipment');
        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();
        for(Price_Book_Item__c pbi : pbiItems)
        {
            tktItems.add(new Ticket_Item__c(Price_Book_Item__c = pbi.Id, Ticket__c = tkt.Id));
        }
        insert tktItems;
        Test.stopTest();
        List<Ticket_Item__c> dbItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Job__c = :job.Id];
        System.assert(dbItems.size() == 10, 'should have 10 entries with jobId, instead of ' + dbItems.size());
    }


    static testmethod void TicketItem_ReparentTest()
    {
        Test.startTest();
        List<Job__c> jobs = AlpineTestHelper.CreateJobs(2, false);
        jobs.get(1).Price_Book__c = jobs.get(0).Price_Book__c;
        insert jobs;
        Job__c j1 = jobs.get(0);
        Job__c j2 = jobs.get(1);


        Ticket__c tkt1 = AlpineTestHelper.CreateTickets(j1, 1, true).get(0);
        Ticket__c tkt2 = AlpineTestHelper.CreateTickets(j2, 1, true).get(0);
        Price_Book_Item__c pbi = AlpineTestHelper.CreatePriceBookItems(1, j1.Price_Book__c, 'Equipment').get(0);
        
        Ticket_Item__c ti1 = new Ticket_Item__c(Price_Book_Item__c = pbi.Id, Ticket__c = tkt1.Id);
        insert ti1;

        Ticket_Item__c dbTktItem = [SELECT Id, Job__c, Ticket__c FROM Ticket_Item__c WHERE Id=:ti1.Id];
        System.assert(dbTktItem.Job__c == j1.Id, 'Job__c should be ' + j1.Id + ', instead of ' + dbTktItem.Job__c);

        dbTktItem.Ticket__c = tkt2.Id;
        update dbTktItem;

        dbTktItem = [SELECT Id, Job__c, Ticket__c FROM Ticket_Item__c WHERE Id=:ti1.Id];
        System.assert(dbTktItem.Job__c == j2.Id, 'Job__c should be ' + j2.Id + ', instead of ' + dbTktItem.Job__c);


    }


    static testmethod void TicketLog_Test()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, true).get(0);
        List<Ticket_Log__c> objs = new List<Ticket_Log__c>();
        insert new Ticket_Log__c(Ticket__c = tkt.Id, Start_Time__c = Datetime.now());
        Test.stopTest();
        List<Ticket_Log__c> dbItems = [SELECT Id FROM Ticket_Log__c WHERE Ticket__c =:tkt.Id AND Job__c = :job.Id];
        System.assert(dbItems.size() == 1, 'should have value for Job__c');
    
    }
    
    static testmethod void TicketLog_Update_Test()
    {
       
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, true).get(0);
        List<Ticket_Log__c> objs = new List<Ticket_Log__c>();
        insert new Ticket_Log__c(Ticket__c = tkt.Id, Start_Time__c = Datetime.now());
        Test.startTest();
        List<Ticket_Log__c> dbItems = [SELECT Id, Job__c FROM Ticket_Log__c WHERE Ticket__c =:tkt.Id AND Job__c = :job.Id];
        System.assert(dbItems.size() == 1, 'should have value for Job__c');
        
        Ticket_Log__c log = dbItems.get(0);
        log.Job__c = null;
        update log;
        Test.stopTest();
        dbItems = [SELECT Id FROM Ticket_Log__c WHERE Ticket__c =:tkt.Id AND Job__c = :job.Id];
        System.assert(dbItems.size() == 1, 'should have value for Job__c');
    
    }
    
    static testmethod void TicketChecklistStep_Test()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, true).get(0);
        List<Ticket_Checklist_Step__c> objs = new List<Ticket_Checklist_Step__c>();
        insert new Ticket_Checklist_Step__c(Ticket__c = tkt.Id, Name = StringUtility.newGuid(), Description__c='Unit Test');
        Test.stopTest();
        List<Ticket_Checklist_Step__c> dbItems = [SELECT Id FROM Ticket_Checklist_Step__c WHERE Ticket__c =:tkt.Id AND Job__c = :job.Id];
        System.assert(dbItems.size() == 1, 'should have value for Job__c');
    }
    
    static testmethod void TicketChecklistStep_Update_Test()
    {       
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, true).get(0);
        List<Ticket_Checklist_Step__c> objs = new List<Ticket_Checklist_Step__c>();
        insert new Ticket_Checklist_Step__c(Ticket__c = tkt.Id, Name = StringUtility.newGuid(), Description__c='Unit Test');
        Test.startTest();        
         List<Ticket_Checklist_Step__c> dbItems = [SELECT Id FROM Ticket_Checklist_Step__c WHERE Ticket__c =:tkt.Id AND Job__c = :job.Id];
        System.assert(dbItems.size() == 1, 'should have value for Job__c');
        Ticket_Checklist_Step__c obj = dbItems.get(0);
        obj.Job__c = null;
        update obj;
        Test.stopTest();
        dbItems = [SELECT Id FROM Ticket_Checklist_Step__c WHERE Ticket__c =:tkt.Id AND Job__c = :job.Id];
        System.assert(dbItems.size() == 1, 'should have value for Job__c');
    }

    static testmethod void sObject_Test()
    {
        
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, true).get(0);
        List<Price_Book_Item__c> pbiItems = AlpineTestHelper.CreatePriceBookItems(1, job.Price_Book__c, 'Equipment');
        List<sObject> tktItems = new List<sObject>();
        for(Price_Book_Item__c pbi : pbiItems)
        {
            tktItems.add(new Ticket_Item__c(Price_Book_Item__c = pbi.Id, Ticket__c = tkt.Id));
        }
        insert tktItems;
        Test.startTest();
        String ns = StringUtility.FXNamespace();
        tktItems = Database.query('SELECT Id FROM ' + ns + 'Ticket_Item__c');
        JobPropagator.SetJobId(tktItems);        
        Test.stopTest();

        tktItems = Database.query('SELECT Id, ' + ns + 'Job__c FROM ' + ns + 'Ticket_Item__c');

        for(Ticket_Item__c ti: (List<Ticket_Item__c> )tktItems)
        {
            System.assert(ti.Job__c == job.Id, 'Job__c should be ' + job.Id + ', instead of ' + ti.Job__c);
        }
    }

    static testmethod void PropagatorBatchTest()
    {
        
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, true).get(0);
        List<Price_Book_Item__c> pbiItems = AlpineTestHelper.CreatePriceBookItems(10, job.Price_Book__c, 'Equipment');
        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();
        for(Price_Book_Item__c pbi : pbiItems)
        {
            tktItems.add(new Ticket_Item__c(Price_Book_Item__c = pbi.Id, Ticket__c = tkt.Id));
        }
        insert tktItems;
        Test.startTest();
        Database.executeBatch(new JobPropagatorBatchable(StringUtility.FXNamespace() + 'Ticket_Item__c'));
        Test.stopTest();
        List<Ticket_Item__c> dbItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Job__c = :job.Id];
        System.assert(dbItems.size() == 10, 'should have 10 entries with jobId, instead of ' + dbItems.size());
    }

    static testmethod void RunPostInstall_Test()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, true).get(0);
        List<Price_Book_Item__c> pbiItems = AlpineTestHelper.CreatePriceBookItems(10, job.Price_Book__c, 'Equipment');
        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();
        for(Price_Book_Item__c pbi : pbiItems)
        {
            tktItems.add(new Ticket_Item__c(Price_Book_Item__c = pbi.Id, Ticket__c = tkt.Id));
        }
        insert tktItems;
        JobPropagatorBatchable.RunPostInstall();
        Test.stopTest();
        List<Ticket_Item__c> dbItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Job__c = :job.Id];
        System.assert(dbItems.size() == 10, 'should have 10 entries with jobId, instead of ' + dbItems.size()); 
    }  
    

    static testmethod void JobPropagatorExt_Test()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, true).get(0);
        List<Price_Book_Item__c> pbiItems = AlpineTestHelper.CreatePriceBookItems(10, job.Price_Book__c, 'Equipment');
        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();
        for(Price_Book_Item__c pbi : pbiItems)
        {
            tktItems.add(new Ticket_Item__c(Price_Book_Item__c = pbi.Id, Ticket__c = tkt.Id));
        }
        insert tktItems;
        JobPropagatorExt.Run(tktItems);
        Test.stopTest();
        List<Ticket_Item__c> dbItems = [SELECT Id FROM Ticket_Item__c WHERE Ticket__c =:tkt.Id AND Job__c = :job.Id];
        System.assert(dbItems.size() == 10, 'should have 10 entries with jobId, instead of ' + dbItems.size()); 
    }  
}
