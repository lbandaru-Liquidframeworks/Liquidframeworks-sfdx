@RestResource(urlMapping = '/getPricebookItems/*')
global with sharing class PricebookItemsSvc{

    //
    @HttpGet
    global static Result getPricebookItems() {
        String jobId = RestContext.request.params.get('jobId');
        String ticketId = RestContext.request.params.get('ticketId');
        String showItemsAlreadyOnTheTicket = RestContext.request.params.get('showItemsAlreadyOnTheTicket');
        String keyword = RestContext.request.params.get('keyword');
        String classification = RestContext.request.params.get('classification');
        String itemType = RestContext.request.params.get('itemType');
        String itemLimit = RestContext.request.params.get('limit');
        String itemOffset = RestContext.request.params.get('offset');
        String sortby = RestContext.request.params.get('sortby');
        String sortdir = RestContext.request.params.get('sortdir');
        String fields = RestContext.request.params.get('fields');

        return searchPricebookItems(jobId, ticketId, showItemsAlreadyOnTheTicket, keyword, classification,
                    itemType, itemLimit, itemOffset, sortby, sortdir, fields);
    }

    public static String SearchPricebookItems(String processStr) {
      JSONParser parser = JSON.createParser(processStr);
      Type resultType = Type.forName('PricebookItemsSvc.SearchPricebookItemsRequest');
      PricebookItemsSvc.SearchPricebookItemsRequest readValueAsResult = (PricebookItemsSvc.SearchPricebookItemsRequest)parser.readValueAs(resultType);

      Result resultV1 = searchPricebookItems(readValueAsResult.jobId, readValueAsResult.ticketId, readValueAsResult.showItemsAlreadyOnTheTicket,
                  readValueAsResult.keyword, readValueAsResult.classification, readValueAsResult.itemType, readValueAsResult.itemLimit,
                  readValueAsResult.itemOffset, readValueAsResult.sortby, readValueAsResult.sortdir, readValueAsResult.fields);

      SearchPricebookItemsResult searchPricebookItemsResult = new SearchPricebookItemsResult();
      searchPricebookItemsResult.items = resultV1.items;
      searchPricebookItemsResult.soql = resultV1.soql;
      searchPricebookItemsResult.disallowedIds = resultV1.disallowedIds;

      searchPricebookItemsResult.itemPBIds = new Map<Id, Id>();
      for(Ticket_Item__c ti : [SELECT Id, Price_Book_Item__c, Quote_Item__c FROM Ticket_Item__c WHERE IsDeleted=false AND Price_Book_Item__c!=null AND Ticket__c=:readValueAsResult.ticketId]) {
        searchPricebookItemsResult.itemPBIds.put(ti.Price_Book_Item__c, ti.Id);
      }

      searchPricebookItemsResult.qtItemOnObjPBIds = new Map<Id, Id>();
      for(Quote_Item__c qi : [SELECT Id, Price_Book_Item__c FROM Quote_Item__c WHERE IsDeleted=false AND Price_Book_Item__c!=null AND Quote__c=:readValueAsResult.quoteId]) {
        searchPricebookItemsResult.qtItemOnObjPBIds.put(qi.Price_Book_Item__c, qi.Id);
      }

      return JSON.serializePretty(searchPricebookItemsResult, false);
    }

    public static Result searchPricebookItems(String jobId, String ticketId, String showItemsAlreadyOnTheTicket, String keyword, String classification,
        String itemType, String itemLimit, String itemOffset, String sortby, String sortdir, String fields) {

        String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();

        Result result = new Result();
        result.disallowedIds = RuleEngineCore.GetDisallowedPriceBookItems(ticketId);

        String commandText = 'SELECT ' + fields + ' FROM ' + fxNamespacePrefix + 'Price_Book_Item__c ';
        commandText += ' WHERE Id != null ';
        commandText += ' AND ' + fxNamespacePrefix + 'IsArchived__c = false ';
        commandText += ' AND ' + fxNamespacePrefix + 'Parent_Price_Book_Item__c = null ';

        commandText += ' AND ' + fxNamespacePrefix + 'Price_Book__c in (SELECT ' + fxNamespacePrefix + 'Price_Book__c from ' + fxNamespacePrefix + 'Job__c where Id = \'' + jobId + '\') ';

        if (showItemsAlreadyOnTheTicket == 'false') {
            commandText += ' AND Id not in (SELECT ' + fxNamespacePrefix + 'Price_Book_Item__c FROM ' + fxNamespacePrefix + 'Ticket_Item__c WHERE ' + fxNamespacePrefix + 'Ticket__c = \'' + ticketId + '\' ) ';
        }

        if (keyword != null && keyword != '') {
          String keywordSoql = ' AND ( ';
          List<String> keywords = keyword.split(' ');

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
            commandText += ' AND ' + fxNamespacePrefix + 'Catalog_Classification__c in (' + classification + ') ';
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

    public class SearchPricebookItemsResult {
        public List<Price_Book_Item__c> items;
        public string soql;
        public List<Id> disallowedIds;
        public Map<Id, Id> itemPBIds;
        public Map<Id, Id> qtItemOnObjPBIds;
    }

    public class SearchPricebookItemsRequest {
        public String jobId;
        public String ticketId;
        public String quoteId;
        public String showItemsAlreadyOnTheTicket;
        public String keyword;
        public String classification;
        public String itemType;
        public String itemLimit;
        public String itemOffset;
        public String sortby;
        public String sortdir;
        public String fields;
    }
}
