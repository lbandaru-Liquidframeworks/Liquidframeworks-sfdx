public class InvoiceItemHandler_Transactions
{
  static String creditMemoKeyPrefix = Credit_Memo__c.sObjectType.getDescribe().keyPrefix;

  public static String CreateInvoiceItems(String processStr) {
    JSONParser parser = JSON.createParser(processStr);
    Type resultType = Type.forName('InvoiceItemHandler_Transactions.CreateInvoiceItemsRequest');
    InvoiceItemHandler_Transactions.CreateInvoiceItemsRequest readValueAsResults = (InvoiceItemHandler_Transactions.CreateInvoiceItemsRequest)parser.readValueAs(resultType);

    List<Invoice_Item__c> result = CreateInvoiceItems(readValueAsResults);

    return JSON.serializePretty(result, false);
  }

  public static List<Invoice_Item__c> CreateInvoiceItems(CreateInvoiceItemsRequest request)
  {
      Id invId = request.invId;
      List<CreditMemoIdAndAmount> sourceItems = request.sourceItems;
      Decimal nextSeqNumber = request.nextSeqNumber;
      String invoiceItemParentId = request.parentInvItemId;

      if(sourceItems.isEmpty()) return null;
      Schema.DescribeSObjectResult rInvoiceItem = Invoice_Item__c.sObjectType.getDescribe();
      if(!rInvoiceItem.isAccessible() || !rInvoiceItem.isCreateable()) {
          return null;
      }

      List<Id> sourceIds = new List<Id>();
      for(CreditMemoIdAndAmount sourceItem : sourceItems) {
        sourceIds.add(sourceItem.Id);
      }

      Invoice__c invoice = [SELECT Id, Price_Book__c FROM Invoice__c WHERE Id=:invId];
      Price_Book__c pricebook = [SELECT Id, AddTktItemsByPBSeqNum__c FROM Price_Book__c WHERE Id=:invoice.Price_Book__c ];

      CreditMemoIdAndAmount sourceItem = sourceItems.get(0);
      String itemId = sourceItem.Id;
      List<Invoice_Item__c> rootItems = null;
      List<Credit_Memo_Applied__c> cmas = null;

      try
      {
        if(itemId.startsWith(creditMemoKeyPrefix)) {
            List<Credit_Memo__c> creditMemos = [SELECT Id FROM Credit_Memo__c WHERE Id IN :sourceIds];
            Set<Id> creditMemoIds = new Map<Id, Credit_Memo__c>(creditMemos).keySet();

            rootItems =  CreateInvoiceItemWithCreditMemo(invId, creditMemoIds, invoiceItemParentId);
            insert rootItems;

            cmas = CreateCreditMemoApplied(invId, creditMemoIds, sourceItems);
            insert cmas;
        }

        if(rootItems == null || rootItems.isEmpty()) return null;

        if (!pricebook.AddTktItemsByPBSeqNum__c) {
          InvoiceItemHandler.ApplySequenceNumber(rootItems, nextSeqNumber);
          update rootItems;
        }

        Map<Id, Invoice_Item__c> newItemsMap = new Map<Id, Invoice_Item__c>(rootItems);
        Set<Id> invItemIds = newItemsMap.keySet();

        List<String> fields = new List<String>(Schema.sObjectType.Invoice_Item__c.fields.getMap().keySet());
        String fieldsStr = String.join(fields, ',');

        String ns = StringUtility.FXNamespace();
        String inviSoql = String.format('SELECT {0} FROM {1} WHERE Id IN :invItemIds', new String[]{fieldsStr, ns+'Invoice_Item__c'});
        List<Invoice_Item__c> invItems = (List<Invoice_Item__c>)Database.query(inviSoql);

        return invItems;
      }
      catch (Exception ex)
      {
          throw ex;
      }
      finally
      {
          //RuleEngineCore.RuleEngineInProgress = flagValue;
      }
  }

  static List<Credit_Memo_Applied__c> CreateCreditMemoApplied(Id invId, Set<Id> creditMemoIds, List<CreditMemoIdAndAmount> sourceItems) {
    Map<Id, CreditMemoIdAndAmount> sourceItemsMap = new Map<Id, CreditMemoIdAndAmount>();
    for(CreditMemoIdAndAmount sourceItem : sourceItems) {
      sourceItemsMap.put(sourceItem.Id, sourceItem);
    }

    List<Credit_Memo_Applied__c> newItems = new List<Credit_Memo_Applied__c>();
    SobjectType cmaType = Credit_Memo_Applied__c.SobjectType;

    for(Id cmId : creditMemoIds) {
      CreditMemoIdAndAmount sourceItem = sourceItemsMap.get(cmId);

      Credit_Memo_Applied__c cma = (Credit_Memo_Applied__c)cmaType.newSObject();
      cma.Amount__c = sourceItem.AmountToApply;
      cma.Date__c = Date.today();
      cma.Invoice__c = invId;
      cma.Credit_Memo__c = cmId;

      newItems.add(cma);
    }

    return newItems;
  }

  static List<Invoice_Item__c> CreateInvoiceItemWithCreditMemo(Id invId, Set<Id> sourceItemIds, String invoiceItemParentId)
  {

      List<Invoice_Item__c> newItems = new List<Invoice_Item__c>();

      String ns = UtilityGetNamespace.CurrentNamespace();

      Set<String> cmFields = Credit_Memo__c.sObjectType.getDescribe().fields.getMap().keySet();
      Set<String> cmQueryFields = new Set<String>();
      cmQueryFields.addAll(cmFields);

      String soql = String.format('SELECT {1} FROM {0}Credit_Memo__c WHERE IsDeleted=false AND (Id IN :sourceItemIds) ',
          new String[]{ns, String.join(new List<String>(cmQueryFields), ',')});
System.debug(sourceItemIds);
System.debug(soql);

      List<Credit_Memo__c> sources = (List<Credit_Memo__c>)Database.query(soql);
      Map<Id, Credit_Memo__c> sourcesLookup = new Map<Id, Credit_Memo__c>(sources);

      Map<String, String> invItemToCreditMemoFieldMapping =  GetInvoiceItemToCreditMemoFieldMapping(ns.toLowercase(), cmFields);

      SobjectType invItemType = Invoice_Item__c.SobjectType;

      for(Id sourceItemId: sourceItemIds)
      {
          Credit_Memo__c obj = sourcesLookup.get(sourceItemId);
          Invoice_Item__c invi = (Invoice_Item__c)invItemType.newSObject();
          for(String f: invItemToCreditMemoFieldMapping.keySet())
          {
              invi.put(f, obj.get(invItemToCreditMemoFieldMapping.get(f)));
          }
          invi.Invoice__c = invId;

          if (!String.IsEmpty(invoiceItemParentId)) {
            invi.Parent_Invoice_Item__c = invoiceItemParentId;
          }
          newItems.add(invi);
      }
      return newItems;
  }

  static Map<String, String> GetInvoiceItemToCreditMemoFieldMapping(String nsLowercase, Set<String> creditMemoFields)
  {
      Map<String, String> inviToCreditMemoFieldMapping = new Map<String, String>();
      Boolean isInDev = String.isBlank(nsLowercase);

      for(Schema.SObjectField f: Schema.sObjectType.Invoice_Item__c.fields.getMap().values())
      {
          Schema.DescribeFieldResult fd = f.getDescribe();

          if (!fd.isCustom() || !fd.isAccessible() || !fd.isCreateable() || fd.isCalculated() || fd.isAutoNumber())
          {
              continue;
          }
          String inviFieldName = fd.getName().toLowercase();
          if(creditMemoFields.contains(inviFieldName))
          {
              inviToCreditMemoFieldMapping.put(inviFieldName, inviFieldName);
          }
          else if(!isInDev)
          {
              String cmField = '';
              if(inviFieldName.startsWith(nsLowercase))
              {
                  cmField = inviFieldName.replace(nsLowercase, '');
              }
              else
              {
                  cmField = nsLowercase + inviFieldName;
              }
              if(creditMemoFields.contains(cmField))
              {
                  inviToCreditMemoFieldMapping.put(inviFieldName, cmField);
              }
          }
      }
      return inviToCreditMemoFieldMapping;
  }

  public static String GetCreditMemosForInvoice(String processStr) {
    JSONParser parser = JSON.createParser(processStr);
    Type resultType = Type.forName('InvoiceItemHandler_Transactions.GetCreditMemosForInvoiceRequest');
    InvoiceItemHandler_Transactions.GetCreditMemosForInvoiceRequest readValueAsResults = (InvoiceItemHandler_Transactions.GetCreditMemosForInvoiceRequest)parser.readValueAs(resultType);

    GetCreditMemosForInvoiceResult result = GetCreditMemosForInvoice(readValueAsResults);

    return JSON.serializePretty(result, false);
  }

  public static GetCreditMemosForInvoiceResult GetCreditMemosForInvoice(GetCreditMemosForInvoiceRequest request) {
    String invoiceId = request.invoiceId;
    String showItemsAlreadyOnTheInvoice = request.showItemsAlreadyOnTheInvoice;
    String itemLimit = request.itemLimit;
    String itemOffset = request.itemOffset;
    String sortby = request.sortby;
    String sortdir = request.sortdir;
    String creditMemoFields = request.creditMemoFields;
    String invoiceItemParentTktItemId = request.invoiceItemParentTktItemId;
    String showItemsAlreadyInvoiced = request.showItemsAlreadyInvoiced;

    String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
    GetCreditMemosForInvoiceResult result = new GetCreditMemosForInvoiceResult();

    if(!creditMemoFields.contains('Remaining_Credit__c')) {
      creditMemoFields += ', '+fxNamespacePrefix+'Remaining_Credit__c';
    }
    if(!creditMemoFields.contains('Total_Amount__c')) {
      creditMemoFields += ', '+fxNamespacePrefix+'Total_Amount__c';
    }
    if(!creditMemoFields.contains('Total_Applied__c')) {
      creditMemoFields += ', '+fxNamespacePrefix+'Total_Applied__c';
    }
    if(!creditMemoFields.contains('Date__c')) {
      creditMemoFields += ', '+fxNamespacePrefix+'Date__c';
    }
    if(!creditMemoFields.contains('Name')) {
      creditMemoFields += ', '+'Name';
    }

    Invoice__c invoice = [SELECT Id, Price_Book__c FROM Invoice__c WHERE Id=:invoiceId];

    List<Credit_Memo_Applied__c> cmaItems = [SELECT Id, Credit_Memo__c FROM Credit_Memo_Applied__c WHERE Invoice__c=:invoiceId];

    Set<Id> invoicedCreditMemosIds = new Set<Id>();
    Set<Id> invoicedCreditMemoItemsIds = new Set<Id>();

    for(Credit_Memo_Applied__c cmaItem : cmaItems) {
      if (!invoicedCreditMemosIds.contains(cmaItem.Credit_Memo__c)) {
          invoicedCreditMemosIds.add(cmaItem.Credit_Memo__c);
      }
      if (!invoicedCreditMemoItemsIds.contains(cmaItem.Id)) {
          invoicedCreditMemoItemsIds.add(cmaItem.Id);
      }
    }

    String commandText = 'SELECT ' + creditMemoFields + ' FROM ' + fxNamespacePrefix + 'Credit_Memo__c ';
    commandText += ' WHERE IsDeleted=false ';
    commandText += ' AND Id IN :invoicedCreditMemosIds ';

    result.selectedCreditMemos = Database.query(commandText);

    /*
    commandText = 'SELECT ' + tktItemFields + ' FROM ' + fxNamespacePrefix + 'Ticket_Item__c ';
    commandText += ' WHERE IsDeleted=false ';
    commandText += ' AND Id IN :invoicedTktItemIds ';

    result.selectedTktItems = Database.query(commandText);

    */

    commandText = 'SELECT ' + creditMemoFields + ' FROM ' + fxNamespacePrefix + 'Credit_Memo__c ';
    commandText += ' WHERE IsDeleted=false ';
    commandText += ' AND Remaining_Credit__c > 0 ';

/*
    if (showItemsAlreadyInvoiced != 'true') {
        //filter items that are on any invoice
        commandText += ' AND Id NOT IN (SELECT ' + fxNamespacePrefix + 'Credit_Memo__c FROM ' + fxNamespacePrefix + 'Credit_Memo_Item__c WHERE IsDeleted=false AND ' + fxNamespacePrefix + 'Invoice_Item__r.' + fxNamespacePrefix + 'Invoice__c = :invoiceId) ';
    }

    if (showItemsAlreadyOnTheInvoice == 'false') {
        if (invoicedCreditMemosIds.size() > 0) {
            commandText += ' AND Id not in :invoicedCreditMemosIds ';
        }
    }

    if (invoiceItemParentTktItemId != null && invoiceItemParentTktItemId != '') {
        commandText += ' AND Id != :invoiceItemParentTktItemId ';
    }
*/
    commandText += ItemBuilderHelper.GetFilterSoql(request.creditMemofilters, '');

    String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
    String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
    String nullsLast = (sb != '') ? 'NULLS LAST' : '';
    commandText += sb + ' ' + sd + ' ' + nullsLast;

    String lim = (itemLimit != '' ) ? (Integer.valueOf(itemLimit) > 2000) ? '2000' : itemLimit : '2000';
    String off = (itemOffset != '' ) ? (Integer.valueOf(itemOffset) > 2000) ? '2000' : itemOffset : '0';
    commandText += ' LIMIT ' + lim + ' OFFSET ' + off + ' ';

    result.soql = commandText;
System.debug(commandText);

    result.creditMemos = Database.query(commandText);
  System.debug(result.creditMemos.size());

    return result;
  }

  public static String GetAppliedCreditSearchFilter() {
    String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();

    GetAppliedCreditSearchFilterResult result = new GetAppliedCreditSearchFilterResult();
    result.creditMemoSearchFields = ItemBuilderHelper.ProcessSearchFieldSet(fxNamespacePrefix+'Credit_Memo__c', fxNamespacePrefix+'IIBSearchFields');
    result.keyPrefixesForObjects = ItemBuilderHelper.getKeyPrefixesForObjects();

    return JSON.serializePretty(result, false);
  }

  public static String GetHistoricalTransactionsLayout() {
    String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();

    GetHistoricalTransactionsLayoutResult result = new GetHistoricalTransactionsLayoutResult();
    result.creditMemoAppliedFields = ItemBuilderHelper.ProcessSearchFieldSet(fxNamespacePrefix+'Credit_Memo_Applied__c', fxNamespacePrefix+'IIBHistoricalTransactionsColumns');
    result.paymentAppliedFields = ItemBuilderHelper.ProcessSearchFieldSet(fxNamespacePrefix+'Payment_Applied__c', fxNamespacePrefix+'IIBHistoricalTransactionsColumns');
    result.keyPrefixesForObjects = ItemBuilderHelper.getKeyPrefixesForObjects();

    return JSON.serializePretty(result, false);
  }

  public static String GetHistoricalTransactionsForInvoice(String processStr) {
    JSONParser parser = JSON.createParser(processStr);
    Type resultType = Type.forName('InvoiceItemHandler_Transactions.GetHistoricalTransactionsForInvoiceRequest');
    InvoiceItemHandler_Transactions.GetHistoricalTransactionsForInvoiceRequest readValueAsResults = (InvoiceItemHandler_Transactions.GetHistoricalTransactionsForInvoiceRequest)parser.readValueAs(resultType);

    GetHistoricalTransactionsForInvoiceResult result = GetHistoricalTransactionsForInvoice(readValueAsResults);

    return JSON.serializePretty(result, false);
  }

  public static GetHistoricalTransactionsForInvoiceResult GetHistoricalTransactionsForInvoice(GetHistoricalTransactionsForInvoiceRequest request) {
    String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();

    GetHistoricalTransactionsForInvoiceResult result = new GetHistoricalTransactionsForInvoiceResult();

    String invoiceId = request.invoiceId;
    String creditAppliedFields = request.creditAppliedFields;
    String paymentAppliedFields = request.paymentAppliedFields;
    if(!creditAppliedFields.contains('Id')) {
      creditAppliedFields += ','+'Id';
    }
    if(!creditAppliedFields.contains('Date__c')) {
      creditAppliedFields += ','+fxNamespacePrefix+'Date__c';
    }
    if(!creditAppliedFields.contains('Amount__c')) {
      creditAppliedFields += ','+fxNamespacePrefix+'Amount__c';
    }
    if(!paymentAppliedFields.contains('Id')) {
      paymentAppliedFields += ','+'Id';
    }
    if(!paymentAppliedFields.contains('Date__c')) {
      paymentAppliedFields += ','+fxNamespacePrefix+'Payment__r.'+fxNamespacePrefix+'Date__c';
    }
    if(!paymentAppliedFields.contains('Amount__c')) {
      paymentAppliedFields += ','+fxNamespacePrefix+'Amount__c';
    }

    String commandText = 'SELECT ' + creditAppliedFields + ' FROM ' + fxNamespacePrefix + 'Credit_Memo_Applied__c ';
    commandText += ' WHERE IsDeleted=false ';
    commandText += ' AND Invoice__c = :invoiceId ';

    List<Credit_Memo_Applied__c> creditApplieds = Database.query(commandText);

    commandText = 'SELECT ' + paymentAppliedFields + ' FROM ' + fxNamespacePrefix + 'Payment_Applied__c ';
    commandText += ' WHERE IsDeleted=false ';
    commandText += ' AND Invoice__c = :invoiceId ';

    List<Payment_Applied__c> paymentApplieds = Database.query(commandText);

    List<AppliedItem> appliedItems = new List<AppliedItem>();
    for(Credit_Memo_Applied__c creditApplied : creditApplieds) {
      AppliedItem item = new AppliedItem();
      item.Id = creditApplied.Id;
      item.amountApplied = creditApplied.Amount__c;
      item.dateApplied = creditApplied.Date__c;
      item.creditMemoApplied = creditApplied;
      item.type = 'Credit Memo';
      appliedItems.add(item);
    }
    for(Payment_Applied__c paymentApplied : paymentApplieds) {
      AppliedItem item = new AppliedItem();
      item.Id = paymentApplied.Id;
      item.amountApplied = paymentApplied.Amount__c;
      item.dateApplied = paymentApplied.Payment__r.Date__c;
      item.paymentApplied = paymentApplied;
      item.type = 'Payment';
      appliedItems.add(item);
    }

    appliedItems.sort();
    result.appliedItems = appliedItems;

    Set<String> allFieldsSet = new Set<String>();
    List<String> creditAppliedColumnNames = creditAppliedFields.split(',');
    List<String> paymentAppliedColumnNames = paymentAppliedFields.split(',');
    allFieldsSet.addAll(creditAppliedColumnNames);
    allFieldsSet.addAll(paymentAppliedColumnNames);
    List<String> allFields = new List<String>(allFieldsSet);

    for(String field : allFields) {
    System.debug(field);
    }

    allFields.sort();

    result.fields = allFields;

    return result;
  }

  public class GetAppliedCreditSearchFilterResult {
    public List<ItemBuilderHelper.SearchFieldResult> creditMemoSearchFields;
    public Map<String, String> keyPrefixesForObjects;
  }

  public class GetHistoricalTransactionsLayoutResult {
    public List<ItemBuilderHelper.SearchFieldResult> creditMemoAppliedFields;
    public List<ItemBuilderHelper.SearchFieldResult> paymentAppliedFields;
    public Map<String, String> keyPrefixesForObjects;
  }

  public class GetHistoricalTransactionsForInvoiceRequest {
    public String invoiceId;
    public String creditAppliedFields;
    public String paymentAppliedFields;
  }

  public class GetHistoricalTransactionsForInvoiceResult {
    public List<AppliedItem> appliedItems;
    public List<String> fields;
  }

  public class AppliedItem implements Comparable {
    public Id Id;
    public Decimal amountApplied;
    public Date dateApplied;
    public Credit_Memo_Applied__c creditMemoApplied;
    public Payment_Applied__c paymentApplied;
    public String type;

    // Compare opportunities based on the opportunity amount.
    public Integer compareTo(Object compareToObj) {
        String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();

        AppliedItem compareToWrapper = (AppliedItem)compareToObj;

        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (dateApplied > compareToWrapper.dateApplied) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (dateApplied < compareToWrapper.dateApplied) {
            // Set return value to a negative value.
            returnValue = -1;
        }

        return returnValue;
    }
  }

  public class GetCreditMemosForInvoiceRequest {
      public String invoiceId;
      public String showItemsAlreadyOnTheInvoice;
      public String itemLimit;
      public String itemOffset;
      public String sortby;
      public String sortdir;
      public String creditMemoFields;
      public String invoiceItemParentTktItemId;
      public String showItemsAlreadyInvoiced;
      public List<ItemBuilderHelper.SearchFieldRequest> creditMemofilters;
  }

  public class GetCreditMemosForInvoiceResult {
      public List<Credit_Memo__c> selectedCreditMemos;
      public List<Credit_Memo__c> creditMemos;
      public string soql;
  }

  public class CreateInvoiceItemsRequest {
    public Id invId;
    public List<CreditMemoIdAndAmount> sourceItems;
    public Decimal nextSeqNumber;
    public String parentInvItemId;
  }

  public class CreditMemoIdAndAmount {
    public Id Id;
    public Decimal AmountToApply;
  }

}
