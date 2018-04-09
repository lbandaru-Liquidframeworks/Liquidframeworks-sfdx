@isTest
private class FXProcessTest{

    static testmethod void InvoiceItemsUpdate() {
        Test.startTest();

        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(j, 1, true).get(0);

        Price_Book__c pb = [SELECT Id, AddTktItemsByPBSeqNum__c FROM Price_Book__c WHERE Id=:j.Price_Book__c ];
        pb.AddTktItemsByPBSeqNum__c = false;
        update pb;

        List<Price_Book_Item__c> pbiEquip = AlpineTestHelper.CreatePriceBookItems(5, j.Price_Book__c, 'Equipment', true);
        List<Price_Book_Item__c> pbiLabor = AlpineTestHelper.CreatePriceBookItems(5, j.Price_Book__c, 'Labor', true);

        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();
        for(Price_Book_Item__c pbi : pbiEquip)
        {
            Ticket_Item__c ti  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pbi.Id);
            tktItems.add(ti);
        }
        for(Price_Book_Item__c pbi : pbiLabor)
        {
            Ticket_Item__c ti  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pbi.Id);
            tktItems.add(ti);
        }
        insert tktItems;

        List<Invoice__c> invs = AlpineTestHelper.CreateInvoices(1, true, j.Price_Book__c);
        Invoice__c inv = invs[0];

        List<Ticket_Item__c> tis = [SELECT Id FROM Ticket_Item__c];
        Map<Id, Ticket_Item__c> tisIds = new Map<Id, Ticket_Item__c>(tis);
        List<Invoice_Item__c> invItems = InvoiceItemHandler.CreateInvoiceItems(inv.Id, new List<Id>(tisIds.keySet()), 100, null);

        string action = 'InvoiceItemsUpdate';

        String str = '';
        for(Invoice_Item__c invItem : invItems) {
          str+='{"Id":"'+invItem.Id+'","Qty__c":200},';
        }
        str = str.substring(0,str.length()-1)+'';
System.Debug(str);

        string objStr = '{"inviList":[';
        objStr += str;
        objStr +='],"typeStr":"Invoice_Item__c","invItemFields":"Id,Name,Sequence_Number__c,Qty__c","invFields":"Id,Name"}';
System.Debug('objStr');
System.Debug(objStr);
        System.debug(FXProcess.Process(action, objStr));

        Test.stopTest();
    }

    static testmethod void TicketItemUpdate() {
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

        string ticketItemUpdateStr = '{'+
            '"typeStr": "Ticket_Item__c",'+
            '"objStr": {"Price__c":12,"id":"'+tktItem.Id+'"},'+
            '"tktFields": "Name,Ticket_Date__c,Tracking_Number__c",'+
            '"tktItemFields": "RecordType.Name,RecordType.Id,RecordTypeId,Date_End__c,Equipment__r.Name,Equipment__r.Id,Equipment__c,Date_Start__c,Price__c,'+
                'LastModifiedBy.Name,LastModifiedBy.Id,LastModifiedById,LastModifiedDate,Catalog_UOM__c,Discount_Percent__c,CreatedBy.Name,CreatedBy.Id,'+
                'CreatedById,CreatedDate,Cost__c,Cost_Plus_Markup_Percent__c,Name,Cost_Plus_Markup_Amount__c,Item_Code__c,Warehouse__r.Name,Warehouse__r.Id,Warehouse__c,'+
                'Description__c,Parent_Ticket_Item__r.Name,Parent_Ticket_Item__r.Id,Parent_Ticket_Item__c,Sequence_Number__c,On_Standby__c,Standby_Price__c,Contact__r.Name,'+
                'Contact__r.Id,Contact__c,Breadcrumb__c,'+
                'Catalog_Record_Type__c,PBI_Default_Quantity__c,Catalog_Classification__r.Name,Catalog_Classification__r.Id,Catalog_Classification__c,PBI_Minimum_Charge__c'+
                ',Catalog_Track_Inventory__c,PBI_Maximum_Quantity__c,PBI_Minimum_Quantity__c,PBI_Included_Quantity__c,PBI_Locked_Price_Markup__c,PBI_Locked_Discount__c,Id,'+
                'PBI_Required_Item__c,Price_Book_Item__c,PBI_Locked_Description__c,PBI_Pricing_Method__c,Input_Qty__c,Rule_Required_Item__c,Price_Book_Item__r.'+
                'Price_Book__c,PBI_Enable_Dynamic_Parenting__c" }';

        String res = FXProcess.Process('TicketItemUpdate', ticketItemUpdateStr);
        Test.stopTest();

        System.debug(res);
    }


}
