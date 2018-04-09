@isTest
private class OverrideHandler_Test
{
    @testSetup
    static void Setup()
    {
        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        
        Ticket__c tkt = AlpineTestHelper.CreateTickets(j, 1, true).get(0);
                
        String ns = StringUtility.FXNamespace();
        Override_Config__c config = new Override_Config__c(
            Applies_to_SObject__c = 'Ticket',
            Override_Fields__c = ns + 'Price__c',
            Filter_Clause__c= ns + 'CustomerAccount__c=$CustomerAccount__c AND ' + ns + 'Catalog_Item__c=$Catalog_Item__c',
            Limit__c=1);        
        insert config;
        
        Id pbId = j.Price_Book__c;
        
        List<Override__c> overrides = new List<Override__c>();
        
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(10, pbId, 'Equipment', false);
        for(Price_Book_Item__c pbi: pbItems)
        {
            pbi.Override_Price_Method__c = config.Id;
            pbi.Discount_Percent__c = 0;
            
            overrides.add(new Override__c(Catalog_Item__c = pbi.Catalog_Item__c, 
                Price__c = pbi.Price__c * 2,
                Applies_to_SObject__c = 'Ticket',
                CustomerAccount__c = j.CustomerAccount__c));
                
        }
        insert pbItems;
        insert overrides;

    }    

     static testmethod void RunOnTicketUpdate()
    {        
        Ticket__c tkt = [SELECT Id, Job__c FROM Ticket__c LIMIT 1];
        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();
        for(Price_Book_Item__c pbi : [SELECT Id FROM Price_Book_Item__c LIMIT 2])
        {
            tktItems.add(new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pbi.Id));
        }
        insert tktItems;

        tktItems = [SELECT Id, Price__c, Price_Book_Item__r.Price__c, Override__c, Override__r.Price__c FROM Ticket_Item__c];
        for(Ticket_Item__c ti: tktItems)
        {
            System.assert(ti.Price__c == ti.Override__r.Price__c && ti.Price__c != ti.Price_Book_Item__r.Price__c, 
                'Price not overridden: ' + JSON.serializePretty(ti));
        }
        List<Override__c> overrides = [SELECT Id, Price__c FROM Override__c];
        for(Override__c o: overrides)
        {
            o.Price__c += 210;
        }
        update overrides;

        Test.startTest();
        update tkt;
        Test.stopTest();
        tktItems = [SELECT Id, Price__c, Price_Book_Item__r.Price__c, Override__c, Override__r.Price__c FROM Ticket_Item__c];
        for(Ticket_Item__c ti: tktItems)
        {
            System.assert(ti.Price__c == ti.Override__r.Price__c && ti.Price__c != ti.Price_Book_Item__r.Price__c, 
                'Price not overridden: ' + JSON.serializePretty(ti));
        }
    }

     static testmethod void RunOnJobUpdate()
    {        
        Job__c job = [SELECT Id  FROM Job__c LIMIT 1];

        Ticket__c tkt = [SELECT Id, Job__c FROM Ticket__c LIMIT 1];
        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();
        for(Price_Book_Item__c pbi : [SELECT Id FROM Price_Book_Item__c LIMIT 2])
        {
            tktItems.add(new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pbi.Id));
        }
        insert tktItems;

        tktItems = [SELECT Id, Price__c, Price_Book_Item__r.Price__c, Override__c, Override__r.Price__c FROM Ticket_Item__c];
        for(Ticket_Item__c ti: tktItems)
        {
            System.assert(ti.Price__c == ti.Override__r.Price__c && ti.Price__c != ti.Price_Book_Item__r.Price__c, 
                'Price not overridden: ' + JSON.serializePretty(ti));
        }
        List<Override__c> overrides = [SELECT Id, Price__c FROM Override__c];
        for(Override__c o: overrides)
        {
            o.Price__c += 210;
        }
        update overrides;

        Test.startTest();
        update job;
        Test.stopTest();
        tktItems = [SELECT Id, Price__c, Price_Book_Item__r.Price__c, Override__c, Override__r.Price__c FROM Ticket_Item__c];
        for(Ticket_Item__c ti: tktItems)
        {
            System.assert(ti.Price__c == ti.Override__r.Price__c && ti.Price__c != ti.Price_Book_Item__r.Price__c, 
                'Price not overridden: ' + JSON.serializePretty(ti));
        }
    }

    
    static testmethod void RunOnTicket_Batch()
    {        
        Ticket__c tkt = [SELECT Id, Job__c FROM Ticket__c LIMIT 1];
        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();
        for(Price_Book_Item__c pbi : [SELECT Id FROM Price_Book_Item__c])
        {
            tktItems.add(new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pbi.Id));
        }
        insert tktItems;
        Test.startTest();
        Set<Id> ids = new Set<Id>();
        ids.add(tkt.Id);
        OverrideBatcher.RunBatch(OverrideBatcher.TicketItemCountSoql_Tickets, ids, tktItems.size()+1);
        Test.stopTest();
    }

    static testmethod void RunOnTicket_NoBatch()
    {
        
        Ticket__c tkt = [SELECT Id, Job__c FROM Ticket__c LIMIT 1];
        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();
        for(Price_Book_Item__c pbi : [SELECT Id FROM Price_Book_Item__c LIMIT 2])
        {
            tktItems.add(new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pbi.Id));
        }
        insert tktItems;
        Test.startTest();
        Set<Id> ids = new Set<Id>();
        ids.add(tkt.Id);
        OverrideBatcher.RunOnTickets(ids);
        Test.stopTest();
    }
    

    static testmethod void RunOnJob_Batch()
    {       
        Ticket__c tkt = [SELECT Id, Job__c FROM Ticket__c LIMIT 1];
        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();
        for(Price_Book_Item__c pbi : [SELECT Id FROM Price_Book_Item__c])
        {
            tktItems.add(new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pbi.Id));
        }
        insert tktItems;
        Test.startTest();
        Set<Id> ids = new Set<Id>();
        ids.add(tkt.Job__c);
        OverrideBatcher.RunBatch(OverrideBatcher.TicketItemCountSoql_Jobs, ids, tktItems.size()+1);
        Test.stopTest();
    }

    static testmethod void RunOnJob_NoBatch()
    {
        
        Ticket__c tkt = [SELECT Id, Job__c FROM Ticket__c LIMIT 1];
        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();
        for(Price_Book_Item__c pbi : [SELECT Id FROM Price_Book_Item__c LIMIT 2])
        {
            tktItems.add(new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pbi.Id));
        }
        insert tktItems;
        Test.startTest();
        Set<Id> ids = new Set<Id>();
        ids.add(tkt.Job__c);
        OverrideBatcher.RunOnJobs(ids);
        Test.stopTest();
    }

    static testmethod void OverridePrice_Test()
    {
       
        Ticket__c tkt = [SELECT Id FROM Ticket__c LIMIT 1];
        Price_Book_Item__c pbi = [SELECT Id, Price__c, Catalog_Item__c FROM Price_Book_Item__c LIMIT 1];
        Override__c overrideObj = [SELECT Id, Price__c, Catalog_Item__c FROM Override__c WHERE Catalog_Item__c =:pbi.Catalog_Item__c LIMIT 1];
        Test.startTest();
        Ticket_Item__c ti = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pbi.Id);
        insert ti;
        Test.stopTest();
        Ticket_Item__c dbItem = [SELECT Id, Price__c, Override__c FROM Ticket_Item__c WHERE Id=:ti.Id];
        
        System.assert(dbItem.Price__c == overrideObj.Price__c, 'Price should be ' + overrideObj.Price__c + ', instead of ' + dbItem.Price__c);
        System.assert(dbItem.Override__c == overrideObj.Id, 'Override Id should be ' + overrideObj.Id + ', instead of ' + dbItem.Override__c);
        
    }

    static testmethod void OverrideConfigValidation_Test()
    {
       
        Test.startTest();
        String ns = StringUtility.FXNamespace();
        Override_Config__c config = new Override_Config__c(
            Applies_to_SObject__c = 'Ticket',
            Override_Fields__c = ns + 'Price123__c',
            Filter_Clause__c= ns + 'CustomerAccount__c=$' + ns + 'CustomerAccount__c AND ' + ns + 'Catalog_Item__c=$' + ns + 'Catalog_Item__c',
            Limit__c=1);        
        try {
            insert config;
        }
        catch (Exception ex) {
            System.debug(ex.getMessage());
        }   
        Test.stopTest();    

    }

    static testmethod void OverrideConfigUpdate_Validation_Test()
    {
       
        Test.startTest();
        Override_Config__c config = [SELECT Id, Override_Fields__c, Filter_Clause__c FROM Override_Config__c LIMIT 1];
        try {
            String ns = StringUtility.FXNamespace();
            config.Filter_Clause__c = ns + 'FieldNotExisted__c=$' + ns + 'CustomerAccount__c';
            update config;
        }
        catch (Exception ex) {
            System.debug(ex.getMessage());
        }   
        Test.stopTest();    

    }
    
}