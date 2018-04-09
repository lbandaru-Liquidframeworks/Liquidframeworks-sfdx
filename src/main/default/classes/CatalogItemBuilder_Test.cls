@isTest
private class CatalogItemBuilder_Test 
{    
    static testmethod void CopyClassificationBreadcrumb_Insert()
    {
        Test.StartTest();   
        String newGuid = StringUtility.newGuid();   

        Classification__c cParent = new Classification__c(Name='p' + newGuid);
        insert cParent;

        Classification__c cChild = new Classification__c(Name='c' + newGuid, P__c = cParent.Id);
        insert cChild;


        Catalog_Item__c catalogItem = new Catalog_Item__c();
        catalogItem.Classification__c = cChild.Id;
        catalogItem.Cost__c = 10;
        catalogItem.Description__c = newGuid;
        catalogItem.Name = newGuid;
        catalogItem.Name_Unique__c = newGuid;

        insert catalogItem;

        Test.StopTest();

        string cName='c' + newGuid;
        Classification__c c = [SELECT Breadcrumb__c FROM Classification__c WHERE Name=:cName LIMIT 1];

        List<Catalog_Item__c> dbItems = [SELECT Breadcrumb__c FROM Catalog_Item__c WHERE Name =:newGuid];
        for(Catalog_Item__c ci : dbItems)
        {
            System.assertEquals(c.Breadcrumb__c, ci.Breadcrumb__c);
        }       
    }  

    static testmethod void CopyClassificationBreadcrumb_Update()
    {
        Test.StartTest();   
        String newGuid = StringUtility.newGuid();   

        Classification__c cParent = new Classification__c(Name='p' + newGuid);
        insert cParent;

        Classification__c cChild1 = new Classification__c(Name='c1' + newGuid, P__c = cParent.Id);
        insert cChild1;

        Classification__c cChild2 = new Classification__c(Name='c2' + newGuid, P__c = cParent.Id);
        insert cChild2;

        Catalog_Item__c catalogItem = new Catalog_Item__c();
        catalogItem.Classification__c = cChild1.Id;
        catalogItem.Cost__c = 10;
        catalogItem.Description__c = newGuid;
        catalogItem.Name = newGuid;
        catalogItem.Name_Unique__c = newGuid;

        insert catalogItem;

        Catalog_Item__c ci = [SELECT Classification__c FROM Catalog_Item__c WHERE Name =:newGuid LIMIT 1];
        ci.Classification__c = cChild2.Id;

        update ci;

        Test.StopTest();

        string cName='c2' + newGuid;
        Classification__c c = [SELECT Breadcrumb__c FROM Classification__c WHERE Name=:cName LIMIT 1];

        Catalog_Item__c dbItem= [SELECT Breadcrumb__c FROM Catalog_Item__c WHERE Name =:newGuid LIMIT 1];
        System.assertEquals(c.Breadcrumb__c, dbItem.Breadcrumb__c);   
    }  


    static testmethod void CopyClassificationBreadcrumb_UpdateClassificationToNull()
    {
        Test.StartTest();   
        String newGuid = StringUtility.newGuid();   

        Classification__c cParent = new Classification__c(Name='p' + newGuid);
        insert cParent;

        Classification__c cChild1 = new Classification__c(Name='c1' + newGuid, P__c = cParent.Id);
        insert cChild1;

        Classification__c cChild2 = new Classification__c(Name='c2' + newGuid, P__c = cParent.Id);
        insert cChild2;

        Catalog_Item__c catalogItem = new Catalog_Item__c();
        catalogItem.Classification__c = cChild1.Id;
        catalogItem.Cost__c = 10;
        catalogItem.Description__c = newGuid;
        catalogItem.Name = newGuid;
        catalogItem.Name_Unique__c = newGuid;

        insert catalogItem;

        Catalog_Item__c ci = [SELECT Classification__c FROM Catalog_Item__c WHERE Name =:newGuid LIMIT 1];
        ci.Classification__c = null;

        update ci;

        Test.StopTest();

        string cName='c2' + newGuid;
        Classification__c c = [SELECT Breadcrumb__c FROM Classification__c WHERE Name=:cName LIMIT 1];

        Catalog_Item__c dbItem= [SELECT Breadcrumb__c FROM Catalog_Item__c WHERE Name =:newGuid LIMIT 1];
        System.assert(dbItem.Breadcrumb__c==null);
    }  


    static testmethod void TaintPriceBookItems_Test()
    {
          
        String newGuid = StringUtility.newGuid();   

        Price_Book__c priceBook = new Price_Book__c(Name = 'PriceBook ' + newGuid);
        insert priceBook;


        Catalog_Item__c catalogItem = new Catalog_Item__c(Name= newGuid, Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210, Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem;       
        
        Price_Book_Item__c pli = new Price_Book_Item__c(Price_Book__c = priceBook.Id, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);

        insert pli;

        Price_Book__c pb1 = [SELECT Name, Items_Last_Modified__c FROM Price_Book__c WHERE Id=:priceBook.Id];
        
        Datetime lastTime = pb1.Items_Last_Modified__c;

        Test.StartTest();

       
        Catalog_Item__c ci = [SELECT Id, Name, Sequence_Number__c FROM Catalog_Item__c WHERE Name = :newGuid LIMIT 1];

        ci.Sequence_Number__c = 500;

        update ci;      

        Test.StopTest();

        Price_Book__c pb2 = [SELECT Name, Items_Last_Modified__c FROM Price_Book__c WHERE Id=:priceBook.Id];

        //System.debug('before:' + pb1);
        //System.debug('after: ' + pb2);
        System.assert(pb2.Items_Last_Modified__c >= lastTime);
    }      
}