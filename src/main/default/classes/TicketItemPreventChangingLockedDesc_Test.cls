@isTest
private class TicketItemPreventChangingLockedDesc_Test {

    static Price_Book__c SetupPriceBook() 
    {
        Classification__c classification = new Classification__c();
        classification.Name = 'Name';
        insert classification;
        
        Catalog_Item__c catalogItem = new Catalog_Item__c();
        catalogItem.Classification__c = classification.Id;
        catalogItem.Cost__c = 0.0;
        catalogItem.Description__c = 'Description';
        catalogItem.Name = 'Name';
        catalogItem.Name_Unique__c = 'Name Unique';
        insert catalogItem;
        
        Price_Book__c priceBook = new Price_Book__c();
        insert priceBook;
        
        Price_Book_Item__c pbi = new Price_Book_Item__c();
        pbi.Description_Override__c = 'locked desc';
        pbi.Catalog_Item__c = catalogItem.Id;
        pbi.Price_Book__c = priceBook.Id;
        pbi.Default_Quantity__c = 0;
        pbi.Price__c = 0;
        pbi.Locked_Description__c = true;
        insert pbi;
        
        pbi = new Price_Book_Item__c();
        pbi.Description_Override__c = 'unlocked';
        pbi.Catalog_Item__c = catalogItem.Id;
        pbi.Price_Book__c = priceBook.Id;
        pbi.Default_Quantity__c = 0;
        pbi.Price__c = 0;
        pbi.Locked_Description__c = false;
        pbi.Locked_Discount__c = false;
        pbi.Locked_Price_Markup__C = false;
        pbi.Parent_Price_Book_Item__c = pbi.Id;
        pbi.Requires_Parent_Item__c = true;

        insert pbi;

        pbi = new Price_Book_Item__c();
        pbi.Description_Override__c = 'locked discount';
        pbi.Catalog_Item__c = catalogItem.Id;
        pbi.Price_Book__c = priceBook.Id;
        pbi.Default_Quantity__c = 0;
        pbi.Price__c = 0;
        pbi.Locked_Description__c = false;
        pbi.Locked_Discount__c = true;
        pbi.Parent_Price_Book_Item__c = pbi.Id;
        pbi.Requires_Parent_Item__c = true;

        insert pbi;

        pbi = new Price_Book_Item__c();
        pbi.Description_Override__c = 'locked price markup';
        pbi.Catalog_Item__c = catalogItem.Id;
        pbi.Price_Book__c = priceBook.Id;
        pbi.Default_Quantity__c = 0;
        pbi.Price__c = 0;
        pbi.Locked_Description__c = false;
        pbi.Locked_Discount__c = false;
        pbi.Locked_Price_Markup__C = true;
        pbi.Parent_Price_Book_Item__c = pbi.Id;
        pbi.Requires_Parent_Item__c = true;

        insert pbi;
        
        return priceBook;
    }

    static Job__c SetupJob(Price_Book__c priceBook) 
    {
        Account account = new Account();
        account.Name = 'Account';
        insert account;
        
        Account office = new Account();
        office.Name = 'office';
        office.RecordTypeId = [select Id FROM RecordType where IsActive=true AND  Name = 'office' and SobjectType = 'Account'][0].Id;
        insert office;
        
        Job__c job = new Job__c();
        job.Name = 'jobname';
        job.Office__c = office.Id;
        job.CustomerAccount__c = account.Id;
        job.Price_Book__c = priceBook.Id;
        insert job;
        
        Ticket__c ticket = new Ticket__c();
        ticket.Job__c = job.Id;
        insert ticket;
        
        Ticket_Item__c ticketItem = new Ticket_Item__c();
        ticketItem.Price_Book_Item__c = [select Id from Price_Book_Item__c where Description_Override__c = 'locked desc'][0].Id;
        ticketItem.Ticket__c = ticket.Id;
        insert ticketItem;

        ticketItem = new Ticket_Item__c();
        ticketItem.Price_Book_Item__c = [select Id from Price_Book_Item__c where Description_Override__c = 'unlocked'][0].Id;
        ticketItem.Ticket__c = ticket.Id;
        insert ticketItem;

        ticketItem = new Ticket_Item__c();
        ticketItem.Price_Book_Item__c = [select Id from Price_Book_Item__c where Description_Override__c = 'locked discount'][0].Id;
        ticketItem.Ticket__c = ticket.Id;
        insert ticketItem;

        ticketItem = new Ticket_Item__c();
        ticketItem.Price_Book_Item__c = [select Id from Price_Book_Item__c where Description_Override__c = 'locked price markup'][0].Id;
        ticketItem.Ticket__c = ticket.Id;
        insert ticketItem;
        
        return Job;
    }    
    
    static testmethod void ChangeLockedDiscriptionTest()
    {
        Test.StartTest();
        
        //setup test
        Price_Book__c priceBook = SetupPriceBook();
        Job__c job = SetupJob(pricebook);
        
        Test.StopTest();
        
        //test to see if passed
        
        Ticket__c ticket = [select Id from Ticket__c where Job__c = :job.Id];
        List<Ticket_Item__c> ticketItems = [select Id from Ticket_Item__c where Ticket__c = :ticket.Id];

        system.assertEquals(4 , ticketItems.size() ); 
        
        Ticket_Item__c ticketItem = [select Id, Price_Book_Item__c from Ticket_Item__c where Ticket__c = :ticket.Id AND Description__c = 'locked desc' ];
        ticketItem.Description__c = 'changed description';
        
        try {
            update ticketItem;
        } catch (exception e) {
            system.assert(e.getMessage().contains('Cannot change the description as it is locked.'));
        }
    }

    static testmethod void ChangeUnLockedDiscriptionTest()
    {
        Test.StartTest();
        
        //setup test
        Price_Book__c priceBook = SetupPriceBook();
        Job__c job = SetupJob(pricebook);
        
        Test.StopTest();
        
        //test to see if passed
        
        Ticket__c ticket = [select Id from Ticket__c where Job__c = :job.Id];
        List<Ticket_Item__c> ticketItems = [select Id from Ticket_Item__c where Ticket__c = :ticket.Id];

        system.assertEquals(4 , ticketItems.size() ); 
        
        Ticket_Item__c ticketItem = [select Id, Price_Book_Item__c from Ticket_Item__c where Ticket__c = :ticket.Id AND Description__c = 'unlocked' ];
        
        ticketItem.Description__c = 'changed description';
        update ticketItem;
        
        List<Ticket_Item__c> verifyTicketItems = [select Id from Ticket_Item__c where Ticket__c = :ticket.Id AND Description__c = 'changed description' ];

        system.assertEquals(1 , verifyTicketItems.size() );
    }
 
    static testmethod void ChangeLockedDiscountTest()
    {
        Test.StartTest();
        
        //setup test
        Price_Book__c priceBook = SetupPriceBook();
        Job__c job = SetupJob(pricebook);
        
        Test.StopTest();
        
        //test to see if passed
        
        Ticket__c ticket = [select Id from Ticket__c where Job__c = :job.Id];
        List<Ticket_Item__c> ticketItems = [select Id from Ticket_Item__c where Ticket__c = :ticket.Id];

        system.assertEquals(4 , ticketItems.size() ); 
        
        Ticket_Item__c ticketItem = [select Id, Price_Book_Item__c from Ticket_Item__c where Ticket__c = :ticket.Id AND Description__c = 'locked discount' ];
        ticketItem.Discount_Percent__c  = 99;
        
        try {
            update ticketItem;
        } catch (exception e) {
            system.assert(e.getMessage().contains('Cannot change the discounted percent as the discount is locked.'));
        }
    }
 
     static testmethod void ChangeUnLockedDiscountTest()
    {
        Test.StartTest();
        
        //setup test
        Price_Book__c priceBook = SetupPriceBook();
        Job__c job = SetupJob(pricebook);
        
        Test.StopTest();
        
        //test to see if passed
        
        Ticket__c ticket = [select Id from Ticket__c where Job__c = :job.Id];
        List<Ticket_Item__c> ticketItems = [select Id from Ticket_Item__c where Ticket__c = :ticket.Id];

        system.assertEquals(4 , ticketItems.size() ); 
        
         Ticket_Item__c ticketItem = [select Id, Price_Book_Item__c from Ticket_Item__c where Ticket__c = :ticket.Id AND Description__c = 'unlocked' ];
        
        ticketItem.Discount_Percent__c  = 99;
        update ticketItem;
        
        List<Ticket_Item__c> verifyTicketItems = [select Id from Ticket_Item__c where Ticket__c = :ticket.Id AND Discount_Percent__c = 99 ];

        system.assertEquals(1 , verifyTicketItems.size() );
   }
 
    static testmethod void ChangeLockedPriceMarkupTest()
    {
        Test.StartTest();
        
        //setup test
        Price_Book__c priceBook = SetupPriceBook();
        Job__c job = SetupJob(pricebook);
        
        Test.StopTest();
        
        //test to see if passed
        
        Ticket__c ticket = [select Id from Ticket__c where Job__c = :job.Id];
        List<Ticket_Item__c> ticketItems = [select Id from Ticket_Item__c where Ticket__c = :ticket.Id];

        system.assertEquals(4 , ticketItems.size() ); 
        
        Ticket_Item__c ticketItem = [select Id, Price_Book_Item__c from Ticket_Item__c where Ticket__c = :ticket.Id AND Description__c = 'locked price markup' ];
        ticketItem.Price__c = 99;
        
        try {
            update ticketItem;
        } catch (exception e) {
            system.assert(e.getMessage().contains('Cannot change the price'));
        }
    }
 
     static testmethod void ChangeUnLockedPriceMarkupTest()
    {
        Test.StartTest();
        
        //setup test
        Price_Book__c priceBook = SetupPriceBook();
        Job__c job = SetupJob(pricebook);
        
        Test.StopTest();
        
        //test to see if passed
        
        Ticket__c ticket = [select Id from Ticket__c where Job__c = :job.Id];
        List<Ticket_Item__c> ticketItems = [select Id from Ticket_Item__c where Ticket__c = :ticket.Id];

        system.assertEquals(4 , ticketItems.size() ); 
        
         Ticket_Item__c ticketItem = [select Id, Price_Book_Item__c from Ticket_Item__c where Ticket__c = :ticket.Id AND Description__c = 'unlocked' ];
        
        ticketItem.Price__c = 99;
        update ticketItem;
        
        List<Ticket_Item__c> verifyTicketItems = [select Id from Ticket_Item__c where Ticket__c = :ticket.Id AND Price__c = 99 ];

        system.assertEquals(1 , verifyTicketItems.size() );
   }
 
}