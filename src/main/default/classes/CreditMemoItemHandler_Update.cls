public class CreditMemoItemHandler_Update
{
  public static String CreditMemoItemUpdate(String processStr) {
      JSONParser parser = JSON.createParser(processStr);
      Type resultType = Type.forName('CreditMemoItemHandler_Update.UpdateCreditMemoItemRequest');
      CreditMemoItemHandler_Update.UpdateCreditMemoItemRequest readValueAsResults = (CreditMemoItemHandler_Update.UpdateCreditMemoItemRequest)parser.readValueAs(resultType);

      UpdateCreditMemoItemResult updateCreditMemoItemResult = CreditMemoItemUpdate(readValueAsResults);
      System.debug(updateCreditMemoItemResult);

      return JSON.serializePretty(updateCreditMemoItemResult, false);
  }

  public static UpdateCreditMemoItemResult CreditMemoItemUpdate(UpdateCreditMemoItemRequest request) {
    Credit_Memo_Item__c cmItem = request.cmItem;
    string typeStr = request.typeStr;
    string cmFields = request.cmFields;
    string cmiFields = request.cmiFields;

    sObject[] cmItems = new sObject[]{ cmItem };
    Database.SaveResult[] res = Database.update(cmItems, false);

    UpdateCreditMemoItemResult results = new UpdateCreditMemoItemResult();
    results.id = cmItem.id;
    results.success = res[0].success;
    results.errors = new List<CreditMemoItemUpdateError>();

    for (Database.SaveResult sr : res) {
        for(Database.Error err : sr.getErrors()) {
            CreditMemoItemUpdateError ue = new CreditMemoItemUpdateError();
            ue.message = err.getMessage();
            ue.fields = err.getFields();
            results.errors.add(ue);
        }
    }

    String ns = UtilityGetNamespace.CurrentNamespace();

    if (!cmiFields.contains('LastModifiedDate')) {
        cmiFields += ', LastModifiedDate';
    }
    if (!cmFields.contains('LastModifiedDate')) {
        cmFields += ', LastModifiedDate';
    }
    if (!cmiFields.contains('Credit_Memo__c')) {
        cmiFields += ','+ns+'Credit_Memo__c';
    }

    //get cm id
    String soql = 'SELECT Credit_Memo__c' + ' FROM '+ns+'Credit_Memo_Item__c WHERE Id=\'' + cmItem.Id + '\' LIMIT 1';
    System.debug(soql);
    Credit_Memo_Item__c cmi = database.query(soql);

    //get cm
    String cmSoql = 'SELECT ' + cmFields + ' FROM '+ns+'Credit_Memo__c WHERE Id=\'' + cmi.Credit_Memo__c + '\' LIMIT 1';
    System.debug(cmSoql);
    Credit_Memo__c cm = database.query(cmSoql);

    //get cmItem
    String cmiSoql = 'SELECT ' + cmiFields + ' FROM '+ns+'Credit_Memo_Item__c WHERE Id=\'' + cmItem.Id + '\'';
    System.debug(cmiSoql);
    cmi = database.query(cmiSoql);

    //get cmItem siblings
    String siblingsoql = 'SELECT ' + cmiFields + ' FROM '+ns+'Credit_Memo_Item__c WHERE IsDeleted=false and '+ns+'Parent_Credit_Memo_Item__c = NULL and '+ns+'Credit_Memo__c=\'' + cm.Id + '\' AND Id!=\'' + cmItem.Id + '\'';
    System.debug(siblingsoql);
    List<Credit_Memo_Item__c> cmiSiblings = database.query(siblingsoql);

    //get cm children
    String cmiChildrenSql = 'SELECT ' + cmiFields + ' FROM '+ns+'Credit_Memo_Item__c WHERE IsDeleted=false and '+ns+'Parent_Credit_Memo_Item__c != NULL AND '+ns+'Credit_Memo__c=\'' + cm.Id + '\'';
    System.debug(cmSoql);
    List<Credit_Memo_Item__c> cmiChildren = database.query(cmiChildrenSql);

    results.cmItem = cmi;
    results.creditMemo = cm;
    results.cmiChildren = cmiChildren;
    results.cmiSiblings = cmiSiblings;

    return results;
  }

  public static String CreditMemoItemsUpdate(String processStr) {
      JSONParser parser = JSON.createParser(processStr);
      Type resultType = Type.forName('CreditMemoItemHandler_Update.UpdateCreditMemoItemsRequest');
      CreditMemoItemHandler_Update.UpdateCreditMemoItemsRequest readValueAsResults = (CreditMemoItemHandler_Update.UpdateCreditMemoItemsRequest)parser.readValueAs(resultType);

      CreditMemoItemsUpdateResult resCreditMemoItemsUpdate = CreditMemoItemsUpdate(readValueAsResults);
      System.debug(resCreditMemoItemsUpdate);

      return JSON.serializePretty(resCreditMemoItemsUpdate, false);
  }

  public static CreditMemoItemsUpdateResult CreditMemoItemsUpdate(UpdateCreditMemoItemsRequest request) {
      List<Credit_Memo_Item__c> cmiList = request.cmiList;
      string typeStr = request.typeStr;
      string cmFields = request.cmFields;
      string cmiFields = request.cmiFields;

      String ns = UtilityGetNamespace.CurrentNamespace();

      if (!cmFields.contains('LastModifiedDate')) {
          cmFields += ', LastModifiedDate';
      }

      //get cmItem
      String cmItemsoql = 'SELECT Credit_Memo__c FROM '+ns+'Credit_Memo_Item__c WHERE IsDeleted=false and Id=\'' + cmiList[0].Id + '\'';
      System.debug(cmItemsoql);
      Credit_Memo_Item__c cmi = database.query(cmItemsoql);

      //get cm
      String cmSoql = 'SELECT ' + cmFields + ' FROM '+ns+'Credit_Memo__c WHERE Id=\'' + cmi.Credit_Memo__c + '\' LIMIT 1';
      System.debug(cmSoql);
      Credit_Memo__c cm = database.query(cmSoql);

      CreditMemoItemsUpdateResult creditMemoItemsUpdateResult = new CreditMemoItemsUpdateResult();
      creditMemoItemsUpdateResult.updateResult = new List<CreditMemoItemUpdateResult>();

      if (cmiList.size()>200) {
          Database.SaveResult[] res = Database.update(cmiList, false);
          System.Debug(res);

          Integer i = 0;
          for (Database.SaveResult sr : res) {
              CreditMemoItemUpdateResult result = new CreditMemoItemUpdateResult();
              result.id = sr.getId();
              result.success = sr.success;

              result.errors = new List<CreditMemoItemUpdateError>();
              for(Database.Error err : sr.getErrors()) {
                  CreditMemoItemUpdateError ue = new CreditMemoItemUpdateError();
                  ue.message = err.getMessage();
                  ue.fields = err.getFields();
                  result.errors.add(ue);
                  result.id = cmiList[i].Id;
              }

              creditMemoItemsUpdateResult.updateResult.add(result);
              i++;
          }
      } else {
          for(Credit_Memo_Item__c cmi1 : cmiList) {
              Database.SaveResult sr1 = Database.update(cmi1, false);
              System.Debug(sr1);

              CreditMemoItemUpdateResult result = new CreditMemoItemUpdateResult();
              result.id = sr1.getId();
              result.success = sr1.success;

              result.errors = new List<CreditMemoItemUpdateError>();
              for(Database.Error err : sr1.getErrors()) {
                  CreditMemoItemUpdateError ue = new CreditMemoItemUpdateError();
                  ue.message = err.getMessage();
                  ue.fields = err.getFields();
                  result.errors.add(ue);
                  result.id = cmi1.Id;
              }

              creditMemoItemsUpdateResult.updateResult.add(result);

          }
      }

      //validate cmiList list
      String cmiSoql = 'SELECT Id FROM '+ns+'Credit_Memo_Item__c WHERE IsDeleted=false and '+ns+'Credit_Memo__c=\'' + cmi.Credit_Memo__c + '\'';
      List<Credit_Memo_Item__c> verifiedCmiList = (List<Credit_Memo_Item__c>)Database.query(cmiSoql);
      System.debug(verifiedCmiList);

      if (!cmiFields.contains('LastModifiedDate')) {
          cmiFields += ', LastModifiedDate';
      }

      if (!cmiFields.contains('Credit_Memo__c')) {
          cmiFields += ','+ns+'Credit_Memo__c';
      }

      //get cmItems
      String cmItemssoql = 'SELECT ' + cmiFields + ', IsDeleted FROM '+ns+'Credit_Memo_Item__c WHERE IsDeleted=false and '+ns+'Credit_Memo__c=\'' + cm.Id + '\'';
      System.debug(cmItemssoql);
      List<Credit_Memo_Item__c> cmItems = database.query(cmItemssoql);

      creditMemoItemsUpdateResult.creditMemo = cm;
      creditMemoItemsUpdateResult.cmItems = cmItems;

      return creditMemoItemsUpdateResult;
  }

  public class CreditMemoItemsUpdateResult {
      public List<CreditMemoItemUpdateResult> updateResult  { get; set; }
      public Credit_Memo__c creditMemo;
      public List<Credit_Memo_Item__c> cmItems;
  }

  public class CreditMemoItemUpdateResult {
      public String id { get; set; }
      public Boolean success  { get; set; }
      public List<CreditMemoItemUpdateError> errors  { get; set; }
  }

  public class CreditMemoItemUpdateError {
      public String message { get; set; }
      public List<String> fields { get; set; }
  }

  public class UpdateCreditMemoItemsRequest {
      public string typeStr;
      public String cmFields;
      public String cmiFields;
      public List<Credit_Memo_Item__c> cmiList;
  }

  public class UpdateCreditMemoItemRequest {
      public Credit_Memo_Item__c cmItem;
      public string typeStr;
      public string cmFields;
      public string cmiFields;
  }

  public class UpdateCreditMemoItemResult {
      public Credit_Memo_Item__c cmItem;
      public Credit_Memo__c creditMemo;
      public List<Credit_Memo_Item__c> cmiChildren;
      public List<Credit_Memo_Item__c> cmiSiblings;

      public String id { get; set; }
      public Boolean success  { get; set; }
      public List<CreditMemoItemUpdateError> errors  { get; set; }
  }
}
