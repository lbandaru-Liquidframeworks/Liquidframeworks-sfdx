@isTest
private class CreditMemoAppliedHandler_Fetch_Test {

  @testSetup
  static void setup()
  {
      Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
      List<Invoice__c> invs = AlpineTestHelper.CreateInvoices(1, true, j.Price_Book__c);
      Account acc = AlpineTestHelper.CreateAccount('a1');

      RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');
      string newGuid = StringUtility.newGuid();

      string statusName = 'CMInitialStatus ' + newGuid;
      Status__c st = new Status__c(Name = statusName, SObject__c='Credit_Memo__c', Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);

      insert st;

      Credit_Memo__c cm = new Credit_Memo__c(CustomerAccount__c = acc.Id, Status__c = st.Id);
      insert cm;

      Credit_Memo_Applied__c cma = new Credit_Memo_Applied__c();
      cma.Amount__c = 200.20;
      cma.Credit_Memo__c = cm.Id;
      cma.Invoice__c = invs[0].Id;
      cma.Date__c = Date.today();
      insert cma;

System.debug(cma.Id);
  }

  static testMethod void CreditMemoAppliedsFetchTest()
  {
      Test.startTest();

      List<Credit_Memo_Applied__c> cmas = [SELECT Id, Credit_Memo__c FROM Credit_Memo_Applied__c LIMIT 1];
System.debug(cmas.size());

      string cmaFields = 'Id, Name';
      CreditMemoAppliedHandler_Fetch.CreditMemoItemsFilterRequest filter = new CreditMemoAppliedHandler_Fetch.CreditMemoItemsFilterRequest();
      filter.creditMemoId = cmas[0].Credit_Memo__c;
      filter.itemLimit = '2000';
      filter.itemOffset = '0';
      filter.sortby = 'Name';
      filter.sortdir = 'ASC';

      CreditMemoAppliedHandler_Fetch.CreditMemoAppliedsFetchResult res = CreditMemoAppliedHandler_Fetch.CreditMemoAppliedsFetch(cmaFields, filter);

      System.assert(res.cmas.size() > 0, 'should have some credit memo applieds');

      Test.stopTest();
  }

}
