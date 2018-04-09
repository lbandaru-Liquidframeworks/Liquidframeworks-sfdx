@RestResource(urlMapping = '/getQuoteItems/*')
global with sharing class QuoteItemsSvc{

    public static String GetQuoteItems(String processStr) {
      JSONParser parser = JSON.createParser(processStr);
      Type resultType = Type.forName('QuoteItemsSvc.QuoteItemsSvcRequest');
      QuoteItemsSvc.QuoteItemsSvcRequest readValueAsResult = (QuoteItemsSvc.QuoteItemsSvcRequest)parser.readValueAs(resultType);

      Result resultV1 = searchQuoteItems(readValueAsResult.jobId, readValueAsResult.ticketId, readValueAsResult.showItemsAlreadyOnTheTicket,
          readValueAsResult.keyword, readValueAsResult.classification, readValueAsResult.itemType, readValueAsResult.itemLimit,
          readValueAsResult.itemOffset, readValueAsResult.sortby, readValueAsResult.sortdir);

      QuoteItemsSvcResult quoteItemsSvcResult = new QuoteItemsSvcResult();
      quoteItemsSvcResult.items = resultV1.items;
      quoteItemsSvcResult.soql = resultV1.soql;
      quoteItemsSvcResult.disallowedIds = resultV1.disallowedIds;

      quoteItemsSvcResult.itemPBIds = new Map<Id, Id>();
      String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
      for(Ticket_Item__c ti : [SELECT Id, Price_Book_Item__c, Quote_Item__c FROM Ticket_Item__c WHERE IsDeleted=false AND Price_Book_Item__c!=null AND Ticket__c=:readValueAsResult.ticketId]) {
        quoteItemsSvcResult.itemPBIds.put(ti.Price_Book_Item__c, ti.Id);
      }

      return JSON.serializePretty(quoteItemsSvcResult, false);
    }

    //
    @HttpGet
    global static Result getQuoteItems() {

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

        return searchQuoteItems(jobId, ticketId, showItemsAlreadyOnTheTicket, keyword, classification,
            itemType, itemLimit, itemOffset, sortby, sortdir);
    }

    public static Result searchQuoteItems(String jobId, String ticketId, String showItemsAlreadyOnTheTicket, String keyword, String classification,
        String itemType, String itemLimit, String itemOffset, String sortby, String sortdir) {

        String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();

        Result result = new Result();
        result.disallowedIds = RuleEngineCore.GetDisallowedPriceBookItems(ticketId);

        String commandText = 'SELECT Id, Name, ' +  fxNamespacePrefix + 'Catalog_Classification__c, ' +  fxNamespacePrefix + 'Catalog_Record_Type__c, ' +  fxNamespacePrefix + 'Description__c, ' +  fxNamespacePrefix + 'Item_Code__c, ';
        commandText += ' ' +  fxNamespacePrefix + 'PBI_Default_Quantity__c, ' +  fxNamespacePrefix + 'PBI_Included_Quantity__c, ' +  fxNamespacePrefix + 'PBI_Locked_Description__c, ' +  fxNamespacePrefix + 'PBI_Locked_Discount__c, ' +  fxNamespacePrefix + 'PBI_Locked_Price_Markup__c, ' +  fxNamespacePrefix + 'PBI_Maximum_Quantity__c, ';
        commandText += ' ' +  fxNamespacePrefix + 'PBI_Minimum_Charge__c, ' +  fxNamespacePrefix + 'PBI_Minimum_Quantity__c, ' +  fxNamespacePrefix + 'PBI_Pricing_Method__c, ' +  fxNamespacePrefix + 'PBI_Surcharge_Env__c, ' +  fxNamespacePrefix + 'PBI_Surcharge_Fuel__c, ';
        commandText += ' ' +  fxNamespacePrefix + 'Sequence_Number__c, ' +  fxNamespacePrefix + 'Catalog_UOM__c, ' +  fxNamespacePrefix + 'Cost__c, ' +  fxNamespacePrefix + 'Date_Start__c, ' +  fxNamespacePrefix + 'Date_End__c, ';
        commandText += ' ' +  fxNamespacePrefix + 'Price__c, ' +  fxNamespacePrefix + 'On_Standby__c, ' +  fxNamespacePrefix + 'Standby_Price__c, ' +  fxNamespacePrefix + 'Discount_Percent__c,  ';
        commandText += ' ' +  fxNamespacePrefix + 'Surcharge_Rate_Env__c, ' +  fxNamespacePrefix + 'Surcharge_Rate_Fuel__c, ' +  fxNamespacePrefix + 'Price_Book_Item__c, ' +  fxNamespacePrefix + 'PBI_Required_Item__c, ' +  fxNamespacePrefix + 'Contact__c, ' +  fxNamespacePrefix + 'Contact__r.Name, ';
        commandText += ' ' +  fxNamespacePrefix + 'Equipment__c, ' +  fxNamespacePrefix + 'Equipment__r.Name, ' +  fxNamespacePrefix + 'SyncID__c, RecordTypeId, ' +  fxNamespacePrefix + 'Parent_Ticket_Item__c, ';
        commandText += ' ' +  fxNamespacePrefix + 'Input_Qty__c, ';
        commandText += ' RecordType.DeveloperName, RecordType.Name, ';
        commandText += ' ' +  fxNamespacePrefix + 'BreadCrumb__c ';
        commandText += ' FROM ' +  fxNamespacePrefix + 'Ticket_Item__c  ';

        commandText += ' WHERE Id != null ';
        commandText += ' AND ' + fxNamespacePrefix + 'Parent_Ticket_Item__c = null ';

        if(QuoteExtension.HasQuoteV1 == true)
        {
        commandText += ' AND ' +  fxNamespacePrefix + 'Ticket__c in (SELECT ' +  fxNamespacePrefix + 'Quote__c from ' +  fxNamespacePrefix + 'Job__c where Id = \'' + jobId + '\') ';
        }
        if (keyword != null && keyword != '') {
            commandText += ' AND (' +  fxNamespacePrefix + 'Item_Code__c LIKE \'%' + keyword + '%\' OR ' +  fxNamespacePrefix + 'Description__c LIKE \'%' + keyword + '%\' OR Name LIKE \'%' + keyword + '%\') ';
        }

        if (classification != null && classification != '') {
            commandText += ' AND ' +  fxNamespacePrefix + 'Catalog_Classification__c in (' + classification + ') ';
        }

        if (itemType != null && itemType != '') {
            commandText += ' AND RecordType.DeveloperName = \'' + itemType + '\' ';
        }

        if (result.disallowedIds.size() > 0) {
            commandText += ' AND Price_Book_Item__c NOT IN (' + GetIDsAsString(result.disallowedIds) + ')';
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
        public List<Ticket_Item__c> items;
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

    public class QuoteItemsSvcResult {
        public List<Ticket_Item__c> items;
        public string soql;
        public List<Id> disallowedIds;
        public Map<Id, Id> itemPBIds;
        public Map<Id, Id> qtItemOnObjPBIds;
    }

    public class QuoteItemsSvcRequest {
        String jobId;
        String ticketId;
        String showItemsAlreadyOnTheTicket;
        String keyword;
        String classification;
        String itemType;
        String itemLimit;
        String itemOffset;
        String sortby;
        String sortdir;
    }
}
