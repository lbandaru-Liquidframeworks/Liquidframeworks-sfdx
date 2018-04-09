@isTest
public class CreditMemoItemHandler_Fetch_Test
{
  @testSetup
  static void setup()
  {
    Account acc = AlpineTestHelper.CreateAccount('a1');

    RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');
    string newGuid = StringUtility.newGuid();

    string statusName = 'CMInitialStatus ' + newGuid;
    Status__c st = new Status__c(Name = statusName, SObject__c='Credit_Memo__c', Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);

    insert st;

    Credit_Memo__c cm = new Credit_Memo__c(CustomerAccount__c = acc.Id, Status__c = st.Id);
    insert cm;

    Credit_Memo_Item__c cmi = new Credit_Memo_Item__c();
    cmi.Credit_Memo__c = cm.Id;
    cmi.Description__c = 'cmi1';
    insert cmi;
  }

  static testMethod void CreditMemoItemsFetchTest()
  {
      Test.startTest();

      List<Credit_Memo_Item__c> cmis = [SELECT Id, Credit_Memo__c FROM Credit_Memo_Item__c LIMIT 1];
System.debug(cmis.size());


      String cmItemId = cmis[0].Id;
      String cmId = cmis[0].Credit_Memo__c;
      string cmFields = 'Id, Name';
      string cmiFields = 'Id, Name';
      CreditMemoItemHandler_Fetch.CreditMemoItemsFilterResponse filter = new CreditMemoItemHandler_Fetch.CreditMemoItemsFilterResponse();
      filter.keyword = 'cmi1';
      filter.itemType = '';
      filter.classification = '';
      filter.itemLimit = '2000';
      filter.itemOffset = '0';
      filter.sortby = 'Name';
      filter.sortdir = 'ASC';

      CreditMemoItemHandler_Fetch.CreditMemoItemsFetchResult res = CreditMemoItemHandler_Fetch.CreditMemoItemsFetch(cmItemId, cmId, cmFields, cmiFields, filter);

      System.assert(res.cmItems.size() > 0, 'should have some credit memo items');

      Test.stopTest();
  }

}
