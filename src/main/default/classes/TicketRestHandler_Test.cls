@isTest
private class TicketRestHandler_Test
{
    static testmethod void CreateTicketItemFromQuote_Test()
    {
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        List<Ticket__c> tkts  = AlpineTestHelper.CreateTickets(job, 2, true);
        Ticket__c t1 = tkts.get(0);        
        Ticket__c t2 = tkts.get(1);
        
        Price_Book_Item__c pli = AlpineTestHelper.CreatePriceBookItems(1, job.Price_Book__c, 'Equipment').get(0);
        
        Ticket_Item__c ti = new Ticket_Item__c(Ticket__c = t1.Id, Price_Book_Item__c = pli.Id);
        insert ti;
        
        Test.startTest();
      
        List<Id> quoteItemIds = new List<Id>();
        quoteItemIds.add(ti.Id);
        
        List<Ticket_Item__c> result = TicketRestHandler.CreateTicketItems(t2.Id, quoteItemIds, true, 0);
        
        System.assert(result.size() > 0);
        
        Test.stopTest();
        
    }
}