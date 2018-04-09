public class TicketItemsFetch {
    public static String Process(String processStr) {
        JSONParser parser = JSON.createParser(processStr);
        Type resultType = null;
        String tktItemId = '';
        String tktId = '';
        String tktFields = '';
        String tktItemFields = '';
        TktItemsFilterResponse filter = null;

        if (processStr.contains('"filter"')) {
          resultType = Type.forName('TicketItemsFetch.TktItemsResponseWithFilter');
          TicketItemsFetch.TktItemsResponseWithFilter readValueAsResults1 = (TicketItemsFetch.TktItemsResponseWithFilter)parser.readValueAs(resultType);
          tktItemId = readValueAsResults1.tktItemId;
          tktId = readValueAsResults1.tktId;
          tktFields = readValueAsResults1.tktFields;
          tktItemFields = readValueAsResults1.tktItemFields;
          filter = readValueAsResults1.filter;
        } else {
          resultType = Type.forName('TicketItemsFetch.TktItemsResponse');
          TicketItemsFetch.TktItemsResponse readValueAsResults2 = (TicketItemsFetch.TktItemsResponse)parser.readValueAs(resultType);
          tktItemId = readValueAsResults2.tktItemId;
          tktId = readValueAsResults2.tktId;
          tktFields = readValueAsResults2.tktFields;
          tktItemFields = readValueAsResults2.tktItemFields;
        }

        TicketItemsFetchResult resTicketItemFetch = TicketItemsFetch(tktItemId, tktId, tktFields, tktItemFields, filter);
        System.debug(resTicketItemFetch);

        return JSON.serializePretty(resTicketItemFetch, false);
    }

public static string GetFilterSoql(TktItemsFilterResponse filter) {
  if (filter == null) return '';

  String ns = UtilityGetNamespace.CurrentNamespace();
  String keyword = filter.keyword;
  String itemType = filter.itemType;
  String classification = filter.classification;
  String itemLimit = filter.itemLimit;
  String itemOffset = filter.itemOffset;
  String sortby = filter.sortby;
  String sortdir = filter.sortdir;

  String tktItemssql = '';

  if (keyword != null && keyword != '') {
      tktItemssql += ' AND (' +  ns + 'Item_Code__c LIKE \'%' + keyword + '%\' OR ' +  ns + 'Description__c LIKE \'%' + keyword + '%\' OR Name LIKE \'%' + keyword + '%\') ';
  }

  if (classification != null && classification != '') {
      tktItemssql += ' AND ' +  ns + 'Catalog_Classification__c in (' + classification + ') ';
  }

  if (itemType != null && itemType != '') {
      tktItemssql += ' AND RecordType.DeveloperName = \'' + itemType + '\' ';
  }

  String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
  String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
  String nullsLast = (sb != '') ? 'NULLS LAST' : '';
  tktItemssql += sb + ' ' + sd + ' ' + nullsLast;

  String lim = (itemLimit != '' && itemLimit != null ) ? (Integer.valueOf(itemLimit) > 2000) ? '2000' : itemLimit : '2000';
  String off = (itemOffset != '' && itemOffset != null ) ? (Integer.valueOf(itemOffset) > 2000) ? '2000' : itemOffset : '0';
  tktItemssql += ' LIMIT ' + lim + ' OFFSET ' + off + ' ';

  return tktItemssql;
}

public static TicketItemsFetchResult TicketItemsFetch(String tktItemId, String tktId, string tktFields, string tktItemFields, TktItemsFilterResponse filter) {
        String ns = UtilityGetNamespace.CurrentNamespace();
        TicketItemsFetchResult ticketItemsFetchResult = new TicketItemsFetchResult();

        if (!tktFields.contains('LastModifiedDate')) {
            tktFields += ', LastModifiedDate';
        }

        if (!tktItemFields.contains('LastModifiedDate')) {
            tktItemFields += ', LastModifiedDate';
        }

        if (!tktItemFields.contains('Ticket__c')) {
            tktItemFields += ', '+ns+'Ticket__c';
        }

        //get tkt
        String tktsql = 'SELECT ' + tktFields + ' FROM '+ns+'Ticket__c WHERE Id=\'' + tktId + '\' LIMIT 1';
        System.debug(tktsql);
        Ticket__c t = database.query(tktsql);

        //get tktItems
        String tktItemssql = 'SELECT ' + tktItemFields + ', IsDeleted FROM '+ns+'Ticket_Item__c WHERE IsDeleted=false and '+ns+'Ticket__c=\'' + tktId + '\'';
        tktItemssql += GetFilterSoql(filter);

        System.debug(tktItemssql);
        List<Ticket_Item__c> tktItems = database.query(tktItemssql);
System.debug(tktItems);
System.debug(t);

        //get tktItem
        Ticket_Item__c ti = null;
        List<Ticket_Item__c> tktItemSiblings = null;
        List<Ticket_Item__c> tiChildren = null;
        String siblingsql = 'SELECT ' + tktItemFields + ' FROM '+ns+'Ticket_Item__c WHERE IsDeleted=false and '+ns+'Parent_Ticket_Item__c = NULL and '+ns+'Ticket__c=\'' + t.Id + '\' ';

        if (tktItemId != null) {
          String tisql = 'SELECT ' + tktItemFields + ' FROM '+ns+'Ticket_Item__c WHERE Id=\'' + tktItemId
           + '\'';
          System.debug(tisql);
          ti = database.query(tisql);
          ticketItemsFetchResult.tktItem = ti;

          siblingsql+= ' AND Id!=\'' + tktItemId + '\' ';
        }

        //get tktItem siblings
        siblingsql += GetFilterSoql(filter);
        System.debug(siblingsql);
        tktItemSiblings = database.query(siblingsql);

        //get tkt children
        String tiChildrenSql = 'SELECT ' + tktItemFields + ' FROM '+ns+'Ticket_Item__c WHERE IsDeleted=false and '+ns+'Parent_Ticket_Item__c != NULL AND '+ns+'Ticket__c=\'' + t.Id + '\'';

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

        System.debug(tiChildrenSql);
        tiChildren = database.query(tiChildrenSql);

        ticketItemsFetchResult.ticket = t;
        ticketItemsFetchResult.tktItemChildren = tiChildren;
        ticketItemsFetchResult.tktItemSiblings = tktItemSiblings;
        ticketItemsFetchResult.tktItems = tktItems;

        return ticketItemsFetchResult;
    }

    public class TicketItemsFetchResult {
        public Ticket__c ticket;
        public List<Ticket_Item__c> tktItems;
        public Ticket_Item__c tktItem;
        public List<Ticket_Item__c> tktItemSiblings;
        public List<Ticket_Item__c> tktItemChildren;
    }

    public class TktItemsResponse {
        public String tktFields;
        public String tktItemFields;
        public String tktId;
        public String tktItemId;
    }

    public class TktItemsResponseWithFilter {
        public String tktFields;
        public String tktItemFields;
        public String tktId;
        public String tktItemId;
        public TktItemsFilterResponse filter;
    }

    public class TktItemsFilterResponse {
        public string keyword;
        public string itemType;
        public string classification;
        public string itemLimit;
        public string itemOffset;
        public string sortby;
        public string sortdir;
    }

}
