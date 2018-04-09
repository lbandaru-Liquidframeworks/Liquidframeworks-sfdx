@isTest
private class TicketItemsSvcTest{

    
    static testmethod void testUpdate(){
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);

        Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem;
          
        Price_Book_Item__c pli = new Price_Book_Item__c(Price_Book__c = job.Price_Book__c, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, 
                Default_Quantity__c=6, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id,
                Maximum_Quantity__c=10);
        insert pli;


        Ticket__c t= new Ticket__c(Job__c = job.Id);
        insert t;

        Ticket_Item__c tktItem  = new Ticket_Item__c(Ticket__c = t.Id, Price_Book_Item__c = pli.Id);

        insert tktItem;    

        string objStr = '{"Input_Qty__c":"2.00","id":"'+tktItem.Id+'"}';
        string typeStr = 'Ticket_Item__c';
        string tktFields = 'Name';
        string tktItemFields = 'Discount_Percent__c,Input_Qty__c';

        TicketItemsSvc.UpdateTktItemResult res = TicketItemsSvc.updateTktItem(objStr, typeStr, tktFields, tktItemFields);

        system.assert(res.success, 'ALL GOOD');

        objStr = '{"Input_Qty__c":"100","id":"'+tktItem.Id+'"}';

        res = TicketItemsSvc.updateTktItem(objStr, typeStr, tktFields, tktItemFields);
    }
    
    static testmethod void testUpdate2(){    
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);

        Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem;
          
        Price_Book_Item__c pli = new Price_Book_Item__c(Price_Book__c = job.Price_Book__c, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, 
                Default_Quantity__c=6, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id,
                Maximum_Quantity__c=10);
        insert pli;


        Ticket__c t= new Ticket__c(Job__c = job.Id);
        insert t;

        Ticket_Item__c tktItem  = new Ticket_Item__c(Ticket__c = t.Id, Price_Book_Item__c = pli.Id);

        insert tktItem;    

        tktItem.Input_Qty__c = 2;
        
        string typeStr = 'Ticket_Item__c';
        string tktFields = 'Name';
        string tktItemFields = 'Discount_Percent__c,Input_Qty__c';

        TicketItemsSvc.UpdateTktItemResult res = TicketItemsSvc.TicketItemUpdate(tktItem, typeStr, tktFields, tktItemFields);

        system.assert(res.success, 'ALL GOOD');

        tktItem.Input_Qty__c = 100;

        res = TicketItemsSvc.TicketItemUpdate(tktItem, typeStr, tktFields, tktItemFields);
    }
}