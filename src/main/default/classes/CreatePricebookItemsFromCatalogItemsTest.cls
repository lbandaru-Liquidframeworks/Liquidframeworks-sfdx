@isTest
private class CreatePricebookItemsFromCatalogItemsTest 
{    
    static testmethod void Create4Items()
    {
        Test.StartTest();   
        
        String itemType = 'Labor';
        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        Catalog_Item__c cat1 = new Catalog_Item__c(Name= 'CI' +  StringUtility.newGuid(), Description__c = 'Test Catalog Item1', 
                                    UOM__c='Gal', Sequence_Number__c=1,  Ticket_Item_Record_Type__c = itemType);
        insert cat1;

        Catalog_Item__c cat2 = new Catalog_Item__c(Name= 'CI' +  StringUtility.newGuid(), Description__c = 'Test Catalog Item2', 
                                    UOM__c='Gal', Sequence_Number__c=2,  Ticket_Item_Record_Type__c = itemType);
        insert cat2;

        Catalog_Item__c cat3 = new Catalog_Item__c(Name= 'CI' +  StringUtility.newGuid(), Description__c = 'Test Catalog Item3', 
                                    UOM__c='Gal', Sequence_Number__c=3,  Ticket_Item_Record_Type__c = itemType);
        insert cat3;

        Catalog_Item__c cat4 = new Catalog_Item__c(Name= 'CI' +  StringUtility.newGuid(), Description__c = 'Test Catalog Item4', 
                                    UOM__c='Gal', Sequence_Number__c=4,  Ticket_Item_Record_Type__c = itemType);
        insert cat4;
        cat1 = [SELECT Id FROM Catalog_Item__c WHERE Description__c ='Test Catalog Item1' LIMIT 1];
        cat2 = [SELECT Id FROM Catalog_Item__c WHERE Description__c ='Test Catalog Item2' LIMIT 1];
        cat3 = [SELECT Id FROM Catalog_Item__c WHERE Description__c ='Test Catalog Item3' LIMIT 1];
        cat4 = [SELECT Id FROM Catalog_Item__c WHERE Description__c ='Test Catalog Item4' LIMIT 1];
        
        List<Id> catalogItemIds = new List<Id>();
        catalogItemIds.add(cat1.Id);
        catalogItemIds.add(cat2.Id);
        catalogItemIds.add(cat3.Id);
        catalogItemIds.add(cat4.Id);

        String parentId = '';

        CreatePricebookItemsFromCatalogItems.CreatePricebookItems(pb.Id, catalogItemIds, parentId);

        Test.StopTest();

        List<Price_Book_Item__c> dbItems = [SELECT Id FROM Price_Book_Item__c WHERE Price_Book__c =:pb.Id];
        System.assert(dbItems.size() == 4);
    }  

    static testmethod void Create1Item3Children()
    {
        Test.StartTest();   
        
        String itemType = 'Labor';
        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        Catalog_Item__c cat1 = new Catalog_Item__c(Name= 'CI' +  StringUtility.newGuid(), Description__c = 'Test Catalog Item1', 
                                    UOM__c='Gal', Sequence_Number__c=1,  Ticket_Item_Record_Type__c = itemType);
        insert cat1;
        cat1 = [SELECT Id FROM Catalog_Item__c WHERE Description__c ='Test Catalog Item1' LIMIT 1];

        List<Id> catalogItemIds = new List<Id>();
        catalogItemIds.add(cat1.Id);
        CreatePricebookItemsFromCatalogItems.CreatePricebookItems(pb.Id, catalogItemIds, '');
        List<Price_Book_Item__c> dbItems = [SELECT Id FROM Price_Book_Item__c WHERE Price_Book__c =:pb.Id];
        Price_Book_Item__c parentPbi = dbItems[0];

        Catalog_Item__c cat2 = new Catalog_Item__c(Name= 'CI' +  StringUtility.newGuid(), Description__c = 'Test Catalog Item2', 
                                    UOM__c='Gal', Sequence_Number__c=2,  Ticket_Item_Record_Type__c = itemType);
        insert cat2;
        Catalog_Item__c cat3 = new Catalog_Item__c(Name= 'CI' +  StringUtility.newGuid(), Description__c = 'Test Catalog Item3', 
                                    UOM__c='Gal', Sequence_Number__c=3,  Ticket_Item_Record_Type__c = itemType);
        insert cat3;
        Catalog_Item__c cat4 = new Catalog_Item__c(Name= 'CI' +  StringUtility.newGuid(), Description__c = 'Test Catalog Item4', 
                                    UOM__c='Gal', Sequence_Number__c=4,  Ticket_Item_Record_Type__c = itemType);
        insert cat4;
        cat2 = [SELECT Id FROM Catalog_Item__c WHERE Description__c ='Test Catalog Item2' LIMIT 1];
        cat3 = [SELECT Id FROM Catalog_Item__c WHERE Description__c ='Test Catalog Item3' LIMIT 1];
        cat4 = [SELECT Id FROM Catalog_Item__c WHERE Description__c ='Test Catalog Item4' LIMIT 1];
        
        catalogItemIds = new List<Id>();
        catalogItemIds.add(cat2.Id);
        catalogItemIds.add(cat3.Id);
        catalogItemIds.add(cat4.Id);

        String parentId = parentPbi.Id;

        CreatePricebookItemsFromCatalogItems.CreatePricebookItems(pb.Id, catalogItemIds, parentId);

        Test.StopTest();

        dbItems = [SELECT Id FROM Price_Book_Item__c WHERE Price_Book__c =:pb.Id];
        System.assert(dbItems.size() == 4);

        dbItems = [SELECT Id FROM Price_Book_Item__c WHERE Price_Book__c =:pb.Id AND Id =:parentPbi.Id];
        System.assert(dbItems.size() == 1);

        dbItems = [SELECT Id FROM Price_Book_Item__c WHERE Price_Book__c =:pb.Id AND Parent_Price_Book_Item__c =:parentPbi.Id];
        System.assert(dbItems.size() == 3);
    }  

}