@isTest
private class QuoteItemHandler_Test{

    static testmethod void AddChild_Test()
    {
        Test.StartTest();        
        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        Quote__c quote = AlpineTestHelper.CreateQuotes(pb, 1, true).get(0);
        Id priceBookId = quote.Price_Book__c;

        AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);
        List<Price_Book_Item__c> dbItems = [SELECT Id, Price_Book__c,  Parent_Price_Book_Item__c FROM Price_Book_Item__c WHERE Price_Book__c =:priceBookId];

        Price_Book_Item__c p= dbItems.get(0);
        dbItems.get(1).Parent_Price_Book_Item__c = p.Id;
        dbItems.get(2).Parent_Price_Book_Item__c = p.Id;        
        update dbItems;

        Quote_Item__c qi = new Quote_Item__c();
        qi.Quote__c = quote.Id;
        qi.Price_Book_Item__c = p.Id;
        insert qi;
        Test.stopTest();

        List<Quote_Item__c> qItems = [SELECT Id, Auto_Added__c FROM Quote_Item__c WHERE Quote__c=:quote.Id AND Auto_Added__c=false];
        System.assert(qItems.size()==3, 'Quote should have 3 items - 1 parent with two child items');

    }
    
    static testmethod void SetSyncIdForClonedQuoteItem()
    {
        Test.StartTest();        
        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        Quote__c quote = AlpineTestHelper.CreateQuotes(pb, 1, true).get(0);
        Id priceBookId = quote.Price_Book__c;

        AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);
        List<Price_Book_Item__c> dbItems = [SELECT Id, Price_Book__c,  Parent_Price_Book_Item__c FROM Price_Book_Item__c WHERE Price_Book__c =:priceBookId];

        Price_Book_Item__c p= dbItems.get(0);
               
        Quote_Item__c qi = new Quote_Item__c();
        qi.Quote__c = quote.Id;
        qi.Price_Book_Item__c = p.Id;
        insert qi;
        
        String quoteItemId = qi.Id;
        
        String soql = String.format('{0} WHERE Id=:quoteItemId', new String[]{MetadataHelper.GetSelectQuery(Quote_Item__c.sObjectType.getDescribe())});
        
        Quote_Item__c source = (Quote_Item__c)Database.query(soql);
        Quote_Item__c newOne = source.clone(false, false, false, false);      
        
        String syncId = newOne.SyncId__c;
        newOne.SyncId__c = null;
        
        SObjectClonerUtility.CloningInProgress = true;
        
        insert newOne;
        
        Test.stopTest();

        Quote_Item__c quoteItem = [SELECT Id, SyncId__c FROM Quote_Item__c WHERE Id =:newOne.Id];
        
        System.assert(!String.isBlank(quoteItem.SyncId__c), 'Trigger should have set Quote Item SyncId');      
        
      

    }
    
    static testmethod void AddNoChildForCreatedInMobileQuoteItem_Test()
    {
        Test.StartTest();        
        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        Quote__c quote = AlpineTestHelper.CreateQuotes(pb, 1, true).get(0);
        Id priceBookId = quote.Price_Book__c;

        AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);
        List<Price_Book_Item__c> dbItems = [SELECT Id, Price_Book__c,  Parent_Price_Book_Item__c FROM Price_Book_Item__c WHERE Price_Book__c =:priceBookId];

        Price_Book_Item__c p= dbItems.get(0);
        dbItems.get(1).Parent_Price_Book_Item__c = p.Id;
        dbItems.get(2).Parent_Price_Book_Item__c = p.Id;        
        update dbItems;

        Quote_Item__c qi = new Quote_Item__c();
        qi.Quote__c = quote.Id;
        qi.Price_Book_Item__c = p.Id;
        qi.Created_in_Mobile__c = true;
        insert qi;
        Test.stopTest();

        List<Quote_Item__c> qItems = [SELECT Id, Auto_Added__c FROM Quote_Item__c WHERE Quote__c=:quote.Id AND Auto_Added__c=false];
        System.assert(qItems.size()==1, 'Quote should have 3 items - 1 parent with two child items');

    }


    static testmethod void Update_Test()
    {
        Test.StartTest();        
        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        Quote__c quote = AlpineTestHelper.CreateQuotes(pb, 1, true).get(0);
        Id priceBookId = quote.Price_Book__c;

        AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);
        List<Price_Book_Item__c> dbItems = [SELECT Id, Price_Book__c,  Parent_Price_Book_Item__c FROM Price_Book_Item__c WHERE Price_Book__c =:priceBookId];

        Price_Book_Item__c p= dbItems.get(0);
        dbItems.get(1).Parent_Price_Book_Item__c = p.Id;
        dbItems.get(2).Parent_Price_Book_Item__c = p.Id;        
        update dbItems;

        Quote_Item__c qi = new Quote_Item__c();
        qi.Quote__c = quote.Id;
        qi.Price_Book_Item__c = p.Id;
        insert qi;

        qi.Discount_Percent__c = 50;
        update qi;

        Test.stopTest();

        List<Quote_Item__c> qItems = [SELECT Id, Auto_Added__c FROM Quote_Item__c WHERE Quote__c=:quote.Id AND Auto_Added__c=false];
        System.assert(qItems.size()==3, 'Quote should have 3 items - 1 parent with two child items');

    }

    static testmethod void Delete_Test()
    {
        Test.StartTest();        
        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        Quote__c quote = AlpineTestHelper.CreateQuotes(pb, 1, true).get(0);
        Id priceBookId = quote.Price_Book__c;

        AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);
        List<Price_Book_Item__c> dbItems = [SELECT Id, Price_Book__c,  Parent_Price_Book_Item__c FROM Price_Book_Item__c WHERE Price_Book__c =:priceBookId];

        Price_Book_Item__c p= dbItems.get(0);
        dbItems.get(1).Parent_Price_Book_Item__c = p.Id;
        dbItems.get(2).Parent_Price_Book_Item__c = p.Id;        
        update dbItems;

        Quote_Item__c qi = new Quote_Item__c();
        qi.Quote__c = quote.Id;
        qi.Price_Book_Item__c = p.Id;
        insert qi;

        List<Quote_Item__c> qItems = [SELECT Id, Auto_Added__c FROM Quote_Item__c WHERE Quote__c=:quote.Id AND Auto_Added__c=false];
        System.assert(qItems.size()==3, 'Quote should have 3 items - 1 parent with two child items');

        delete qi;

        Test.stopTest();

        qItems = [SELECT Id FROM Quote_Item__c WHERE Quote__c=:quote.Id];
        System.assert(qItems.size()==0, 'Quote should have 0 items');

    }
}