@isTest
private class IIH_AvailableTktsSearch_Test
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

    static testmethod void GetAvailableTicketsSearchFilter_Test()
    {
      Test.startTest();

      Invoice__c inv = [SELECT Id FROM Invoice__c LIMIT 1];

      InvoiceItemHandler_AvailableTktsSearch.GetAvailableTicketsSearchFilterRequest request = new InvoiceItemHandler_AvailableTktsSearch.GetAvailableTicketsSearchFilterRequest();
      request.invId = inv.Id;

      String res = InvoiceItemHandler_AvailableTktsSearch.GetAvailableTicketsSearchFilter(request);

      System.assert(res.length() > 0, 'should have some search filters');

      Test.stopTest();
    }

    static testmethod void GetAvailableTicketsForInvoiceTest() {
        Test.startTest();

        Invoice__c inv = [SELECT Id FROM Invoice__c LIMIT 1];
        InvoiceItemHandler_AvailableTktsSearch.GetAvailableTicketsForInvoiceRequest data = new InvoiceItemHandler_AvailableTktsSearch.GetAvailableTicketsForInvoiceRequest();
        data.invoiceId = inv.Id;
        data.showItemsAlreadyOnTheInvoice = 'false';
        data.itemLimit = '400';
        data.itemOffset = '0';
        data.sortby = 'Name';
        data.sortdir = 'DESC';
        data.tktFields = 'Id';
        data.tktItemFields = 'Id';

        InvoiceItemHandler_AvailableTktsSearch.GetAvailableTicketsForInvoiceResult res = InvoiceItemHandler_AvailableTktsSearch.GetAvailableTicketsForInvoice(data);
        System.debug(res);

        System.assert(res.availableTickets.size() > 0, 'should have some availableTickets');

        Test.stopTest();
    }

}
