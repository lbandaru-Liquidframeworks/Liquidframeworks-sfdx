public class QuoteItemsFetch {
    public static String Process(String processStr) {
    JSONParser parser = JSON.createParser(processStr);
    Type resultType = null;
    String qtItemId = '';
    String qtId = '';
    String qtFields = '';
    String qtItemFields = '';
    QtItemsFilterResponse filter = null;

    if (processStr.contains('"filter"')) {
      resultType = Type.forName('QuoteItemsFetch.QtItemsResponseWithFilter');
      QuoteItemsFetch.QtItemsResponseWithFilter readValueAsResults1 = (QuoteItemsFetch.QtItemsResponseWithFilter)parser.readValueAs(resultType);
      qtItemId = readValueAsResults1.qtItemId;
      qtId = readValueAsResults1.qtId;
      qtFields = readValueAsResults1.qtFields;
      qtItemFields = readValueAsResults1.qtItemFields;
      filter = readValueAsResults1.filter;
    } else {
      resultType = Type.forName('QuoteItemsFetch.QtItemsResponse');
      QuoteItemsFetch.QtItemsResponse readValueAsResults2 = (QuoteItemsFetch.QtItemsResponse)parser.readValueAs(resultType);
      qtItemId = readValueAsResults2.qtItemId;
      qtId = readValueAsResults2.qtId;
      qtFields = readValueAsResults2.qtFields;
      qtItemFields = readValueAsResults2.qtItemFields;
    }

    QuoteItemsFetchResult resQuoteItemFetch = QuoteItemsFetch(qtItemId, qtId, qtFields, qtItemFields, filter);
    System.debug(resQuoteItemFetch);

    return JSON.serializePretty(resQuoteItemFetch, false);
}

public static string GetFilterSoql(QtItemsFilterResponse filter) {
  if (filter == null) return '';

  String ns = UtilityGetNamespace.CurrentNamespace();
  String keyword = filter.keyword;
  String itemType = filter.itemType;
  String classification = filter.classification;
  String itemLimit = filter.itemLimit;
  String itemOffset = filter.itemOffset;
  String sortby = filter.sortby;
  String sortdir = filter.sortdir;

  String soql = '';

  if (keyword != null && keyword != '') {
      soql += ' AND (' +  ns + 'Item_Code__c LIKE \'%' + keyword + '%\' OR ' +  ns + 'Description__c LIKE \'%' + keyword + '%\' OR Name LIKE \'%' + keyword + '%\') ';
  }

  if (classification != null && classification != '') {
      soql += ' AND ' +  ns + 'Catalog_Classification__c in (' + classification + ') ';
  }

  if (itemType != null && itemType != '') {
      soql += ' AND RecordType.DeveloperName = \'' + itemType + '\' ';
  }

  String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
  String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
  String nullsLast = (sb != '') ? 'NULLS LAST' : '';
  soql += sb + ' ' + sd + ' ' + nullsLast;

  String lim = (itemLimit != '' && itemLimit != null ) ? (Integer.valueOf(itemLimit) > 2000) ? '2000' : itemLimit : '2000';
  String off = (itemOffset != '' && itemOffset != null ) ? (Integer.valueOf(itemOffset) > 2000) ? '2000' : itemOffset : '0';
  soql += ' LIMIT ' + lim + ' OFFSET ' + off + ' ';

  return soql;
}

public static QuoteItemsFetchResult QuoteItemsFetch(String qtItemId, String qtId, string qtFields, string qtItemFields, QtItemsFilterResponse filter) {
        String ns = UtilityGetNamespace.CurrentNamespace();
        QuoteItemsFetchResult quoteItemsFetchResult = new QuoteItemsFetchResult();

        if (!qtFields.contains('LastModifiedDate')) {
            qtFields += ', LastModifiedDate';
        }

        if (!qtItemFields.contains('LastModifiedDate')) {
            qtItemFields += ', LastModifiedDate';
        }

        //get qt
        String qtsql = 'SELECT ' + qtFields + ' FROM '+ns+'Quote__c WHERE Id=\'' + qtId + '\' LIMIT 1';
        System.debug(qtsql);
        Quote__c t = database.query(qtsql);

        //get qtItems
        String qtItemssql = 'SELECT ' + qtItemFields + ', Quote__c, IsDeleted FROM '+ns+'Quote_Item__c WHERE IsDeleted=false and '+ns+'Quote__c=\'' + qtId + '\'';
        qtItemssql += GetFilterSoql(filter);

        System.debug(qtItemssql);
        List<Quote_Item__c> qtItems = database.query(qtItemssql);
System.debug(qtItems);
System.debug(t);

        //get qtItem
        Quote_Item__c ti = null;
        List<Quote_Item__c> qtItemSiblings = null;
        List<Quote_Item__c> tiChildren = null;
        String siblingsql = 'SELECT ' + qtItemFields + ', Quote__c' + ' FROM '+ns+'Quote_Item__c WHERE IsDeleted=false and '+ns+'Parent_Quote_Item__c = NULL and '+ns+'Quote__c=\'' + t.Id + '\' ';

        if (qtItemId != null) {
            String tisql = 'SELECT ' + qtItemFields + ', Quote__c' + ' FROM '+ns+'Quote_Item__c WHERE Id=\'' + qtItemId
             + '\'';
            System.debug(tisql);
            ti = database.query(tisql);
            quoteItemsFetchResult.qtItem = ti;

            siblingsql+= ' AND Id!=\'' + qtItemId + '\' ';
        }

        //get qtItem siblings
        siblingsql += GetFilterSoql(filter);
        System.debug(siblingsql);
        qtItemSiblings = database.query(siblingsql);

        //get qt children
        String tiChildrenSql = 'SELECT ' + qtItemFields + ' FROM '+ns+'Quote_Item__c WHERE IsDeleted=false and '+ns+'Parent_Quote_Item__c != NULL AND '+ns+'Quote__c=\'' + t.Id + '\'';

        if (filter != null) {
          String itemLimit = filter.itemLimit;
          String itemOffset = filter.itemOffset;
          String sortby = filter.sortby;
          String sortdir = filter.sortdir;

          String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
          String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
          String nullsLast = (sb != '') ? 'NULLS LAST' : '';
          tiChildrenSql += sb + ' ' + sd + ' ' + nullsLast;

          String lim = (itemLimit != '' && itemLimit != null ) ? (Integer.valueOf(itemLimit) > 2000) ? '2000' : itemLimit : '2000';
          String off = (itemOffset != '' && itemOffset != null ) ? (Integer.valueOf(itemOffset) > 2000) ? '2000' : itemOffset : '0';
          tiChildrenSql += ' LIMIT ' + lim + ' OFFSET ' + off + ' ';
        }

        System.debug(qtsql);
        tiChildren = database.query(tiChildrenSql);

        quoteItemsFetchResult.quote = t;
        quoteItemsFetchResult.qtItemChildren = tiChildren;
        quoteItemsFetchResult.qtItemSiblings = qtItemSiblings;
        quoteItemsFetchResult.qtItems = qtItems;

        return quoteItemsFetchResult;
    }

    public class QuoteItemsFetchResult {
        public Quote__c quote;
        public List<Quote_Item__c> qtItems;
        public Quote_Item__c qtItem;
        public List<Quote_Item__c> qtItemSiblings;
        public List<Quote_Item__c> qtItemChildren;
    }

    public class QtItemsResponse {
        public String qtFields;
        public String qtItemFields;
        public String qtId;
        public String qtItemId;
    }

    public class QtItemsResponseWithFilter {
        public String qtFields;
        public String qtItemFields;
        public String qtId;
        public String qtItemId;
        public QtItemsFilterResponse filter;
    }

    public class QtItemsFilterResponse {
        public string keyword;
        public string itemType;
        public string classification;
        public string itemLimit;
        public string itemOffset;
        public string sortby;
        public string sortdir;
    }

}
