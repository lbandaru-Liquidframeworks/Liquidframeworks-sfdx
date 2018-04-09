@isTest
public class CreditMemoItemHandler_PBISearch_Test
{
  @testSetup
  static void setup()
  {
    Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
    List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(10, j.Price_Book__c , 'Equipment', true);

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

  }

  static testMethod void GetCreditMemoAvailablePBISearchFilterTest()
  {
      Test.startTest();

      String res = CreditMemoItemHandler_PBISearch.GetCreditMemoAvailablePBISearchFilter();

      System.assert(!String.IsEmpty(res), 'should have a search filter');

      Test.stopTest();
  }

  static testMethod void GetAvailableInvoicesForCreditMemoTest()
  {
      Test.startTest();

      List<Credit_Memo__c> cms = [SELECT Id FROM Credit_Memo__c LIMIT 1];
System.debug(cms.size());


      CreditMemoItemHandler_PBISearch.GetAvailablePBIsForCreditMemoRequest request = new CreditMemoItemHandler_PBISearch.GetAvailablePBIsForCreditMemoRequest();
      request.creditMemoId = cms[0].Id;
      request.itemLimit = '2000';
      request.itemOffset = '0';
      request.sortby = 'Name';
      request.sortdir = 'ASC';
      request.pbiFields = 'Id, Name';
      request.creditMemoItemParentPBIId = null;
      request.availablePBIfilters = new List<ItemBuilderHelper.SearchFieldRequest>();
      request.showItemsAlreadyOnTheCreditMemo = 'false';

      CreditMemoItemHandler_PBISearch.GetAvailablePBIsForCreditMemoResult res = CreditMemoItemHandler_PBISearch.GetAvailablePBIsForCreditMemo(request);

      System.assert(res.availablePBIs.size() > 0, 'should have some pbis');

      Test.stopTest();
  }
}
