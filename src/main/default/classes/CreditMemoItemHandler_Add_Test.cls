@isTest
public class CreditMemoItemHandler_Add_Test
{
  @testSetup
  static void setup()
  {
    Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
    List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(10, j.Price_Book__c , 'Equipment', true);

    Account acc = AlpineTestHelper.CreateAccount('a1');

    RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');
    string newGuid = StringUtility.newGuid();

    String statusName = 'CMInitialStatus ' + newGuid;
    Status__c st = new Status__c(Name = statusName, SObject__c='Credit_Memo__c', Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);

    insert st;

    Credit_Memo__c cm = new Credit_Memo__c(CustomerAccount__c = acc.Id, Status__c = st.Id);
    insert cm;

    statusName = 'InvInitialStatus ' + newGuid;
    Status__c invStatus = new Status__c(Name = statusName, SObject__c='Invoice__c', Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);

    Invoice__c inv = new Invoice__c(CustomerAccount__c = j.CustomerAccount__c , Price_Book__c = j.Price_Book__c, Status__c = invStatus.Id );
    insert inv;

    List<Invoice_Item__c> newiis = new List<Invoice_Item__c>();
    for(integer i = 0; i<10 ; i++){
        Invoice_Item__c invi = new Invoice_Item__c(Invoice__c=inv.Id);
        newiis.add(invi);
    }
    insert newiis;

  }

  static testMethod void CreateCreditMemoItems_PBI_Test()
  {
    Test.startTest();

    List<Credit_Memo__c> cms = [SELECT Id FROM Credit_Memo__c LIMIT 1];
    List<Price_Book_Item__c> pbis = [SELECT Id FROM Price_Book_Item__c LIMIT 10];

    CreditMemoItemHandler_Add.CreateCreditMemoItemsRequest request = new CreditMemoItemHandler_Add.CreateCreditMemoItemsRequest();
    request.cmId = cms[0].Id;
    request.sourceIds = new List<Id>(new Map<Id, Price_Book_Item__c>(pbis).keySet());
    request.nextSeqNumber = 0;
    request.parentCreditMemoItemId = null;

    List<Credit_Memo_Item__c> res = CreditMemoItemHandler_Add.CreateCreditMemoItems(request);

    System.assert(res.size() > 0, 'should have some cmis');

    Test.stopTest();
  }

  static testMethod void CreateCreditMemoItems_Inv_Test()
  {
    Test.startTest();

    List<Credit_Memo__c> cms = [SELECT Id FROM Credit_Memo__c LIMIT 1];
    List<Invoice_Item__c> invis = [SELECT Id FROM Invoice_Item__c LIMIT 10];

    CreditMemoItemHandler_Add.CreateCreditMemoItemsRequest request = new CreditMemoItemHandler_Add.CreateCreditMemoItemsRequest();
    request.cmId = cms[0].Id;
    request.sourceIds = new List<Id>(new Map<Id, Invoice_Item__c>(invis).keySet());
    request.nextSeqNumber = 0;
    request.parentCreditMemoItemId = null;

    List<Credit_Memo_Item__c> res = CreditMemoItemHandler_Add.CreateCreditMemoItems(request);

    System.assert(res.size() > 0, 'should have some cmis');

    Test.stopTest();
  }

}
