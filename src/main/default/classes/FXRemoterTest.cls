@isTest
private class FXRemoterTest{

    static testmethod void DeleteObjects_WithSelfReference(){
        Test.startTest();

        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        Quote__c qt = AlpineTestHelper.CreateQuotes(pb, 1, false).get(0);
        insert qt;

        Catalog_Item__c catalogItem1 = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item1', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem1;
        Catalog_Item__c catalogItem2 = new Catalog_Item__c(Name= '13000', Description__c = 'Test Catalog Item2', UOM__c='Gal', Sequence_Number__c=220,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem2;
        Catalog_Item__c catalogItem3 = new Catalog_Item__c(Name= '14000', Description__c = 'Test Catalog Item3', UOM__c='Gal', Sequence_Number__c=230,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem3;
        Catalog_Item__c catalogItem4 = new Catalog_Item__c(Name= '15000', Description__c = 'Test Catalog Item4', UOM__c='Gal', Sequence_Number__c=240,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem4;

        Price_Book_Item__c pli1 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem1.Id);
        insert pli1;
        Price_Book_Item__c pli2 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =2, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem2.Id);
        insert pli2;
        Price_Book_Item__c pli3 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =3, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem3.Id);
        insert pli3;
        Price_Book_Item__c pli4 = new Price_Book_Item__c(Price_Book__c = pb.Id, Price__c=125, Sequence_Number__c =4, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem4.Id);
        insert pli4;

        Quote_Item__c pqtItem1  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli1.Id);
        insert pqtItem1;
        Quote_Item__c qtItem2  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli2.Id, Parent_Quote_Item__c = pqtItem1.Id);
        insert qtItem2;
        Quote_Item__c qtItem3  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli3.Id, Parent_Quote_Item__c = pqtItem1.Id);
        insert qtItem3;
        Quote_Item__c notSelectedQtItem4  = new Quote_Item__c(Quote__c = qt.Id, Price_Book_Item__c = pli4.Id, Parent_Quote_Item__c = pqtItem1.Id);
        insert notSelectedQtItem4;    

        String ns = UtilityGetNamespace.CurrentNamespace();
        String objStr = '[{"Id":"'+pqtItem1.Id+'"},{"Id":"'+qtItem2.Id+'"},{"Id":"'+qtItem3.Id+'"}]';
        String typeStr = ns+'Quote_Item__c';

        List<FXRemoter.UpdateResult> result = FXRemoter.deleteObjects(objStr, typeStr);
        System.assert(result.size() == 4);

        Test.stopTest();

    }

    static testmethod void DeleteObjects_NoSelfReference(){
        Test.startTest();

        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        Quote__c qt = AlpineTestHelper.CreateQuotes(pb, 1, false).get(0);
        insert qt;

        Catalog_Item__c catalogItem1 = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item1', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem1;

        String ns = UtilityGetNamespace.CurrentNamespace();
        String objStr = '[{"Id":"'+catalogItem1.Id+'"}]';
        String typeStr = ns+'Catalog_Item__c';

        List<FXRemoter.UpdateResult> result = FXRemoter.deleteObjects(objStr, typeStr);
        System.assert(result.size() == 1);

        Test.stopTest();
    }

    static testmethod void DeleteObjects_Empty(){
        Test.startTest();

        String ns = UtilityGetNamespace.CurrentNamespace();
        String objStr = '[]';
        String typeStr = ns+'Catalog_Item__c';

        List<FXRemoter.UpdateResult> result = FXRemoter.deleteObjects(objStr, typeStr);
        System.assert(result.size() == 0);

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

        String res = FXRemoter.Process('TicketItemUpdate', ticketItemUpdateStr);
        Test.stopTest();
    }
}
