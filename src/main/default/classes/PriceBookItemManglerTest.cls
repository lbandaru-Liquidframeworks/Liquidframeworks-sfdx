@isTest
private class PriceBookItemManglerTest{
   
    static testmethod void EURPriceBookItem(){
        Test.startTest();
    
        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'EUR');
        Boolean hasCurrencyIso = AlpineTestHelper.HasCurrencyIso();
        
        Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem;
        
        Price_Book_Item__c pli = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli;

        Test.stopTest();        
        
        if (hasCurrencyIso) {
            string namespace = UtilityGetNamespace.CurrentNamespace(); 
            Price_Book_Item__c priceBookItem = (Price_Book_Item__c)Database.query('SELECT Id, CurrencyISOCode FROM ' + namespace + 'Price_Book_Item__c WHERE Id =\''+pli.Id+'\' LIMIT 1');
            String pbicurrency = string.valueOf(priceBookItem.get('CurrencyISOCode'));
            String pbcurrency = string.valueOf(pb.get('CurrencyISOCode'));            
            System.assertEquals(pbicurrency, pbcurrency);
        }
    }

    static testmethod void DeleteParentWithChild() {
        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'EUR');
        Boolean hasCurrencyIso = AlpineTestHelper.HasCurrencyIso();
        
        Catalog_Item__c catalogItem1 = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item1', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem1;
        Catalog_Item__c catalogItem2 = new Catalog_Item__c(Name= '12001', Description__c = 'Test Catalog Item2', UOM__c='Gal', Sequence_Number__c=220,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem2;
        Catalog_Item__c catalogItem3 = new Catalog_Item__c(Name= '12002', Description__c = 'Test Catalog Item3', UOM__c='Gal', Sequence_Number__c=230,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem3;
        
        Price_Book_Item__c pli1 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =1, 
                    Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem1.Id);
        insert pli1;
        Price_Book_Item__c pli2 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =2, 
                    Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, 
                    Catalog_Item__c=catalogItem2.Id, Parent_Price_Book_Item__c = pli1.Id);
        insert pli2;
        Price_Book_Item__c pli3 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =3, 
                    Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, 
                    Catalog_Item__c=catalogItem3.Id, Parent_Price_Book_Item__c = pli1.Id);
        insert pli3;

        delete pli1;

        List<Price_Book_Item__c> pbis = [SELECT Id FROM Price_Book_Item__c WHERE Price_Book__c =:pb.Id];

        System.assert(pbis.size() == 0);
    }
}