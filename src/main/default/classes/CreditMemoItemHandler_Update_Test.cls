@isTest
public class CreditMemoItemHandler_Update_Test
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
  }

  static testMethod void CreditMemoItemUpdate() {
    Test.startTest();

    List<Credit_Memo_Item__c> cmis = [SELECT Id, Description__c FROM Credit_Memo_Item__c LIMIT 1];
    cmis[0].Description__c = 'updated';

    CreditMemoItemHandler_Update.UpdateCreditMemoItemRequest request = new CreditMemoItemHandler_Update.UpdateCreditMemoItemRequest();
    request.cmItem = cmis[0];
    request.typeStr = 'Credit_Memo_Item__c';
    request.cmFields = 'Id, Name';
    request.cmiFields = 'Id, Name';

    CreditMemoItemHandler_Update.UpdateCreditMemoItemResult res = CreditMemoItemHandler_Update.CreditMemoItemUpdate(request);

    List<Credit_Memo_Item__c> cmis2 = [SELECT Id, Description__c FROM Credit_Memo_Item__c LIMIT 1];

    System.assert(cmis2[0].Description__c=='updated', 'should have updated cmis');

    Test.stopTest();
  }

  static testMethod void CreditMemoItemsUpdate() {
    Test.startTest();

    List<Credit_Memo_Item__c> cmis = [SELECT Id, Description__c FROM Credit_Memo_Item__c LIMIT 1];
    cmis[0].Description__c = 'updated again';

    CreditMemoItemHandler_Update.UpdateCreditMemoItemsRequest request = new CreditMemoItemHandler_Update.UpdateCreditMemoItemsRequest();
    request.typeStr = 'Credit_Memo_Item__c';
    request.cmFields = 'Id, Name';
    request.cmiFields = 'Id, Name';
    request.cmiList = cmis;

    CreditMemoItemHandler_Update.CreditMemoItemsUpdateResult res = CreditMemoItemHandler_Update.CreditMemoItemsUpdate(request);

    List<Credit_Memo_Item__c> cmis2 = [SELECT Id, Description__c FROM Credit_Memo_Item__c LIMIT 1];

    System.assert(cmis2[0].Description__c=='updated again', 'should have updated cmis');

    Test.stopTest();
  }

  static testMethod void CreditMemoItemsUpdateOver200() {
    Test.startTest();

    List<Credit_Memo__c> cms = [SELECT Id FROM Credit_Memo__c LIMIT 1];

    List<Credit_Memo_Item__c> newcmis = new List<Credit_Memo_Item__c>();
    for(integer i = 0; i<201 ; i++){
        Credit_Memo_Item__c cmi = new Credit_Memo_Item__c();
        cmi.Credit_Memo__c = cms[0].Id;
        cmi.Description__c = 'cmi '+i;
        newcmis.add(cmi);
    }
    insert newcmis;


    List<Credit_Memo_Item__c> cmis = [SELECT Id, Description__c FROM Credit_Memo_Item__c LIMIT 201];
    for(integer i = 0; i<201 ; i++){
      cmis[i].Description__c = 'updated again '+i;
    }

    CreditMemoItemHandler_Update.UpdateCreditMemoItemsRequest request = new CreditMemoItemHandler_Update.UpdateCreditMemoItemsRequest();
    request.typeStr = 'Credit_Memo_Item__c';
    request.cmFields = 'Id, Name';
    request.cmiFields = 'Id, Name';
    request.cmiList = cmis;

    CreditMemoItemHandler_Update.CreditMemoItemsUpdateResult res = CreditMemoItemHandler_Update.CreditMemoItemsUpdate(request);

    List<Credit_Memo_Item__c> cmis2 = [SELECT Id, Description__c FROM Credit_Memo_Item__c WHERE Description__c='updated again 50' LIMIT 1];

    System.assert(cmis2.size() > 0, 'should have updated cmis');

    Test.stopTest();
  }

}
