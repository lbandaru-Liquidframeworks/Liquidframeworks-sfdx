public class CreditMemoItemHandler_Fetch
{
  public static String CreditMemoItemsFetch(String processStr) {
      JSONParser parser = JSON.createParser(processStr);
      Type resultType = null;
      String cmItemId = '';
      String cmId = '';
      String cmFields = '';
      String cmiFields = '';
      CreditMemoItemsFilterResponse filter = null;

      resultType = Type.forName('CreditMemoItemHandler_Fetch.CreditMemoItemsResponseWithFilter');
      CreditMemoItemHandler_Fetch.CreditMemoItemsResponseWithFilter readValueAsResults = (CreditMemoItemHandler_Fetch.CreditMemoItemsResponseWithFilter)parser.readValueAs(resultType);
      cmItemId = readValueAsResults.cmItemId;
      cmId = readValueAsResults.cmId;
      cmFields = readValueAsResults.cmFields;
      cmiFields = readValueAsResults.cmiFields;
      filter = readValueAsResults.filter;

      CreditMemoItemsFetchResult resCreditMemoItemFetch = CreditMemoItemsFetch(cmItemId, cmId, cmFields, cmiFields, filter);
      System.debug(resCreditMemoItemFetch);

      return JSON.serializePretty(resCreditMemoItemFetch, false);
  }

  public static CreditMemoItemsFetchResult CreditMemoItemsFetch(String cmItemId, String cmId, string cmFields, string cmiFields, CreditMemoItemsFilterResponse filter) {
      String ns = UtilityGetNamespace.CurrentNamespace();
      CreditMemoItemsFetchResult creditMemoItemsFetchResult = new CreditMemoItemsFetchResult();

      String cmItemsFilterSoql = GetCreditMemoItemsFilterSoql(filter);

      if (!cmFields.contains('LastModifiedDate')) {
          cmFields += ', LastModifiedDate';
      }

      if (!cmiFields.contains('LastModifiedDate')) {
          cmiFields += ', LastModifiedDate';
      }

      if (!cmiFields.contains('Credit_Memo__c')) {
          cmiFields += ','+ns+'Credit_Memo__c';
      }

      //get cm
      String cmsql = 'SELECT ' + cmFields + ' FROM '+ns+'Credit_Memo__c WHERE Id=\'' + cmId + '\' LIMIT 1';
      Credit_Memo__c cm = database.query(cmsql);

      //get cmItems
      String cmItemssql = 'SELECT ' + cmiFields + ', IsDeleted FROM '+ns+'Credit_Memo_Item__c WHERE IsDeleted=false and '+ns+'Credit_Memo__c=\'' + cmId + '\'';
      cmItemssql += cmItemsFilterSoql;

      List<Credit_Memo_Item__c> cmItems = database.query(cmItemssql);

      //get cmItem
      Credit_Memo_Item__c cmi = null;
      List<Credit_Memo_Item__c> cmItemSiblings = null;
      List<Credit_Memo_Item__c> cmiChildren = null;
      String siblingsql = 'SELECT ' + cmiFields + '' + ' FROM '+ns+'Credit_Memo_Item__c WHERE IsDeleted=false and '+ns+'Parent_Credit_Memo_Item__c = NULL and '+ns+'Credit_Memo__c=\'' + cm.Id + '\' ';

      if (cmItemId != null) {
        String cmisql = 'SELECT ' + cmiFields + '' + ' FROM '+ns+'Credit_Memo_Item__c WHERE Id=\'' + cmItemId + '\'';
        cmi = database.query(cmisql);

        creditMemoItemsFetchResult.cmItem = cmi;

        siblingsql+= ' AND Id!=\'' + cmItemId + '\' ';
      }

      //get cmItem siblings
      siblingsql += cmItemsFilterSoql;
      cmItemSiblings = database.query(siblingsql);

      //get cm children
      String cmiChildrenSql = 'SELECT ' + cmiFields + ' FROM '+ns+'Credit_Memo_Item__c WHERE IsDeleted=false and '+ns+'Parent_Credit_Memo_Item__c != NULL AND '+ns+'Credit_Memo__c=\'' + cm.Id + '\'';
      cmiChildrenSql += cmItemsFilterSoql;
      cmiChildren = database.query(cmiChildrenSql);

      creditMemoItemsFetchResult.creditMemo = cm;
      creditMemoItemsFetchResult.cmItemChildren = cmiChildren;
      creditMemoItemsFetchResult.cmItemSiblings = cmItemSiblings;
      creditMemoItemsFetchResult.cmItems = cmItems;

      return creditMemoItemsFetchResult;
  }

  private static string GetCreditMemoItemsFilterSoql(CreditMemoItemsFilterResponse filter) {
      if (filter == null) return '';

      String ns = UtilityGetNamespace.CurrentNamespace();
      String keyword = filter.keyword;
      String itemType = filter.itemType;
      String itemLimit = filter.itemLimit;
      String itemOffset = filter.itemOffset;
      String sortby = filter.sortby;
      String sortdir = filter.sortdir;

      String cmItemssql = '';

      if (keyword != null && keyword != '') {
          cmItemssql += ' AND (' +  ns + 'Item_Code__c LIKE \'%' + keyword + '%\' OR ' +  ns + 'Description__c LIKE \'%' + keyword + '%\' OR Name LIKE \'%' + keyword + '%\') ';
      }

      String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
      String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
      String nullsLast = (sb != '') ? 'NULLS LAST' : '';
      cmItemssql += sb + ' ' + sd + ' ' + nullsLast;

      String lim = (itemLimit != '' && itemLimit != null ) ? (Integer.valueOf(itemLimit) > 2000) ? '2000' : itemLimit : '2000';
      String off = (itemOffset != '' && itemOffset != null ) ? (Integer.valueOf(itemOffset) > 2000) ? '2000' : itemOffset : '0';
      cmItemssql += ' LIMIT ' + lim + ' OFFSET ' + off + ' ';

      return cmItemssql;
  }

  public class CreditMemoItemsFetchResult {
      public Credit_Memo__c creditMemo;
      public List<Credit_Memo_Item__c> cmItems;
      public Credit_Memo_Item__c cmItem;
      public List<Credit_Memo_Item__c> cmItemSiblings;
      public List<Credit_Memo_Item__c> cmItemChildren;
  }

  public class CreditMemoItemsResponseWithFilter {
      public String cmFields;
      public String cmiFields;
      public String cmId;
      public String cmItemId;
      public CreditMemoItemsFilterResponse filter;
  }

  public class CreditMemoItemsFilterResponse {
      public string keyword;
      public string itemType;
      public string classification;
      public string itemLimit;
      public string itemOffset;
      public string sortby;
      public string sortdir;
  }
}
