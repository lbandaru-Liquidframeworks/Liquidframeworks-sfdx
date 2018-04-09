@isTest
private class InvoiceItemHandler_Transactions_Test
{

    @testSetup
    static void setup()
    {
      Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);

      List<Invoice__c> invs = AlpineTestHelper.CreateInvoices(1, true, j.Price_Book__c);
    }

    static testmethod void getAppliedCreditSearchFilter_Test()
    {
      Test.startTest();

      String res = InvoiceItemHandler_Transactions.GetAppliedCreditSearchFilter();

      System.assert(!String.IsEmpty(res), 'should have a search filter');

      Test.stopTest();

    }

    static testmethod void getHistoricalTransactionsLayout_Test()
    {
      Test.startTest();

      String res = InvoiceItemHandler_Transactions.GetHistoricalTransactionsLayout();

      System.assert(!String.IsEmpty(res), 'should have a search filter');

      Test.stopTest();

    }

    static testmethod void invoiceItemsFetch_Test()
    {
      Test.startTest();

      Invoice__c inv = [SELECT Id FROM Invoice__c LIMIT 1];

      InvoiceItemHandler_Transactions.GetCreditMemosForInvoiceRequest request = new InvoiceItemHandler_Transactions.GetCreditMemosForInvoiceRequest();
      request.invoiceId = inv.Id;
      request.showItemsAlreadyOnTheInvoice = 'false';
      request.itemLimit='';
      request.itemOffset='';
      request.sortby='';
      request.sortdir='';
      request.creditMemoFields='Id,Name';
      request.invoiceItemParentTktItemId=null;
      request.showItemsAlreadyInvoiced='false';

      InvoiceItemHandler_Transactions.GetCreditMemosForInvoiceResult res = InvoiceItemHandler_Transactions.GetCreditMemosForInvoice(request);

      Test.stopTest();
    }

}
