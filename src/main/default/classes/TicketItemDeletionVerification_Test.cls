@isTest
private class TicketItemDeletionVerification_Test {  
    
    static testmethod void DeleteParentTest()
    {
        Test.StartTest();
        
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;

        AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);

        List<Price_Book_Item__c> dbItems = [SELECT Id, Price_Book__c,  Parent_Price_Book_Item__c FROM Price_Book_Item__c WHERE Price_Book__c =:priceBookId];

        Price_Book_Item__c parent = dbItems.get(0);

        for(Integer i=1; i<dbItems.size(); i++)
        {
            dbItems.get(i).Parent_Price_Book_Item__c = parent.Id;
        }
        update dbItems;

        Ticket__c ticket = AlpineTestHelper.CreateTickets(job, 1, true).get(0);

        Ticket_Item__c ticketItem = new Ticket_Item__c();
        ticketItem.Price_Book_Item__c = parent.Id;
        ticketItem.Ticket__c = ticket.Id;
        insert ticketItem;

        Test.StopTest();  
        List<Ticket_Item__c> ticketItems = [select Id, Parent_Ticket_Item__c from Ticket_Item__c where Ticket__c = :ticket.Id];

        system.assertEquals(5 , ticketItems.size() ); 
        
        delete [SELECT Id FROM Ticket_Item__c WHERE Id=:ticketItem.Id];
        
        ticketItems = [select Id from Ticket_Item__c where Ticket__c = :ticket.Id];
        system.assertEquals(0 , ticketItems.size() ); 
        
    }

    static testmethod void DeleteRequiredTest()
    {
        Test.StartTest();
        
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', false);       

        for(Integer i=0; i<pbItems.size(); i++)
        {
            pbItems.get(i).Required_Item__c = true;
        }
        insert pbItems;

        Price_Book_Item__c pbi = pbItems.get(0);

        Ticket__c ticket = AlpineTestHelper.CreateTickets(job, 1, true).get(0);        
     
        Test.StopTest();  

        List<Ticket_Item__c> ticketItems = [select Id, Price_Book_Item__c, Parent_Ticket_Item__c, Auto_Added__c, PBI_Required_Item__c,Rule_Required_Item__c  from Ticket_Item__c where Ticket__c = :ticket.Id];

        system.assertEquals(5, ticketItems.size()); 
        
        Ticket_Item__c dbTktItem = ticketItems.get(0);
        Id pbiId = dbTktItem.Price_Book_Item__c;

        System.assert(dbTktItem.Auto_Added__c);
        System.assert(dbTktItem.PBI_Required_Item__c);
        System.assert(dbTktItem.Rule_Required_Item__c);
       
        try 
        {
            delete dbTktItem;
        } 
        catch (exception e) 
        {
            system.assert(e.getMessage().contains('Cannot delete a required ticket item.'));
        }
        
        ticketItems = [select Id, Auto_Added__c, PBI_Required_Item__c, Parent_Ticket_Item__c, Description__c, Price_Book_Item__c from Ticket_Item__c where Ticket__c = :ticket.Id AND Price_Book_Item__c =:pbiId];
      
        system.assertEquals(1 , ticketItems.size()); 
     
        
    }

}