@isTest
private class CopyQuoteItemsTest{
   
    static testmethod void CopySingleItem(){
        Test.startTest();

        List<Id> quoteItemIds = new List<Id>();
    
        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        Quote__c qt = AlpineTestHelper.CreateQuotes(pb, 1, false).get(0);
        insert qt;

        Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem;

        Price_Book_Item__c pli1 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli1;

        Quote_Item__c pqtItem  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli1.Id);
        insert pqtItem;    
        quoteItemIds.add(pqtItem.Id);
        List<Quote_Item__c> result = CopyQuoteItems.CopyQuoteItems(qt.Id, quoteItemIds, true, 0);
        System.assert(result.size() == 1);

        Test.stopTest();

    }

    static testmethod void CopySingleItemWithAutoChildren(){
        Test.startTest();

        List<Id> quoteItemIds = new List<Id>();
    
        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        Quote__c qt = AlpineTestHelper.CreateQuotes(pb, 1, false).get(0);
        insert qt;

        Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem;

        Price_Book_Item__c pli1 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli1;
        Price_Book_Item__c pli2 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =2, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli2;
        Price_Book_Item__c pli3 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =3, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli3;
        Price_Book_Item__c pli4 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =4, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli4;

        Quote_Item__c pqtItem  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli1.Id);
        insert pqtItem;    
        quoteItemIds.add(pqtItem.Id);

        Quote_Item__c cqtItem  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli2.Id);
        cqtItem.Parent_Quote_Item__c = pqtItem.Id;
        insert cqtItem;    

        cqtItem  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli3.Id);
        cqtItem.Parent_Quote_Item__c = pqtItem.Id;
        insert cqtItem;            

        cqtItem  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli4.Id);
        cqtItem.Parent_Quote_Item__c = pqtItem.Id;
        insert cqtItem;            

        List<Quote_Item__c> result = CopyQuoteItems.CopyQuoteItems(qt.Id, quoteItemIds, true, 0);
        System.assert(result.size() == 4);

        Test.stopTest();

    }    

    static testmethod void CopySingleItemWithSelectedChildren(){
        Test.startTest();

        List<Id> quoteItemIds = new List<Id>();
    
        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        Quote__c qt = AlpineTestHelper.CreateQuotes(pb, 1, false).get(0);
        insert qt;

        Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem;

        Price_Book_Item__c pli1 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli1;
        Price_Book_Item__c pli2 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =2, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli2;
        Price_Book_Item__c pli3 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =3, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli3;
        Price_Book_Item__c pli4 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =4, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli4;

        Quote_Item__c pqtItem  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli1.Id);
        insert pqtItem;    
        quoteItemIds.add(pqtItem.Id);

        Quote_Item__c cqtItem  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli2.Id);
        cqtItem.Parent_Quote_Item__c = pqtItem.Id;
        insert cqtItem;    
        quoteItemIds.add(cqtItem.Id);

        cqtItem  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli3.Id);
        cqtItem.Parent_Quote_Item__c = pqtItem.Id;
        insert cqtItem;            
        quoteItemIds.add(cqtItem.Id);

        cqtItem  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli4.Id);
        cqtItem.Parent_Quote_Item__c = pqtItem.Id;
        insert cqtItem;            
        quoteItemIds.add(cqtItem.Id);

        List<Quote_Item__c> result = CopyQuoteItems.CopyQuoteItems(qt.Id, quoteItemIds, true, 0);
        System.assert(result.size() == 4);

        Test.stopTest();
    }    

    static testmethod void CopySingleChild(){
        Test.startTest();

        List<Id> quoteItemIds = new List<Id>();
    
        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        Quote__c qt = AlpineTestHelper.CreateQuotes(pb, 1, false).get(0);
        insert qt;

        Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem;

        Price_Book_Item__c pli1 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli1;
        Price_Book_Item__c pli2 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =2, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli2;
        Price_Book_Item__c pli3 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =3, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli3;
        Price_Book_Item__c pli4 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =4, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli4;

        Quote_Item__c pqtItem  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli1.Id);
        insert pqtItem;    

        Quote_Item__c cqtItem  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli2.Id);
        cqtItem.Parent_Quote_Item__c = pqtItem.Id;
        insert cqtItem;    

        cqtItem  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli3.Id);
        cqtItem.Parent_Quote_Item__c = pqtItem.Id;
        insert cqtItem;            

        cqtItem  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli4.Id);
        cqtItem.Parent_Quote_Item__c = pqtItem.Id;
        insert cqtItem;            
        quoteItemIds.add(cqtItem.Id);

        List<Quote_Item__c> result = CopyQuoteItems.CopyQuoteItems(qt.Id, quoteItemIds, true, 0);
        System.assert(result.size() == 1);

        Test.stopTest();
    }    

}