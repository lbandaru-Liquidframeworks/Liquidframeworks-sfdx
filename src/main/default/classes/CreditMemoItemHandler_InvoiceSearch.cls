public class CreditMemoItemHandler_InvoiceSearch
{

  public static String GetAvailableInvoicesForCreditMemo(String processStr) {
      JSONParser parser = JSON.createParser(processStr);
      Type resultType = Type.forName('CreditMemoItemHandler_InvoiceSearch.GetAvailableInvoicesForCreditMemoRequest');
      CreditMemoItemHandler_InvoiceSearch.GetAvailableInvoicesForCreditMemoRequest readValueAsResults = (CreditMemoItemHandler_InvoiceSearch.GetAvailableInvoicesForCreditMemoRequest)parser.readValueAs(resultType);

      GetAvailableInvoicesForCreditMemoResult result = GetAvailableInvoicesForCreditMemo(readValueAsResults);

      return JSON.serializePretty(result, false);
  }

  public static GetAvailableInvoicesForCreditMemoResult GetAvailableInvoicesForCreditMemo(GetAvailableInvoicesForCreditMemoRequest request) {
      String creditMemoId = request.creditMemoId;
      String itemLimit = request.itemLimit;
      String itemOffset = request.itemOffset;
      String sortby = request.sortby;
      String sortdir = request.sortdir;
      String invoiceFields = request.invoiceFields;
      String invoiceItemFields = request.invoiceItemFields;
      String creditMemoItemParentInvoiceItemId = request.creditMemoItemParentInvoiceItemId;

      String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
      GetAvailableInvoicesForCreditMemoResult result = new GetAvailableInvoicesForCreditMemoResult();

      if(!invoiceItemFields.contains('Invoice__c')) {
        invoiceItemFields += ', '+fxNamespacePrefix+'Invoice__c';
      }
      if(!invoiceItemFields.contains('Parent_Invoice_Item__c')) {
        invoiceItemFields += ', '+fxNamespacePrefix+'Parent_Invoice_Item__c';
      }
      if(!invoiceItemFields.contains('Name')) {
        invoiceItemFields += ', '+'Name';
      }
      if(!invoiceItemFields.contains('Item_Code__c')) {
        invoiceItemFields += ', '+fxNamespacePrefix+'Item_Code__c';
      }
      if(!invoiceItemFields.contains('Price_Book_Item__r.Name')) {
        invoiceItemFields += ', '+fxNamespacePrefix+'Price_Book_Item__r.Name';
      }
      if(!invoiceItemFields.contains('Description__c')) {
        invoiceItemFields += ', '+fxNamespacePrefix+'Description__c';
      }

      Credit_Memo__c creditMemo = [SELECT Id, Price_Book__c FROM Credit_Memo__c WHERE Id=:creditMemoId LIMIT 1];

      Set<Id> creditMemoedInvoiceIds = new Set<Id>();
      Set<Id> creditMemoedInvoiceItemIds = new Set<Id>();

      for(Credit_Memo_Item__c cmi : [SELECT Id, Invoice_Item__c, Invoice_Item__r.Invoice__c FROM Credit_Memo_Item__c WHERE Credit_Memo__c=:creditMemoId]) {
        if (!creditMemoedInvoiceIds.contains(cmi.Invoice_Item__r.Invoice__c)) {
            creditMemoedInvoiceIds.add(cmi.Invoice_Item__r.Invoice__c);
        }
        if (!creditMemoedInvoiceItemIds.contains(cmi.Invoice_Item__c)) {
            creditMemoedInvoiceItemIds.add(cmi.Invoice_Item__c);
        }
      }

      String commandText = 'SELECT ' + invoiceFields + ' FROM ' + fxNamespacePrefix + 'Invoice__c ';
      commandText += ' WHERE IsDeleted=false ';
      commandText += ' AND Id IN :creditMemoedInvoiceIds ';

      result.selectedInvoices = Database.query(commandText);

      commandText = 'SELECT ' + invoiceItemFields + ' FROM ' + fxNamespacePrefix + 'Invoice_Item__c ';
      commandText += ' WHERE IsDeleted=false ';
      commandText += ' AND Id IN :creditMemoedInvoiceItemIds ';

      result.selectedInvoiceItems = Database.query(commandText);

      String invoiceItemFilterSoql = ItemBuilderHelper.GetFilterSoql(request.invoiceItemfilters, '');
      String invoiceFilterSoql = ItemBuilderHelper.GetFilterSoql(request.invoicefilters, 'Invoice__r.');

      commandText = 'SELECT '+invoiceItemFields+', (SELECT Id FROM Credit_Memo_Items__r) FROM ' + fxNamespacePrefix + 'Invoice_Item__c WHERE ' + fxNamespacePrefix + 'Parent_Invoice_Item__c = NULL';
      commandText += invoiceFilterSoql;
      commandText += invoiceItemFilterSoql;

      if (creditMemoItemParentInvoiceItemId != null && creditMemoItemParentInvoiceItemId != '') {
          commandText += ' AND Id != :creditMemoItemParentInvoiceItemId ';
      }

      result.parentInvoiceItems = Database.query(commandText);

      commandText = 'SELECT '+invoiceItemFields+', (SELECT Id FROM Credit_Memo_Items__r) FROM ' + fxNamespacePrefix + 'Invoice_Item__c WHERE ' + fxNamespacePrefix + 'Parent_Invoice_Item__c != NULL';
      commandText += invoiceFilterSoql;
      commandText += invoiceItemFilterSoql;

      if (creditMemoItemParentInvoiceItemId != null && creditMemoItemParentInvoiceItemId != '') {
          commandText += ' AND Id != :creditMemoItemParentInvoiceItemId ';
      }

      result.childInvoiceItems = Database.query(commandText);

      Set<Id> availableInvIds = new Set<Id>();
      for (Invoice_Item__c ii : result.parentInvoiceItems) {
        if (!availableInvIds.contains(ii.Invoice__c))
        availableInvIds.add(ii.Invoice__c);
      }

      commandText = 'SELECT ' + invoiceFields + ' FROM ' + fxNamespacePrefix + 'Invoice__c ';
      commandText += ' WHERE IsDeleted=false ';
      commandText += ' AND Id IN :availableInvIds ';

      String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
      String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
      String nullsLast = (sb != '') ? 'NULLS LAST' : '';
      commandText += sb + ' ' + sd + ' ' + nullsLast;

      String lim = (itemLimit != '' ) ? (Integer.valueOf(itemLimit) > 2000) ? '2000' : itemLimit : '2000';
      String off = (itemOffset != '' ) ? (Integer.valueOf(itemOffset) > 2000) ? '2000' : itemOffset : '0';
      commandText += ' LIMIT ' + lim + ' OFFSET ' + off + ' ';

      result.availableInvoices = Database.query(commandText);


      return result;
  }

  public static String GetCreditMemoAvailableInvoiceSearchFilter() {
    String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
    String searchFieldSetName = fxNamespacePrefix+'CMBSearchFields';

    GetCreditMemoAvailableInvoiceSearchFilterResult result = new GetCreditMemoAvailableInvoiceSearchFilterResult();
    result.invoiceSearchFields = ItemBuilderHelper.ProcessSearchFieldSet(fxNamespacePrefix+'Invoice__c', searchFieldSetName);
    result.invoiceItemSearchFields = ItemBuilderHelper.ProcessSearchFieldSet(fxNamespacePrefix+'Invoice_Item__c', searchFieldSetName);
    result.keyPrefixesForObjects = ItemBuilderHelper.getKeyPrefixesForObjects();

    return JSON.serializePretty(result, false);
  }

  public class GetAvailableInvoicesForCreditMemoRequest {
      public String creditMemoId;
      public String itemLimit;
      public String itemOffset;
      public String sortby;
      public String sortdir;
      public String invoiceFields;
      public String invoiceItemFields;
      public String creditMemoItemParentInvoiceItemId;
      public List<ItemBuilderHelper.SearchFieldRequest> invoicefilters;
      public List<ItemBuilderHelper.SearchFieldRequest> invoiceItemfilters;
  }

  public class GetAvailableInvoicesForCreditMemoResult {
      public List<Invoice__c> selectedInvoices;
      public List<Invoice_Item__c> selectedInvoiceItems;
      public List<Invoice__c> availableInvoices;
      public List<Invoice_Item__c> childInvoiceItems;
      public List<Invoice_Item__c> parentInvoiceItems;
      public string soql;
  }

  public class GetCreditMemoAvailableInvoiceSearchFilterResult {
    public List<ItemBuilderHelper.SearchFieldResult> invoiceSearchFields;
    public List<ItemBuilderHelper.SearchFieldResult> invoiceItemSearchFields;
    public Map<String, String> keyPrefixesForObjects;
  }

}
