@RestResource(urlMapping = '/getQuoteV2Items/*')
global with sharing class QuoteV2ItemsSvc{

    public static String GetQuoteV2Items(String processStr) {
      JSONParser parser = JSON.createParser(processStr);
      Type resultType = Type.forName('QuoteV2ItemsSvc.QuoteV2ItemsSvcRequest');
      QuoteV2ItemsSvc.QuoteV2ItemsSvcRequest readValueAsResult = (QuoteV2ItemsSvc.QuoteV2ItemsSvcRequest)parser.readValueAs(resultType);

      Result resultV1 = searchQuoteItems(readValueAsResult.quoteId, readValueAsResult.ticketId, readValueAsResult.showItemsAlreadyOnTheTicket,
                  readValueAsResult.keyword, readValueAsResult.itemType, readValueAsResult.itemLimit, readValueAsResult.itemOffset,
                  readValueAsResult.sortby, readValueAsResult.sortdir, readValueAsResult.fields);

      QuoteV2ItemsSvcResult quoteItemsSvcResult = new QuoteV2ItemsSvcResult();
      quoteItemsSvcResult.items = resultV1.items;
      quoteItemsSvcResult.soql = resultV1.soql;
      quoteItemsSvcResult.disallowedIds = resultV1.disallowedIds;

      quoteItemsSvcResult.itemPBIds = new Map<Id, Id>();
      String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
      for(Ticket_Item__c ti : [SELECT Id, Price_Book_Item__c, Quote_Item__c FROM Ticket_Item__c WHERE IsDeleted=false AND Price_Book_Item__c!=null AND Ticket__c=:readValueAsResult.ticketId]) {
        quoteItemsSvcResult.itemPBIds.put(ti.Price_Book_Item__c, ti.Id);
      }

      quoteItemsSvcResult.seItemPBIds = new Map<Id, Id>();
      for(Equipment_Planning__c se : [SELECT Id, Price_Book_Item__c FROM Equipment_Planning__c WHERE IsDeleted=false AND Price_Book_Item__c!=null AND Job__c=:readValueAsResult.jobId]) {
        quoteItemsSvcResult.seItemPBIds.put(se.Price_Book_Item__c, se.Id);
      }

System.debug(readValueAsResult.jobId);
      quoteItemsSvcResult.scItemPBIds = new Map<Id, Id>();
      for(Crew_Planning__c sc : [SELECT Id, Role_on_Job__c FROM Crew_Planning__c WHERE IsDeleted=false AND Role_on_Job__c!=null AND Job__c=:readValueAsResult.jobId]) {
        quoteItemsSvcResult.scItemPBIds.put(sc.Role_on_Job__c, sc.Id);
      }
System.debug(quoteItemsSvcResult.scItemPBIds);      

      return JSON.serializePretty(quoteItemsSvcResult, false);
    }

    //
    @HttpGet
    global static Result getQuoteV2Items() {

//jobId, ticketId:ExcludeIfTrue:showItemsAlreadyOnTheTicket, keyword, classification, itemType
//limit, offset, sortby,
//fields

        String quoteId = RestContext.request.params.get('quoteId');
        String ticketId = RestContext.request.params.get('ticketId');
        String showItemsAlreadyOnTheTicket = RestContext.request.params.get('showItemsAlreadyOnTheTicket');
        String keyword = RestContext.request.params.get('keyword');
        String itemType = RestContext.request.params.get('itemType');
        String itemLimit = RestContext.request.params.get('limit');
        String itemOffset = RestContext.request.params.get('offset');
        String sortby = RestContext.request.params.get('sortby');
        String sortdir = RestContext.request.params.get('sortdir');
        String fields = RestContext.request.params.get('fields');

        return searchQuoteItems(quoteId, ticketId, showItemsAlreadyOnTheTicket, keyword,
                    itemType, itemLimit, itemOffset, sortby, sortdir, fields);
    }

    public static Result searchQuoteItems(String quoteId, String ticketId, String showItemsAlreadyOnTheTicket, String keyword,
        String itemType, String itemLimit, String itemOffset, String sortby, String sortdir, String fields) {

        String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();

        Result result = new Result();
        result.disallowedIds = RuleEngineCore.GetDisallowedPriceBookItems(ticketId);

        String commandText = 'SELECT ' + fields + ' FROM ' + fxNamespacePrefix + 'Quote_Item__c ';
        commandText += ' WHERE Id != null ';
        commandText += ' AND ' + fxNamespacePrefix + 'Parent_Quote_Item__c = null ';

        commandText += ' AND ' + fxNamespacePrefix + 'Quote__c =  \'' + quoteId + '\'';

        if (showItemsAlreadyOnTheTicket == 'false') {
            commandText += ' AND ' + fxNamespacePrefix + 'Price_Book_Item__c not in (SELECT ' + fxNamespacePrefix + 'Price_Book_Item__c FROM ' + fxNamespacePrefix + 'Ticket_Item__c WHERE ' + fxNamespacePrefix + 'Ticket__c = \'' + ticketId + '\' ) ';
        }

        if (keyword != null && keyword != '') {
            String keywordSoql = ' AND ( ';
            List<String> keywords = keyword.split(' ');

            keywordSoql += ' ( ';
            for(String str : keywords) {
                keywordSoql += fxNamespacePrefix + 'Description__c LIKE \'%' + str + '%\' AND ';
            }
            keywordSoql = keywordSoql.substring(0,keywordSoql.length()-4);
            keywordSoql += ') OR ';

            keywordSoql += ' ( ';
            for(String str : keywords) {
                keywordSoql += fxNamespacePrefix + 'Item_Code__c LIKE \'%' + str + '%\' AND ';
            }
            keywordSoql = keywordSoql.substring(0,keywordSoql.length()-4);
            keywordSoql += ') ';

            keywordSoql += ' ) ';
            commandText += keywordSoql;
        }

        if (itemType != null && itemType != '') {
            commandText += ' AND RecordType.Name = \'' + itemType + '\' ';
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
        public List<Quote_Item__c> items;
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

    public class QuoteV2ItemsSvcResult {
        public List<Quote_Item__c> items;
        public string soql;
        public List<Id> disallowedIds;
        public Map<Id, Id> itemPBIds;
        public Map<Id, Id> seItemPBIds;
        public Map<Id, Id> scItemPBIds;

    }

    public class QuoteV2ItemsSvcRequest {
        public String quoteId;
        public String ticketId;
        public String jobId;
        public String showItemsAlreadyOnTheTicket;
        public String keyword;
        public String itemType;
        public String itemLimit;
        public String itemOffset;
        public String sortby;
        public String sortdir;
        public String fields;
    }

}
