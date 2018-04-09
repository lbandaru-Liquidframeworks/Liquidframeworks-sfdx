@isTest
private class CatalogItemPriceBookIndex_Test
{
    static testmethod void FlagIsDirty_Test()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Integer itemCount = 20;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(itemCount, job.Price_Book__c, 'Equipment');
        List<CatalogItemPriceBook__c> newItems = new List<CatalogItemPriceBook__c>();
        Set<String> jointKeys = new Set<String>();
        for(Price_Book_Item__c o : pbItems)
        {   
            CatalogItemPriceBook__c cp = new CatalogItemPriceBook__c(Catalog_Item__c = o.Catalog_Item__c, Price_Book__c = o.Price_Book__c);
            cp.JointKey__c = CatalogItemPriceBookHandler.GetJointKey(cp);
            jointKeys.add(cp.JointKey__c);
            newItems.add(cp);
        }
        upsert newItems JointKey__c;

        List<CatalogItemPriceBook__c> dbItems = [SELECT Id, IsDirty__c FROM CatalogItemPriceBook__c WHERE IsDeleted=false AND JointKey__c IN :jointKeys];
        for(CatalogItemPriceBook__c o : dbItems)
        {
            o.IsDirty__c = false;
        }
        update dbItems;

        Integer dirtyCount = [SELECT COUNT() FROM CatalogItemPriceBook__c WHERE IsDeleted=false AND JointKey__c IN :jointKeys AND IsDirty__c=true];
        
        System.assert(dirtyCount == 0, 'Should have no dirty ones, instead of ' + dirtyCount);

        Set<Id> priceBookIds = new Set<Id>();
        priceBookIds.add(job.Price_Book__c);
        CatalogItemPriceBookBatcher.FlagIsDirty(priceBookIds);
        Test.stopTest();

        //dirtyCount = [SELECT COUNT() FROM CatalogItemPriceBook__c WHERE IsDeleted=false AND JointKey__c IN :jointKeys AND IsDirty__c=true];
        
        //System.assert(dirtyCount == 20, 'Should have 20 dirty ones, instead of ' + dirtyCount);


    }

    static testmethod void FlagIsDirtyBatch_Test()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Integer itemCount = 20;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(itemCount, job.Price_Book__c, 'Equipment');
        List<CatalogItemPriceBook__c> newItems = new List<CatalogItemPriceBook__c>();
        Set<String> jointKeys = new Set<String>();
        for(Price_Book_Item__c o : pbItems)
        {   
            CatalogItemPriceBook__c cp = new CatalogItemPriceBook__c(Catalog_Item__c = o.Catalog_Item__c, Price_Book__c = o.Price_Book__c);
            cp.JointKey__c = CatalogItemPriceBookHandler.GetJointKey(cp);
            jointKeys.add(cp.JointKey__c);
            newItems.add(cp);
        }
        upsert newItems JointKey__c;

        List<CatalogItemPriceBook__c> dbItems = [SELECT Id, IsDirty__c FROM CatalogItemPriceBook__c WHERE IsDeleted=false AND JointKey__c IN :jointKeys];
        for(CatalogItemPriceBook__c o : dbItems)
        {
            o.IsDirty__c = false;
        }
        update dbItems;

        Integer dirtyCount = [SELECT COUNT() FROM CatalogItemPriceBook__c WHERE IsDeleted=false AND JointKey__c IN :jointKeys AND IsDirty__c=false];
        
        System.assert(dirtyCount == 20, 'Should have 20 entries with IsDirty__c=false, instead of ' + dirtyCount);

        String soql = String.format('SELECT Id, {0}Catalog_Item__c, {0}Price_Book__c, {0}IsDirty__c FROM {0}CatalogItemPriceBook__c WHERE IsDeleted=false',
            new String[]{StringUtility.FXNamespace()});

        Database.executeBatch(new CatalogItemPriceBookBatcher(soql, CatalogItemPriceBookBatcher.OperType.FlagIsDirty));
        Test.stopTest();

        //dirtyCount = [SELECT COUNT() FROM CatalogItemPriceBook__c WHERE IsDeleted=false AND IsDirty__c=true];
        
        //System.assert(dirtyCount == 20, 'Should have 20 dirty ones, instead of ' + dirtyCount);


    }

    static testmethod void InitialRunPriceBookIndex()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Integer itemCount = 20;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(itemCount, job.Price_Book__c, 'Equipment');

        Database.executeBatch(new CatalogItemPriceBookIndexBatchable(), 200)    ;
        Test.stopTest();

    }
    static testmethod void InsertPriceBookItem_Test()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Integer itemCount = 20;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(itemCount, job.Price_Book__c, 'Equipment');        
        Test.stopTest();

        List<CatalogItemPriceBook__c> dbItems = [SELECT Id FROM CatalogItemPriceBook__c WHERE Price_Book__c=:job.Price_Book__c];
        System.assert(dbItems.size()== itemCount, 'Should have 20 CatalogItemPriceBook__c, instead of ' + dbItems.size());

        Set<Id> pbiItemIds = new Map<Id, Price_Book_Item__c>(pbItems).keySet();
        List<Price_Book_Item__c> pbiItems = [SELECT Id, Catalog_Price_Book_Index__c from Price_Book_Item__c WHERE Id IN :pbiItemIds];
        String pbId = String.valueOf(job.Price_Book__c);
        for(Price_Book_Item__c pbi : pbiItems)
        {
            System.assert(pbi.Catalog_Price_Book_Index__c == pbId, 'Catalog_Price_Book_Index should have value ' + pbId + ' instead of ' + pbi.Catalog_Price_Book_Index__c);
        }
        
    }

    static testmethod void InsertPriceBookItem_2PriceBooks_Test()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Integer itemCount = 20;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(itemCount, job.Price_Book__c, 'Equipment', false);

        Job__c job2 = AlpineTestHelper.CreateJobs(1, true).get(0);
        List<Price_Book_Item__c> pbItems2 = AlpineTestHelper.CreatePriceBookItems(itemCount, job2.Price_Book__c, 'Equipment', false);
        for(Integer i=0; i<itemCount; i++)
        {
            pbItems2.get(i).Catalog_Item__c = pbItems.get(i).Catalog_Item__c;
        }
        pbItems.addAll(pbItems2);
        insert pbItems; 

        Set<Id> pbIds = new Set<Id>();
        pbIds.add(job.Price_Book__c);
        pbIds.add(job2.Price_Book__c);

        Test.stopTest();

        List<CatalogItemPriceBook__c> dbItems = [SELECT Id FROM CatalogItemPriceBook__c WHERE Price_Book__c In :pbIds];
        System.assert(dbItems.size()== 2*itemCount, 'Should have ' + 2* itemCount + ' CatalogItemPriceBook__c, instead of ' + dbItems.size());

        Set<Id> pbiItemIds = new Map<Id, Price_Book_Item__c>(pbItems).keySet();
        List<Price_Book_Item__c> pbiItems = [SELECT Id, Catalog_Price_Book_Index__c from Price_Book_Item__c WHERE Id IN :pbiItemIds];
        String pbIdStr1 = String.valueOf(job.Price_Book__c) + ',' + String.valueOf(job2.Price_Book__c);
        String pbIdStr2 = String.valueOf(job2.Price_Book__c) + ',' + String.valueOf(job.Price_Book__c);
        for(Price_Book_Item__c pbi : pbiItems)
        {
            System.assert(pbi.Catalog_Price_Book_Index__c == pbIdStr1 || pbi.Catalog_Price_Book_Index__c == pbIdStr2, 
                'Catalog_Price_Book_Index should have value ' +  pbIdStr1 + ' instead of ' + pbi.Catalog_Price_Book_Index__c);
        }
        
    }

    static testmethod void DeletePriceBookItem_Test()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Integer itemCount = 20;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(itemCount, job.Price_Book__c, 'Equipment');        
        delete pbItems.get(0);
        Test.stopTest();

        List<CatalogItemPriceBook__c> dbItems = [SELECT Id FROM CatalogItemPriceBook__c WHERE Price_Book__c=:job.Price_Book__c];
        System.assert(dbItems.size()== itemCount-1, 'Should have 19 CatalogItemPriceBook__c, instead of ' + dbItems.size());
    }

    static testmethod void DeletePriceBookItem_CatalogItemOn2PriceBooks_Test()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Job__c j2 = AlpineTestHelper.CreateJobs(1, true).get(0);
        Integer itemCount = 20;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(itemCount, job.Price_Book__c, 'Equipment', false); 
        List<Price_Book_Item__c> pbItems2 = AlpineTestHelper.CreatePriceBookItems(itemCount, j2.Price_Book__c, 'Equipment', false); 
        for(Integer i=0; i<20; i++)
        {
            pbItems2.get(i).Catalog_Item__c = pbItems.get(i).Catalog_Item__c;
        }
        pbItems.addAll(pbItems2);
        insert pbItems;

        delete pbItems.get(0);
        Test.stopTest();

        Set<Id> pbIds = new Set<Id>();
        pbIds.add(job.Price_Book__c);
        pbIds.add(j2.Price_Book__c);
        List<CatalogItemPriceBook__c> dbItems = [SELECT Id FROM CatalogItemPriceBook__c WHERE Price_Book__c In :pbIds];
        System.assert(dbItems.size()== 39, 'Should have 39 CatalogItemPriceBook__c, instead of ' + dbItems.size());
    }

    static testmethod void DeactivatePriceBook_Test()
    {
        Test.startTest();

        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Integer itemCount = 20;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(itemCount, job.Price_Book__c, 'Equipment');
        
        Job__c job2 = AlpineTestHelper.CreateJobs(1, true).get(0);
        List<Price_Book_Item__c> pbItems2 = AlpineTestHelper.CreatePriceBookItems(itemCount, job2.Price_Book__c, 'Equipment', false);
        for(Integer i=0; i<itemCount; i++)
        {
            pbItems2.get(i).Catalog_Item__c = pbItems.get(i).Catalog_Item__c;
        }
        insert pbItems2;        

        Price_Book__c pb = [SELECT Id, Effective_Date__c, Expiration_Date__c FROM Price_Book__c WHERE Id =:job.Price_Book__c ];
        pb.Effective_Date__c = Date.today().addDays(-5);
        pb.Expiration_Date__c = Date.today().addDays(-1);
        update pb;      

        Set<Id> pbIds = new Set<Id>();
        pbIds.add(job.Price_Book__c);
        pbIds.add(job2.Price_Book__c);
        Test.stopTest();

        List<CatalogItemPriceBook__c> dbItems = [SELECT Id FROM CatalogItemPriceBook__c WHERE Price_Book__c IN :pbIds];

        System.assert(dbItems.size()== itemCount*2, 'Deactivating Price Book should not delete CatalogItemPriceBook__c, thus should have ' + 2*itemCount + 'items, instead of ' + dbItems.size());

        List<Price_Book_Item__c> pbiItems = [SELECT Id, Catalog_Price_Book_Index__c from Price_Book_Item__c WHERE Price_Book__c = :job2.Price_Book__c];

        String pbIdStr  = String.valueOf(job2.Price_Book__c);
        for(Price_Book_Item__c pbi : pbiItems)
        {
            System.assert(pbi.Catalog_Price_Book_Index__c == pbIdStr, 'Price_Book_Index should be ' + pbIdStr + ', instead of ' + pbi.Catalog_Price_Book_Index__c);
        }
    }


    static testmethod void InsertPriceBookItemOnInactivePriceBook_Test()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Price_Book__c pb = [SELECT Id, Effective_Date__c, Expiration_Date__c FROM Price_Book__c WHERE Id =:job.Price_Book__c ];
        pb.Effective_Date__c = Date.today().addDays(-5);
        pb.Expiration_Date__c = Date.today().addDays(-1);
        update pb;


        Integer itemCount = 20;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(itemCount, job.Price_Book__c, 'Equipment');        
        
        Test.stopTest();

        List<CatalogItemPriceBook__c> dbItems = [SELECT Id FROM CatalogItemPriceBook__c WHERE Price_Book__c=:job.Price_Book__c];
        System.assert(dbItems.size()== itemCount , 'CatalogItemPriceBook__c would be created for inactive Price Book, should have ' + itemCount + ' items, instead of ' + dbItems.size());

        Set<Id> pbiItemIds = new Map<Id, Price_Book_Item__c>(pbItems).keySet();
        List<Price_Book_Item__c> pbiItems = [SELECT Id, Catalog_Price_Book_Index__c from Price_Book_Item__c WHERE Id IN :pbiItemIds];

        for(Price_Book_Item__c pbi : pbiItems)
        {
            System.assert(String.isBlank(pbi.Catalog_Price_Book_Index__c), 'PriceBookItem on inactive PriceBook would not have up to date Price_Book_Index, should be blank, instead of ' + pbi.Catalog_Price_Book_Index__c);
        }
    }

     static testmethod void ActivatePriceBook_CreateCatalogItemPriceBook_Test()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Price_Book__c pb = [SELECT Id, Effective_Date__c, Expiration_Date__c FROM Price_Book__c WHERE Id =:job.Price_Book__c ];
        pb.Effective_Date__c = Date.today().addDays(-5);
        pb.Expiration_Date__c = Date.today().addDays(-1);
        update pb;


        Integer itemCount = 20;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(itemCount, job.Price_Book__c, 'Equipment');                

        pb.Expiration_Date__c = null;
        update pb;

        //CatalogItemPriceBookBatcher.ProcessCatalogPriceBook();
        CatalogItemPriceBookBatcher.ProcessCatalogItemPriceBook();
        
        Test.stopTest();
        
        Price_Book__c dbPb = [SELECT Id, Is_Active__c FROM Price_Book__c WHERE Id=:pb.Id];
        System.assert(dbPb.Is_Active__c==true, 'PriceBook should be active');
        
        Integer count = [SELECT COUNT() FROM CatalogItemPriceBook__c WHERE IsDeleted=false AND Price_Book__c=:pb.Id AND IsDirty__c=false];        
        System.assert(count == itemCount , 'Should have ' + itemCount + ' CatalogItemPriceBook__c entries, instead of ' + count);
        
        Set<Id> pbiItemIds = new Map<Id, Price_Book_Item__c>(pbItems).keySet();
        List<Price_Book_Item__c> pbiItems = [SELECT Id, Catalog_Price_Book_Index__c from Price_Book_Item__c WHERE Id IN :pbiItemIds];

        Id pbId = job.Price_Book__c;
        for(Price_Book_Item__c pbi : pbiItems)
        {
            System.assert(pbi.Catalog_Price_Book_Index__c == pbId, 'Catalog_Price_Book_Index__c should have PriceBook ' + pbId + ', instead of ' + pbi.Catalog_Price_Book_Index__c);
        }
    }


    static testmethod void ProcessCatalogPriceBook_Test()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);

        Integer itemCount = 20;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(itemCount, job.Price_Book__c, 'Equipment');
        CatalogItemPriceBookBatcher.ProcessCatalogItemPriceBook();
        Test.stopTest();

        
        //List<CatalogItemPriceBook__c> dbItems = [SELECT Id FROM CatalogItemPriceBook__c WHERE Price_Book__c=:job.Price_Book__c AND IsDirty__c=true];
        //System.assert(dbItems.size()== itemCount, 'Should have ' + itemCount + ' CatalogItemPriceBook__c upon activating inactive Price Book, instead of ' + dbItems.size());

        Set<Id> pbiItemIds = new Map<Id, Price_Book_Item__c>(pbItems).keySet();
        List<Price_Book_Item__c> pbiItems = [SELECT Id, Catalog_Price_Book_Index__c from Price_Book_Item__c WHERE Id IN :pbiItemIds];

        Id pbId = job.Price_Book__c;
        for(Price_Book_Item__c pbi : pbiItems)
        {
            System.assert(pbi.Catalog_Price_Book_Index__c == pbId, 'Catalog_Price_Book_Index__c should have PriceBook ' + pbId + ', instead of ' + pbi.Catalog_Price_Book_Index__c);
        }
    }
 
}