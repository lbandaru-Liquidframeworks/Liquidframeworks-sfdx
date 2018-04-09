@isTest
private class InvoiceItemHandler_Test
{

    @testSetup
    static void setup()
    {
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
    }

    static testmethod void GetAvailableTicketsForInvoiceTest() {
        Test.startTest();

        Invoice__c inv = [SELECT Id FROM Invoice__c LIMIT 1];
        InvoiceItemHandler.GetAvailableTicketsForInvoiceRequest data = new InvoiceItemHandler.GetAvailableTicketsForInvoiceRequest();
        data.invoiceId = inv.Id;
        data.showItemsAlreadyOnTheInvoice = 'false';
        data.itemLimit = '400';
        data.itemOffset = '0';
        data.sortby = 'Name';
        data.sortdir = 'DESC';
        data.tktFields = 'Id';
        data.tktItemFields = 'Id';

        InvoiceItemHandler.GetAvailableTicketsForInvoiceResult res = InvoiceItemHandler.GetAvailableTicketsForInvoice(data);
        System.debug(res);

        System.assert(res.availableTickets.size() > 0, 'should have some availableTickets');

        Test.stopTest();
    }

    static testmethod void createInvItemsWithTicketItem_Test()
    {
        Test.startTest();
        List<Ticket_Item__c> sources  = [SELECT Id FROM Ticket_Item__c];

        System.assert(sources!=null && sources.size() == 10, 'should have 10 Ticket_Book_Item__c items');
        List<Id> sourceIds = new List<Id>(new Map<Id, Ticket_Item__c>(sources).keySet());

        Invoice__c inv = [SELECT Id FROM Invoice__c LIMIT 1];

        Decimal nextSeqNumber = 200;
        List<Invoice_Item__c> invItems = InvoiceItemHandler.CreateInvoiceItems(inv.Id, sourceIds, nextSeqNumber, null);

        Test.stopTest();

        Integer count = invItems!=null? invItems.size() : 0;

        System.assert(count == sources.size(), 'should have 10 items, instead having ' + count);

        //check sequence numbers
        Map<Id, Decimal> expectedResults = new Map<Id, Decimal>();
        for(Integer i=0; i<sourceIds.size(); i++)
        {
            expectedResults.put(sourceIds.get(i), nextSeqNumber + i);
        }
        for(Invoice_Item__c invi: invItems)
        {
            System.assert(invi.Sequence_Number__c == expectedResults.get(invi.Ticket_Item__c), 'Sequence_Number__c should be sequential starting with the provided nextSeqNumber');
        }
    }

    static testmethod void createInvoiceItemWithPBItem_Test()
    {
      Test.startTest();
      List<Price_book_Item__c> sources  = [SELECT Id FROM Price_book_Item__c];

      System.assert(sources!=null && sources.size() == 10, 'should have 10 Price_book_Item__c items');
      List<Id> sourceIds = new List<Id>(new Map<Id, Price_book_Item__c>(sources).keySet());

      Invoice__c inv = [SELECT Id FROM Invoice__c LIMIT 1];

      Decimal nextSeqNumber = 200;

      List<Invoice_Item__c> invItems = InvoiceItemHandler.CreateInvoiceItems(inv.Id, sourceIds, nextSeqNumber, null);

      Test.stopTest();

      Integer count = invItems!=null? invItems.size() : 0;

      System.assert(count == sources.size(), 'should have 10 items, instead having ' + count);

      //check sequence numbers
      Map<Id, Decimal> expectedResults = new Map<Id, Decimal>();
      for(Integer i=0; i<sourceIds.size(); i++)
      {
          expectedResults.put(sourceIds.get(i), nextSeqNumber + i);
      }
      for(Invoice_Item__c invi: invItems)
      {
          System.assert(invi.Sequence_Number__c == expectedResults.get(invi.Price_book_Item__c), 'Sequence_Number__c should be sequential starting with the provided nextSeqNumber');
      }
    }

    static testmethod void invoiceItemsFetch_Test()
    {
      Test.startTest();

      Invoice__c inv = [SELECT Id FROM Invoice__c LIMIT 1];

      String invItemId = null;
      String invId = inv.Id;
      string invFields = 'Name,Id';
      string invItemFields = 'Name,Id';
      InvoiceItemHandler.InvItemsFilterResponse filter = new InvoiceItemHandler.InvItemsFilterResponse();
      filter.keyword = '';
      filter.itemType = '';
      filter.classification = '';
      filter.itemLimit = '';
      filter.itemOffset = '';
      filter.sortby = '';
      filter.sortdir = '';

      InvoiceItemHandler.InvoiceItemsFetchResult res = InvoiceItemHandler.InvoiceItemsFetch(invItemId, invId, invFields, invItemFields, filter);

      Test.stopTest();
    }


}
