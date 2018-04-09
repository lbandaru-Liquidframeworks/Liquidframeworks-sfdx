@RestResource(urlMapping = '/getPricebookItemsForQuote/*')
global with sharing class PricebookItemsForQuoteSvc{

    //
    @HttpGet
    global static Result getPricebookItemsForQuote() {

        String quoteId = RestContext.request.params.get('quoteId');
        String showItemsAlreadyOnTheQuote = RestContext.request.params.get('showItemsAlreadyOnTheQuote');
        String keyword = RestContext.request.params.get('keyword');
        String classification = RestContext.request.params.get('classification');
        String itemType = RestContext.request.params.get('itemType');
        String itemLimit = RestContext.request.params.get('limit');
        String itemOffset = RestContext.request.params.get('offset');
        String sortby = RestContext.request.params.get('sortby');
        String sortdir = RestContext.request.params.get('sortdir');
        String fields = RestContext.request.params.get('fields');

        return searchPricebookItemsForQuote(quoteId, showItemsAlreadyOnTheQuote, keyword, classification,
                    itemType, itemLimit, itemOffset, sortby, sortdir, fields);
    }

    public static Result searchPricebookItemsForQuote(String quoteId, String showItemsAlreadyOnTheQuote, String keyword, String classification,
        String itemType, String itemLimit, String itemOffset, String sortby, String sortdir, String fields) {

        String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();

        Result result = new Result();
        result.disallowedIds = new List<Id>(); // RuleEngineCore.GetDisallowedPriceBookItems(quoteId);

        String commandText = 'SELECT ' + fields + ' FROM ' + fxNamespacePrefix + 'Price_Book_Item__c ';
        commandText += ' WHERE Id != null ';
        commandText += ' AND ' + fxNamespacePrefix + 'IsArchived__c = false ';
        commandText += ' AND ' + fxNamespacePrefix + 'Parent_Price_Book_Item__c = null ';

        commandText += ' AND ' + fxNamespacePrefix + 'Price_Book__c in (SELECT ' + fxNamespacePrefix + 'Price_Book__c from ' + fxNamespacePrefix + 'Quote__c where Id = \'' + quoteId + '\') ';

        if (showItemsAlreadyOnTheQuote == 'false') {
            commandText += ' AND Id not in (SELECT ' + fxNamespacePrefix + 'Price_Book_Item__c FROM ' + fxNamespacePrefix + 'Quote_Item__c WHERE ' + fxNamespacePrefix + 'Quote__c = \'' + quoteId + '\' ) ';
        }

        if (keyword != null && keyword != '') {
          String keywordSoql = ' AND ( ';
          List<String> keywords = keyword.split(' ');

          keywordSoql += ' ( ';
          for(String str : keywords) {
            keywordSoql += 'Name LIKE \'%' + str + '%\' AND ';
          }
          keywordSoql = keywordSoql.substring(0,keywordSoql.length()-4);
          keywordSoql += ') OR ';

          keywordSoql += ' ( ';
          for(String str : keywords) {
            keywordSoql += fxNamespacePrefix + 'Catalog_Description__c LIKE \'%' + str + '%\' AND ';
          }
          keywordSoql = keywordSoql.substring(0,keywordSoql.length()-4);
          keywordSoql += ') OR ';

          keywordSoql += ' ( ';
          for(String str : keywords) {
            keywordSoql += fxNamespacePrefix + 'Description_Override__c LIKE \'%' + str + '%\' AND ';
          }
          keywordSoql = keywordSoql.substring(0,keywordSoql.length()-4);
          keywordSoql += ') OR ';

          keywordSoql += ' ( ';
          for(String str : keywords) {
            keywordSoql += fxNamespacePrefix + 'Catalog_Item_Code__c LIKE \'%' + str + '%\' AND ';
          }
          keywordSoql = keywordSoql.substring(0,keywordSoql.length()-4);
          keywordSoql += ') ';

          keywordSoql += ' ) ';
          commandText += keywordSoql;
        }

        if (classification != null && classification != '') {
            commandText += ' AND Catalog_Classification__c in (' + classification + ') ';
        }

        if (itemType != null && itemType != '') {
            commandText += ' AND ' + fxNamespacePrefix + 'Ticket_Item_Record_Type__c = \'' + itemType + '\' ';
        }

        if (result.disallowedIds.size() > 0) {
            commandText += ' AND Id NOT IN (' + GetIDsAsString(result.disallowedIds) + ')';
        }

        String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
        String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
        String nullsLast = (sb != '') ? 'NULLS LAST' : '';
        commandText += sb + ' ' + sd + ' ' + nullsLast;

        String lim = (itemLimit != '' ) ? (Integer.valueOf(itemLimit) > 2000) ? '2000' : itemLimit : '2000';
        String off = (itemOffset != '' ) ? (Integer.valueOf(itemOffset) > 2000) ? '2000' : itemOffset : '0';
        commandText += ' LIMIT ' + lim + ' OFFSET ' + off + ' ';

        result.soql = commandText;

        result.items = Database.query(commandText);

        return result;
    }

    global class Result {
        public List<Price_Book_Item__c> items;
        public string soql;
        public List<Id> disallowedIds;
    }

    static String GetIDsAsString(List<Id> ids) {
        String sep = '';
        String soql = '';
        for(Id id: ids)
        {
            soql += sep + '\'' + id + '\'';
            sep = ',';
        }

        return soql;
    }

}
