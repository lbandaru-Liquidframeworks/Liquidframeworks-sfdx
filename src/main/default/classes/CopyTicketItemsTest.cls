@isTest
private class CopyTicketItemsTest{
   
    static testmethod void CopySingleItem(){
        Test.startTest();

        List<Id> ticketItemIds = new List<Id>();
    
        Job__c j = AlpineTestHelper.CreateJobs(1, false).get(0);
        insert j;

        Ticket__c tkt = AlpineTestHelper.CreateTickets(j, 1, false).get(0);
        insert tkt;

        Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem;

        Price_Book_Item__c pli1 = new Price_Book_Item__c(Price_Book__c = j.Price_Book__c, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        insert pli1;

        Ticket_Item__c ptktItem  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pli1.Id);
        insert ptktItem;    
        ticketItemIds.add(ptktItem.Id);
        List<Ticket_Item__c> result = CopyTicketItems.CopyTicketItems(tkt.Id, ticketItemIds, true, 0);
        System.assert(result.size() == 1);

        Test.stopTest();

    }

    static testmethod void CopySingleItemWithAutoChildren(){
        Test.startTest();

        List<Id> ticketItemIds = new List<Id>();
    
        Job__c j = AlpineTestHelper.CreateJobs(1, false).get(0);
        insert j;

        Ticket__c tkt = AlpineTestHelper.CreateTickets(j, 1, false).get(0);
        insert tkt;

        Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem;

        List<Price_Book_Item__c> pliItems = new List<Price_Book_Item__c>();

        Price_Book_Item__c pli1 = new Price_Book_Item__c(Price_Book__c = j.Price_Book__c, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        pliItems.add(pli1);
        Price_Book_Item__c pli2 = new Price_Book_Item__c(Price_Book__c = j.Price_Book__c, Price__c=125, Sequence_Number__c =2, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        pliItems.add(pli2);
        Price_Book_Item__c pli3 = new Price_Book_Item__c(Price_Book__c = j.Price_Book__c, Price__c=125, Sequence_Number__c =3, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        pliItems.add(pli3);
        Price_Book_Item__c pli4 = new Price_Book_Item__c(Price_Book__c = j.Price_Book__c, Price__c=125, Sequence_Number__c =4, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        pliItems.add(pli4);
        insert pliItems;

        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();

        Ticket_Item__c ptktItem  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pli1.Id);
        insert ptktItem;     
        ticketItemIds.add(ptktItem.Id);      

        Ticket_Item__c ctktItem  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pli2.Id);
        ctktItem.Parent_Ticket_Item__c = ptktItem.Id;
        tktItems.add(ctktItem);    

        ctktItem  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pli3.Id);
        ctktItem.Parent_Ticket_Item__c = ptktItem.Id;
        tktItems.add(ctktItem);            

        ctktItem  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pli4.Id);
        ctktItem.Parent_Ticket_Item__c = ptktItem.Id;
        tktItems.add(ctktItem);     

        insert tktItems;       

        List<Ticket_Item__c> result = CopyTicketItems.CopyTicketItems(tkt.Id, ticketItemIds, true, 0);
        System.assert(result.size() == 4, 'should have 4 items, instead of ' + result.size());

        Test.stopTest();

    }    

    static testmethod void CopySingleItemWithSelectedChildren(){
        Test.startTest();

        List<Id> ticketItemIds = new List<Id>();
    
        Job__c j = AlpineTestHelper.CreateJobs(1, false).get(0);
        insert j;

        Ticket__c tkt = AlpineTestHelper.CreateTickets(j, 1, false).get(0);
        insert tkt;

        Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem;

        List<Price_Book_Item__c> pliItems = new List<Price_Book_Item__c>();

        Price_Book_Item__c pli1 = new Price_Book_Item__c(Price_Book__c = j.Price_Book__c, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        pliItems.add(pli1);
        Price_Book_Item__c pli2 = new Price_Book_Item__c(Price_Book__c = j.Price_Book__c, Price__c=125, Sequence_Number__c =2, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        pliItems.add(pli2);
        Price_Book_Item__c pli3 = new Price_Book_Item__c(Price_Book__c = j.Price_Book__c, Price__c=125, Sequence_Number__c =3, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        pliItems.add(pli3);
        Price_Book_Item__c pli4 = new Price_Book_Item__c(Price_Book__c = j.Price_Book__c, Price__c=125, Sequence_Number__c =4, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        pliItems.add(pli4);
        insert pliItems;

        Ticket_Item__c ptktItem  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pli1.Id);
        insert ptktItem;    
        ticketItemIds.add(ptktItem.Id);

        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();


        tktItems.add(new Ticket_Item__c(Parent_Ticket_Item__c = ptktItem.Id, Ticket__c = tkt.Id, Price_Book_Item__c = pli2.Id)); 
        tktItems.add(new Ticket_Item__c(Parent_Ticket_Item__c = ptktItem.Id, Ticket__c = tkt.Id, Price_Book_Item__c = pli3.Id));
        tktItems.add(new Ticket_Item__c(Parent_Ticket_Item__c = ptktItem.Id, Ticket__c = tkt.Id, Price_Book_Item__c = pli4.Id));
     
        insert tktItems;  
        for(Ticket_Item__c ti : tktItems)          
        {
            ticketItemIds.add(ti.Id);
        }

        List<Ticket_Item__c> result = CopyTicketItems.CopyTicketItems(tkt.Id, ticketItemIds, true, 0);
        System.assert(result.size() == 4);

        Test.stopTest();
    }    

    static testmethod void CopySingleChild(){
        Test.startTest();

        List<Id> ticketItemIds = new List<Id>();
    
        Job__c j = AlpineTestHelper.CreateJobs(1, false).get(0);
        insert j;

        Ticket__c tkt = AlpineTestHelper.CreateTickets(j, 1, false).get(0);
        insert tkt;

        Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem;

        List<Price_Book_Item__c> pliItems = new List<Price_Book_Item__c>();

        Price_Book_Item__c pli1 = new Price_Book_Item__c(Price_Book__c = j.Price_Book__c, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        pliItems.add(pli1);
        Price_Book_Item__c pli2 = new Price_Book_Item__c(Price_Book__c = j.Price_Book__c, Price__c=125, Sequence_Number__c =2, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        pliItems.add(pli2);
        Price_Book_Item__c pli3 = new Price_Book_Item__c(Price_Book__c = j.Price_Book__c, Price__c=125, Sequence_Number__c =3, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        pliItems.add(pli3);
        Price_Book_Item__c pli4 = new Price_Book_Item__c(Price_Book__c = j.Price_Book__c, Price__c=125, Sequence_Number__c =4, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
        pliItems.add(pli4);
        insert pliItems;

        Ticket_Item__c ptktItem  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pli1.Id);
        insert ptktItem;    

        Ticket_Item__c ctktItem  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pli2.Id);
        ctktItem.Parent_Ticket_Item__c = ptktItem.Id;
        insert ctktItem;    

        ctktItem  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pli3.Id);
        ctktItem.Parent_Ticket_Item__c = ptktItem.Id;
        insert ctktItem;            

        ctktItem  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pli4.Id);
        ctktItem.Parent_Ticket_Item__c = ptktItem.Id;
        insert ctktItem;            
        ticketItemIds.add(ctktItem.Id);

        List<Ticket_Item__c> result = CopyTicketItems.CopyTicketItems(tkt.Id, ticketItemIds, true, 0);
        System.assert(result.size() == 1);

        Test.stopTest();
    }    

}