@isTest
public class CreditMemoItemHandler_InvoiceSearch_Test
{
  @testSetup
  static void setup()
  {
    Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);

    Account acc = AlpineTestHelper.CreateAccount('a1');

    RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');
    string newGuid = StringUtility.newGuid();

    string statusName = 'InvoiceStatus ' + newGuid;
    Status__c stI = new Status__c(Name = statusName, SObject__c='Invoice__c', Sync__c=true, Initial_Status_Console__c =true);

    insert stI;

    statusName = 'CMInitialStatus ' + newGuid;
    Status__c st = new Status__c(Name = statusName, SObject__c='Credit_Memo__c', Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);

    insert st;

    Credit_Memo__c cm = new Credit_Memo__c(CustomerAccount__c = acc.Id, Status__c = st.Id);
    insert cm;

    Credit_Memo_Item__c cmi = new Credit_Memo_Item__c();
    cmi.Credit_Memo__c = cm.Id;
    cmi.Description__c = 'cmi1';
    insert cmi;

    Invoice__c inv = new Invoice__c(CustomerAccount__c = j.CustomerAccount__c , Price_Book__c = j.Price_Book__c, Status__c = stI.Id );
    insert inv;

    Price_Book__c pb = [SELECT Id, AddTktItemsByPBSeqNum__c FROM Price_Book__c WHERE Id=:j.Price_Book__c ];
    pb.AddTktItemsByPBSeqNum__c = false;
    update pb;

    List<Price_Book_Item__c> pbiEquip = AlpineTestHelper.CreatePriceBookItems(5, j.Price_Book__c, 'Equipment', true);
    List<Price_Book_Item__c> pbiLabor = AlpineTestHelper.CreatePriceBookItems(5, j.Price_Book__c, 'Labor', true);

    List<Price_book_Item__c> sources  = [SELECT Id FROM Price_book_Item__c];
    List<Id> sourceIds = new List<Id>(new Map<Id, Price_book_Item__c>(sources).keySet());

    Decimal nextSeqNumber = 200;
    List<Invoice_Item__c> invItems = InvoiceItemHandler.CreateInvoiceItems(inv.Id, sourceIds, nextSeqNumber, null);


  }

  static testMethod void GetCreditMemoAvailableInvoiceSearchFilterTest()
  {
      Test.startTest();

      String res = CreditMemoItemHandler_InvoiceSearch.GetCreditMemoAvailableInvoiceSearchFilter();

      System.assert(!String.IsEmpty(res), 'should have a search filter');

      Test.stopTest();
  }

  static testMethod void GetAvailableInvoicesForCreditMemoTest()
  {
      Test.startTest();

      List<Credit_Memo__c> cms = [SELECT Id FROM Credit_Memo__c LIMIT 1];
System.debug(cms.size());


      CreditMemoItemHandler_InvoiceSearch.GetAvailableInvoicesForCreditMemoRequest request = new CreditMemoItemHandler_InvoiceSearch.GetAvailableInvoicesForCreditMemoRequest();
      request.creditMemoId = cms[0].Id;
      request.itemLimit = '2000';
      request.itemOffset = '0';
      request.sortby = 'Name';
      request.sortdir = 'ASC';
      request.invoiceFields = 'Id, Name';
      request.invoiceItemFields = 'Id, Name';
      request.creditMemoItemParentInvoiceItemId = null;
      request.invoicefilters = new List<ItemBuilderHelper.SearchFieldRequest>();
      request.invoiceItemfilters = new List<ItemBuilderHelper.SearchFieldRequest>();

      CreditMemoItemHandler_InvoiceSearch.GetAvailableInvoicesForCreditMemoResult res = CreditMemoItemHandler_InvoiceSearch.GetAvailableInvoicesForCreditMemo(request);

      System.assert(res.availableInvoices.size() > 0, 'should have some invoices');

      Test.stopTest();
  }



}
