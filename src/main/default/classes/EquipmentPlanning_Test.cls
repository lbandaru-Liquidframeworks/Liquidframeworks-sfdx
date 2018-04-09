@isTest
private class EquipmentPlanning_Test
{
    static TestMethod void InsertWithValidPriceBookItem_Test()
    {
        Test.startTest();
        Job__c j1 = AlpineTestHelper.CreateJobs(1, true).get(0);
        Job__c j2 = AlpineTestHelper.CreateJobs(1, true).get(0);
        Job__c j3 = AlpineTestHelper.CreateJobs(1, true).get(0);

        Equipment__c equip = AlpineTestHelper.CreateEquipment(true);
        Price_Book_Item__c pbi = AlpineTestHelper.CreatePriceBookItems(1, j1.Price_Book__c, 'Equipment').get(0);

        Equipment_Planning__c ep = new Equipment_Planning__c(Equipment2__c = equip.Id, Job__c = j1.Id, Price_Book_Item__c = pbi.Id);
        insert ep;
        Test.stopTest();
        List<Equipment_Planning__c> items = [SELECT Id FROM Equipment_Planning__c WHERE Equipment2__c =: equip.Id];
        System.assert(items.size()==1, 'Should have one Equipment_Planning__c entry');
    }


    static TestMethod void DifferentPriceBookPriceBookItem_Test()
    {
        Test.startTest();
        Job__c j1 = AlpineTestHelper.CreateJobs(1, true).get(0);
        Job__c j2 = AlpineTestHelper.CreateJobs(1, true).get(0);
        Job__c j3 = AlpineTestHelper.CreateJobs(1, true).get(0);

        Equipment__c equip = AlpineTestHelper.CreateEquipment(true);
        Price_Book_Item__c pbi = AlpineTestHelper.CreatePriceBookItems(1, j2.Price_Book__c, 'Equipment').get(0);

        Equipment_Planning__c ep = new Equipment_Planning__c(Equipment2__c = equip.Id, Job__c = j1.Id, Price_Book_Item__c = pbi.Id);

        String msg= '';
        try
        {
            Database.insert(ep);
        }
        catch(System.DmlException e)
        {
            
            for (Integer i = 0; i < e.getNumDml(); i++) {
                msg += ' | ' + e.getDmlMessage(i); 
            }
            
        }
        
        Test.stopTest();
        
        System.debug(msg);

        System.assert(msg.indexOf('Price Book Item must be from the Job\'s Price Book')>=0, 'Should error out with msg: "Price Book Item must be from the Job\'s Price Book", instead of "' + msg + '"');

        List<Equipment_Planning__c> items = [SELECT Id FROM Equipment_Planning__c WHERE Equipment2__c =: equip.Id];
        System.assert(items.size()==0, 'Should have one Equipment_Planning__c entry');
    }

    static TestMethod void SkipJobPriceBookPriceBookItem_Test()
    {
        Test.startTest();
        Job__c j1 = AlpineTestHelper.CreateJobs(1, true).get(0);
        Job__c j2 = AlpineTestHelper.CreateJobs(1, false).get(0);

        if(EquipmentPlanningHandler.HasColumnEnableExtendedPricing)
        {
            j2.put(EquipmentPlanningHandler.EnableExtendedPricingColumnName, true);
        }
        insert j2;

        Map<Id, Price_Book__c> pbMap = new Map<Id, Price_Book__c>([SELECT Id FROM Price_Book__c]);

        Price_Book__c pbChild = pbMap.get(j2.Price_Book__c);
        pbChild.Parent_Price_Book__c = j1.Price_Book__c;
        update pbChild;

        Equipment__c equip = AlpineTestHelper.CreateEquipment(true);
        Price_Book_Item__c pbiOnChildPriceBook = AlpineTestHelper.CreatePriceBookItems(1, j2.Price_Book__c, 'Equipment').get(0);


        Price_Book_Item__c pbiOnParentPriceBook = new Price_Book_Item__c(Price_Book__c = j1.Price_Book__c, Price__c=500, 
            Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, 
            Included_Quantity__c=0, Catalog_Item__c=pbiOnChildPriceBook.Catalog_Item__c);
        
        insert pbiOnParentPriceBook;

        Equipment_Planning__c ep = new Equipment_Planning__c(Equipment2__c = equip.Id, Job__c = j2.Id, 
            Price_Book_Item__c = pbiOnParentPriceBook.Id);

        String msg= '';
        try
        {
            Database.insert(ep);
        }
        catch(System.DmlException e)
        {
            
            for (Integer i = 0; i < e.getNumDml(); i++) {
                msg += ' | ' + e.getDmlMessage(i); 
            }
            
        }
        
        Test.stopTest();

        if(!EquipmentPlanningHandler.HasColumnEnableExtendedPricing)
        {
            System.assert(msg.indexOf('Price Book Item must be from the Job\'s Price Book')>=0, 'Should error out with msg: "Price Book Item must be from the Job\'s Price Book", instead of "' + msg + '"');
        }
        else
        {
            System.assert(msg.indexOf('Price Book Item must be from the Job\'s or the nearest upper level Price Book')>=0, 
                    'Should error out with msg: Price Book Item must be from the Job\'s or the nearest upper level Price Book');
        }
        List<Equipment_Planning__c> items = [SELECT Id FROM Equipment_Planning__c WHERE Equipment2__c =: equip.Id];
        System.assert(items.size()==0, 'Should have no Equipment_Planning__c entry');
    }


    static TestMethod void ParentPriceBookPriceBookItem_Test()
    {
        Test.startTest();
        Job__c j1 = AlpineTestHelper.CreateJobs(1, true).get(0);
        Job__c j2 = AlpineTestHelper.CreateJobs(1, false).get(0);

        if(EquipmentPlanningHandler.HasColumnEnableExtendedPricing)
        {
            j2.put(EquipmentPlanningHandler.EnableExtendedPricingColumnName, true);
        }
        insert j2;

        Map<Id, Price_Book__c> pbMap = new Map<Id, Price_Book__c>([SELECT Id FROM Price_Book__c]);

        Price_Book__c pbChild = pbMap.get(j2.Price_Book__c);
        pbChild.Parent_Price_Book__c = j1.Price_Book__c;
        update pbChild;

        Equipment__c equip = AlpineTestHelper.CreateEquipment(true);

        Price_Book_Item__c pbi = AlpineTestHelper.CreatePriceBookItems(1, j1.Price_Book__c, 'Equipment').get(0);

        Equipment_Planning__c ep = new Equipment_Planning__c(Equipment2__c = equip.Id, Job__c = j2.Id, 
            Price_Book_Item__c = pbi.Id);

        String msg= '';
        try
        {
            Database.insert(ep);
        }
        catch(System.DmlException e)
        {
            
            for (Integer i = 0; i < e.getNumDml(); i++) {
                msg += ' | ' + e.getDmlMessage(i); 
            }               
        }
        
        Test.stopTest();

        List<Equipment_Planning__c> items = [SELECT Id FROM Equipment_Planning__c WHERE Equipment2__c =: equip.Id];
        if(!EquipmentPlanningHandler.HasColumnEnableExtendedPricing)
        {
            System.assert(msg.indexOf('Price Book Item must be from the Job\'s Price Book')>=0, 'Should error out with msg: "Price Book Item must be from the Job\'s Price Book", instead of "' + msg + '"');

        }
        else
        {
            System.assert(msg.indexOf('Price Book Item must be from the Job\'s Price Book')>=0, 'Should error out with msg: "Price Book Item must be from the Job\'s Price Book", instead of "' + msg + '"');

        }
    }


    static TestMethod void UpdatePriceBookItem_Test()
    {
        Test.startTest();
        Job__c j1 = AlpineTestHelper.CreateJobs(1, true).get(0);
        Job__c j2 = AlpineTestHelper.CreateJobs(1, false).get(0);

        if(EquipmentPlanningHandler.HasColumnEnableExtendedPricing)
        {
            j2.put(EquipmentPlanningHandler.EnableExtendedPricingColumnName, true);
        }
        insert j2;

        Map<Id, Price_Book__c> pbMap = new Map<Id, Price_Book__c>([SELECT Id FROM Price_Book__c]);

        Price_Book__c pbChild = pbMap.get(j2.Price_Book__c);
        pbChild.Parent_Price_Book__c = j1.Price_Book__c;
        update pbChild;

        Equipment__c equip = AlpineTestHelper.CreateEquipment(true);

        Price_Book_Item__c pbi1 = AlpineTestHelper.CreatePriceBookItems(1, j1.Price_Book__c, 'Equipment').get(0);
        Price_Book_Item__c pbi2 = AlpineTestHelper.CreatePriceBookItems(1, j2.Price_Book__c, 'Equipment').get(0);

        Equipment_Planning__c ep = new Equipment_Planning__c(Equipment2__c = equip.Id, Job__c = j1.Id, 
            Price_Book_Item__c = pbi1.Id);

        String msg= '';
        try
        {
            Database.insert(ep);
        }
        catch(System.DmlException e)
        {
            
            for (Integer i = 0; i < e.getNumDml(); i++) {
                msg += ' | ' + e.getDmlMessage(i); 
            }               
        }

        Equipment_Planning__c dbItem = [SELECT Id FROM Equipment_Planning__c WHERE Id=:ep.Id];
        dbItem.Job__c = j2.Id;
        dbItem.Price_Book_Item__c = pbi2.Id;
        update dbItem;
        
        Test.stopTest();

        List<Equipment_Planning__c> items = [SELECT Id FROM Equipment_Planning__c WHERE Equipment2__c =: equip.Id];
        System.assert(items.size()==1, 'Should have one Equipment_Planning__c entry, instead of ' + items.size());
    }


}
