public class CreditMemoItemHandler_PBISearch
{

  public static String GetAvailablePBIsForCreditMemo(String processStr) {
      JSONParser parser = JSON.createParser(processStr);
      Type resultType = Type.forName('CreditMemoItemHandler_PBISearch.GetAvailablePBIsForCreditMemoRequest');
      CreditMemoItemHandler_PBISearch.GetAvailablePBIsForCreditMemoRequest readValueAsResults = (CreditMemoItemHandler_PBISearch.GetAvailablePBIsForCreditMemoRequest)parser.readValueAs(resultType);

      GetAvailablePBIsForCreditMemoResult result = GetAvailablePBIsForCreditMemo(readValueAsResults);

      return JSON.serializePretty(result, false);
  }

  public static GetAvailablePBIsForCreditMemoResult GetAvailablePBIsForCreditMemo(GetAvailablePBIsForCreditMemoRequest request) {
      String creditMemoId = request.creditMemoId;
      String showItemsAlreadyOnTheCreditMemo = request.showItemsAlreadyOnTheCreditMemo;
      String itemLimit = request.itemLimit;
      String itemOffset = request.itemOffset;
      String sortby = request.sortby;
      String sortdir = request.sortdir;
      String pbiFields = request.pbiFields;
      String creditMemoItemParentPBIId = request.creditMemoItemParentPBIId;

      String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
      GetAvailablePBIsForCreditMemoResult result = new GetAvailablePBIsForCreditMemoResult();

      if(!pbiFields.contains('Price_Book__c')) {
        pbiFields += ', '+fxNamespacePrefix+'Price_Book__c';
      }
      if(!pbiFields.contains('Parent_Price_Book_Item__c')) {
        pbiFields += ', '+fxNamespacePrefix+'Parent_Price_Book_Item__c';
      }
      if(!pbiFields.contains('Name')) {
        pbiFields += ', '+'Name';
      }
      if(!pbiFields.contains('Catalog_Item_Code__c')) {
        pbiFields += ', '+fxNamespacePrefix+'Catalog_Item_Code__c';
      }
      if(!pbiFields.contains('Description_Override__c')) {
        pbiFields += ', '+fxNamespacePrefix+'Description_Override__c';
      }
      if(!pbiFields.contains('Catalog_Description__c')) {
        pbiFields += ', '+fxNamespacePrefix+'Catalog_Description__c';
      }
      if(!pbiFields.contains('PBI_Requires_Parent_Item__c')) {
        pbiFields += ', '+fxNamespacePrefix+'Requires_Parent_Item__c';
      }

      Set<Id> creditMemodPBIIds = new Set<Id>();

      for(Credit_Memo_Item__c cmi : [SELECT Id, Price_Book_Item__c FROM Credit_Memo_Item__c WHERE Credit_Memo__c=:creditMemoId]) {
        if (!creditMemodPBIIds.contains(cmi.Price_Book_Item__c)) {
            creditMemodPBIIds.add(cmi.Price_Book_Item__c);
        }
      }

      String commandText = 'SELECT ' + pbiFields + ' FROM ' + fxNamespacePrefix + 'Price_Book_Item__c ';
      commandText += ' WHERE IsDeleted=false ';
      commandText += ' AND Id IN :creditMemodPBIIds ';

      result.selectedPBIs = Database.query(commandText);

      commandText = 'SELECT ' + pbiFields + ' FROM ' + fxNamespacePrefix + 'Price_Book_Item__c ';
      commandText += ' WHERE IsDeleted=false ';
      commandText += ' AND ' + fxNamespacePrefix + 'Parent_Price_Book_Item__c = NULL ';

      if (showItemsAlreadyOnTheCreditMemo == 'false') {
          if (creditMemodPBIIds.size() > 0) {
              commandText += ' AND Id not in :creditMemodPBIIds ';
          }
      }

      if (creditMemoItemParentPBIId != null && creditMemoItemParentPBIId != '') {
          commandText += ' AND Id != :creditMemoItemParentPBIId ';
      }

      commandText += ItemBuilderHelper.GetFilterSoql(request.availablePBIfilters, '');

      String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
      String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
      String nullsLast = (sb != '') ? 'NULLS LAST' : '';
      commandText += sb + ' ' + sd + ' ' + nullsLast;

      String lim = (itemLimit != '' ) ? (Integer.valueOf(itemLimit) > 2000) ? '2000' : itemLimit : '2000';
      String off = (itemOffset != '' ) ? (Integer.valueOf(itemOffset) > 2000) ? '2000' : itemOffset : '0';
      commandText += ' LIMIT ' + lim + ' OFFSET ' + off + ' ';

      result.soql = commandText;

      result.availablePBIs = Database.query(commandText);

      Set<Id> availablePBIIds = new Map<Id, Price_Book_Item__c>(result.availablePBIs).keySet();

      commandText = 'SELECT '+pbiFields+' FROM ' + fxNamespacePrefix + 'Price_Book_Item__c WHERE ' + fxNamespacePrefix + 'Parent_Price_Book_Item__c IN :availablePBIIds';

      if (creditMemoItemParentPBIId != null && creditMemoItemParentPBIId != '') {
          commandText += ' AND Id != :creditMemoItemParentPBIId ';
      }

      result.childPBIs = Database.query(commandText);

      return result;
  }

  public static String GetCreditMemoAvailablePBISearchFilter() {
    String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
    String objName = fxNamespacePrefix+'Price_Book_Item__c';
    String searchFieldSetName = fxNamespacePrefix+'CMBSearchFields';
    List<ItemBuilderHelper.SearchFieldResult> pbiSearchFields = new List<ItemBuilderHelper.SearchFieldResult>();
    List<Schema.FieldSetMember> fields = new List<Schema.FieldSetMember>();

    Schema.FieldSet fieldSet = MetadataHelper.GetFieldSet(objName, searchFieldSetName);
  System.Debug(fieldSet);
    if (fieldSet != null) fields = fieldSet.getFields();

    SObjectType objType = Schema.getGlobalDescribe().get(objName);
    Schema.DescribeSObjectResult obj = objType.getDescribe();
    Map<String,Schema.SObjectField> fieldsMap = obj.fields.getMap();
    Schema.DescribeFieldResult priceBookFieldInfo = fieldsMap.get(fxNamespacePrefix+'Price_Book__c').getDescribe();

    Boolean found = false;
    if (fields != null) {
      pbiSearchFields = ItemBuilderHelper.ProcessSearchFieldSet(objName, searchFieldSetName);

      //look for pricebook in the filter fieldSet. If not there is needs to be added.

      String priceBookFieldInfoName = priceBookFieldInfo.getName();
      for(Schema.FieldSetMember field: fields) {
        if (field.getFieldPath() == priceBookFieldInfoName) {
          found = true;
          break;
        }
      }
    }
    if (!found) {
      ItemBuilderHelper.SearchFieldResult searchField = new ItemBuilderHelper.SearchFieldResult();
      if(priceBookFieldInfo.getReferenceTo().size()>0) {
        Schema.SObjectType reference = priceBookFieldInfo.getReferenceTo()[0];
        Schema.DescribeSObjectResult fieldObjDescribe = reference.getDescribe();
        searchField.keyPrefix = fieldObjDescribe.getKeyPrefix();
        searchField.ApiName = fieldObjDescribe.getName();
        searchField.label = fieldObjDescribe.getLabel();
        searchField.type = Schema.DisplayType.Reference;
      }

      pbiSearchFields.add(searchField);
    }

    GetCreditMemoAvailablePBISearchFilterResult result = new GetCreditMemoAvailablePBISearchFilterResult();
    result.pbiSearchFields = pbiSearchFields;
    result.keyPrefixesForObjects = ItemBuilderHelper.getKeyPrefixesForObjects();

    return JSON.serializePretty(result, false);
  }

  public class GetAvailablePBIsForCreditMemoRequest {
      public String creditMemoId;
      public String showItemsAlreadyOnTheCreditMemo;
      public String itemLimit;
      public String itemOffset;
      public String sortby;
      public String sortdir;
      public String pbiFields;
      public String creditMemoItemParentPBIId;
      public List<ItemBuilderHelper.SearchFieldRequest> availablePBIfilters;
  }

  public class GetAvailablePBIsForCreditMemoResult {
      public List<Price_Book_Item__c> selectedPBIs;
      public List<Price_Book_Item__c> availablePBIs;
      public List<Price_Book_Item__c> childPBIs;
      public string soql;
  }

  public class GetCreditMemoAvailablePBISearchFilterResult {
    public List<ItemBuilderHelper.SearchFieldResult> pbiSearchFields;
    public Map<String, String> keyPrefixesForObjects;
  }

}
