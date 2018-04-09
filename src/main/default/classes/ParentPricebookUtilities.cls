global with sharing class ParentPricebookUtilities {

    public static List<Price_Book__c> GetParentPricebooks(Id pricebookId) {

        Map<Id, Price_Book__c> pricebooksLookup = new Map<Id, Price_Book__c>([SELECT Id, Parent_Price_Book__c, IsArchived__c, Is_Active__c, Effective_Date__c, Expiration_Date__c, AddTktItemsByPBSeqNum__c
            FROM Price_Book__c WHERE IsDeleted=false AND Is_Active__c=true]);

        List<Price_Book__c> parentPricebooks = new List<Price_Book__c>();

        Id pbId = pricebooksLookup.containsKey(pricebookId)? pricebooksLookup.get(pricebookId).Parent_Price_Book__c : null;

        while(!String.isBlank(pbId) && pricebooksLookup.containsKey(pbId)) {
            Price_Book__c pb = pricebooksLookup.get(pbId);
            parentPricebooks.add(pb);
            pbId = pb.Parent_Price_Book__c;
        }
        return parentPricebooks;
    }

    public static String GetPriceBookItemsFromParentPricebook(String processStr) {
      JSONParser parser = JSON.createParser(processStr);
      Type resultType = Type.forName('ParentPricebookUtilities.GetPriceBookItemsFromParentPricebookRequest');
      ParentPricebookUtilities.GetPriceBookItemsFromParentPricebookRequest readValueAsResult = (ParentPricebookUtilities.GetPriceBookItemsFromParentPricebookRequest)parser.readValueAs(resultType);

      Result resultV1 = ParentPricebookUtilities.GetPricebookItemsFromParentPricebook(readValueAsResult.parentPricebookId, readValueAsResult.objectId,
                  readValueAsResult.showItemsAlreadyOnTheObject, readValueAsResult.keyword, readValueAsResult.classification,
                  readValueAsResult.itemType, readValueAsResult.itemLimit, readValueAsResult.itemOffset, readValueAsResult.sortby,
                  readValueAsResult.sortdir, readValueAsResult.fields, readValueAsResult.sobjectType);

      GetPriceBookItemsFromParentPricebookResult getPriceBookItemsFromParentPricebookResult = new GetPriceBookItemsFromParentPricebookResult();
      getPriceBookItemsFromParentPricebookResult.items = resultV1.items;
      getPriceBookItemsFromParentPricebookResult.soql = resultV1.soql;
      getPriceBookItemsFromParentPricebookResult.parentPricebooks = resultV1.parentPricebooks;

      getPriceBookItemsFromParentPricebookResult.itemPBIds = new Map<Id, Id>();
      getPriceBookItemsFromParentPricebookResult.qtItemOnObjPBIds = new Map<Id, Id>();
      String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
      if (readValueAsResult.sobjectType == fxNamespacePrefix+'Quote__c') {
        for(Quote_Item__c qi : [SELECT Id, Price_Book_Item__c FROM Quote_Item__c WHERE IsDeleted=false AND Price_Book_Item__c!=null AND Quote__c=:readValueAsResult.objectId]) {
          getPriceBookItemsFromParentPricebookResult.itemPBIds.put(qi.Price_Book_Item__c, qi.Id);
        }
      } else {
        for(Ticket_Item__c ti : [SELECT Id, Price_Book_Item__c, Quote_Item__c FROM Ticket_Item__c WHERE IsDeleted=false AND Price_Book_Item__c!=null AND Ticket__c=:readValueAsResult.objectId]) {
          getPriceBookItemsFromParentPricebookResult.itemPBIds.put(ti.Price_Book_Item__c, ti.Id);
          if (ti.Quote_Item__c != null) getPriceBookItemsFromParentPricebookResult.qtItemOnObjPBIds.put(ti.Price_Book_Item__c, ti.Quote_Item__c);
        }

        for(Quote_Item__c qi : [SELECT Id, Price_Book_Item__c FROM Quote_Item__c WHERE IsDeleted=false AND Price_Book_Item__c!=null AND Quote__c=:readValueAsResult.relatedObjectId]) {
          getPriceBookItemsFromParentPricebookResult.qtItemOnObjPBIds.put(qi.Price_Book_Item__c, qi.Id);
        }

      }

      return JSON.serializePretty(getPriceBookItemsFromParentPricebookResult, false);
    }

    public static String GetPriceBookItemsFromParentPricebooks(String processStr) {
      JSONParser parser = JSON.createParser(processStr);
      Type resultType = Type.forName('ParentPricebookUtilities.GetPriceBookItemsFromParentPricebooksRequest');
      ParentPricebookUtilities.GetPriceBookItemsFromParentPricebooksRequest readValueAsResult = (ParentPricebookUtilities.GetPriceBookItemsFromParentPricebooksRequest)parser.readValueAs(resultType);

      Result resultV1 = ParentPricebookUtilities.GetPriceBookItems(readValueAsResult.pricebookId, readValueAsResult.objectId,
                readValueAsResult.showItemsAlreadyOnTheObject, readValueAsResult.keyword, readValueAsResult.classification,
                readValueAsResult.itemType, readValueAsResult.itemLimit, readValueAsResult.itemOffset, readValueAsResult.sortby,
                readValueAsResult.sortdir, readValueAsResult.fields, readValueAsResult.sobjectType);

      GetPriceBookItemsFromParentPricebooksResult getPriceBookItemsFromParentPricebooksResult = new GetPriceBookItemsFromParentPricebooksResult();
      getPriceBookItemsFromParentPricebooksResult.items = resultV1.items;
      getPriceBookItemsFromParentPricebooksResult.soql = resultV1.soql;
      getPriceBookItemsFromParentPricebooksResult.parentPricebooks = resultV1.parentPricebooks;

      getPriceBookItemsFromParentPricebooksResult.itemPBIds = new Map<Id, Id>();
      getPriceBookItemsFromParentPricebooksResult.qtItemOnObjPBIds = new Map<Id, Id>();
      String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
      if (readValueAsResult.sobjectType == fxNamespacePrefix+'Quote__c') {
        for(Quote_Item__c qi : [SELECT Id, Price_Book_Item__c FROM Quote_Item__c WHERE IsDeleted=false AND Price_Book_Item__c!=null AND Quote__c=:readValueAsResult.objectId]) {
          getPriceBookItemsFromParentPricebooksResult.itemPBIds.put(qi.Price_Book_Item__c, qi.Id);
        }
      } else {
        for(Ticket_Item__c ti : [SELECT Id, Price_Book_Item__c, Quote_Item__c FROM Ticket_Item__c WHERE IsDeleted=false AND Price_Book_Item__c!=null AND Ticket__c=:readValueAsResult.objectId]) {
          getPriceBookItemsFromParentPricebooksResult.itemPBIds.put(ti.Price_Book_Item__c, ti.Id);
        }

System.debug(readValueAsResult.relatedObjectId);
        for(Quote_Item__c qi : [SELECT Id, Price_Book_Item__c FROM Quote_Item__c WHERE IsDeleted=false AND Price_Book_Item__c!=null AND Quote__c=:readValueAsResult.relatedObjectId]) {
System.debug(qi);
          getPriceBookItemsFromParentPricebooksResult.qtItemOnObjPBIds.put(qi.Price_Book_Item__c, qi.Id);
        }
      }

      return JSON.serializePretty(getPriceBookItemsFromParentPricebooksResult, false);
    }

    public static Result GetPriceBookItems(
            Id pricebookId,
            String objectId,
            String showItemsAlreadyOnTheObject,
            String keyword,
            String classification,
            String itemType,
            String itemLimit,
            String itemOffset,
            String sortby,
            String sortdir,
            String fields)
    {
        return ParentPricebookUtilities.GetPriceBookItems(pricebookId, objectId, showItemsAlreadyOnTheObject, keyword, classification,
            itemType, itemLimit, itemOffset, sortby, sortdir, fields, null);
    }

    public static Result GetPriceBookItems(
            Id pricebookId,
            String objectId,
            String showItemsAlreadyOnTheObject,
            String keyword,
            String classification,
            String itemType,
            String itemLimit,
            String itemOffset,
            String sortby,
            String sortdir,
            String fields,
            String sobjectType)
    {
        String pbIds = '';

        String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
        Result result = new Result();

        //Datetime now = Datetime.now();
        Price_Book__c pricebook = [SELECT Id, Parent_Price_Book__c FROM Price_Book__c WHERE Id =: pricebookId LIMIT 1 ];

        Set<Id> catalogItemIdsSet = new Set<Id>();
        for(Price_Book_Item__c pbi : [SELECT Id, Catalog_Item__c FROM Price_Book_Item__c WHERE IsDeleted=false AND Price_Book__c =: pricebookId
                                      AND (Parent_Price_Book_Item__c = null OR Requires_Parent_Item__c = false)])
        {
            catalogItemIdsSet.add(pbi.Catalog_Item__c);
        }

        List<Price_Book__c> parentPricebooks = ParentPricebookUtilities.GetParentPricebooks(pricebookId);
        result.parentPricebooks = parentPricebooks;

        if (parentPricebooks.isEmpty()) {
            result.items = new List<Price_Book_Item__c>();
            result.soql = '';
            return result;
        }

        Map<Id, Price_Book__c> parentPricebooksLookup = new Map<Id, Price_Book__c>(parentPricebooks);
        List<Id> parentIds = new List<Id>();
        Map<Id, Integer> parentGeneration = new Map<Id, Integer>();
        Integer generation = 0;
        for (Price_Book__c parent : parentPricebooks) {
            parentIds.add(parent.Id);
            parentGeneration.put(parent.Id, generation);
            generation++;
        }
        pbIds = GetIDsAsString(parentIds);

        Set<Id> ticketCatalogIdsSet = new Set<Id>();
        if (sobjectType == fxNamespacePrefix+'Quote__c') {
            for(Quote_Item__c qi : [SELECT Price_Book_Item__r.Catalog_Item__c FROM Quote_Item__c WHERE IsDeleted=false AND Quote__c =: objectId AND Parent_Quote_Item__c = null])
            {
                ticketCatalogIdsSet.add(qi.Price_Book_Item__r.Catalog_Item__c);
            }
        } else {
            for(Ticket_Item__c ti : [SELECT Catalog_Item__c FROM Ticket_Item__c WHERE IsDeleted=false AND Ticket__c =: objectId AND Parent_Ticket_Item__c = null])
            {
                ticketCatalogIdsSet.add(ti.Catalog_Item__c);
            }
        }

        //make sure Catalog_Item__c, Price_Book__c in fields
        if(!fields.contains('Catalog_Item__c'))
        {
            fields += ','+fxNamespacePrefix+'Catalog_Item__c';
        }
        if(!fields.contains('Price_Book__c'))
        {
            fields += ','+fxNamespacePrefix+'Price_Book__c';
        }

        String commandText = 'SELECT ' + fields + ' FROM {0}Price_Book_Item__c ';
        commandText += ' WHERE IsDeleted=false ';
        commandText += ' AND {0}IsArchived__c = false ';
        commandText += ' AND {0}Parent_Price_Book_Item__c = null ';

        commandText = String.format(commandText, new String[]{fxNamespacePrefix});

        if (!parentIds.isEmpty()) {
            commandText += ' AND '+fxNamespacePrefix+'Price_Book__c in (' + pbIds + ') ';
        }

        if(!catalogItemIdsSet.isEmpty())
        {
          commandText += String.format( ' AND {0}Catalog_Item__r.Id not in :catalogItemIdsSet ', new String[]{fxNamespacePrefix });
        }

        if(!catalogItemIdsSet.isEmpty())
        {
          commandText += String.format( ' AND {0}Catalog_Item__r.Id not in :catalogItemIdsSet ', new String[]{fxNamespacePrefix });
        }

        if (showItemsAlreadyOnTheObject == 'false' && ticketCatalogIdsSet.size() > 0) {
          commandText += String.format( ' AND {0}Catalog_Item__r.Id not in :ticketCatalogIdsSet ', new String[]{fxNamespacePrefix });
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
            commandText += ' AND '+fxNamespacePrefix+'Catalog_Classification__c in (' + classification + ') ';
        }

        if (itemType != null && itemType != '') {
            commandText += String.format(' AND {0}Ticket_Item_Record_Type__c = \'\'' + itemType + '\'\' ', new String[]{fxNamespacePrefix});
        }

        String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
        String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
        String nullsLast = (sb != '') ? 'NULLS LAST' : '';
        commandText += sb + ' ' + sd + ' ' + nullsLast;

        String lim = (itemLimit != '' ) ? (Integer.valueOf(itemLimit) > 2000) ? '2000' : itemLimit : '2000';
        String off = (itemOffset != '' ) ? (Integer.valueOf(itemOffset) > 2000) ? '2000' : itemOffset : '0';
        commandText += ' LIMIT ' + lim + ' OFFSET ' + off + ' ';

        result.soql = commandText;

        List<Price_Book_Item__c> items = Database.query(commandText);

        Map<Id, List<Price_Book_Item__c>> itemsOfInterest = new Map<Id, List<Price_Book_Item__c>>();
        Map<Id, Integer> catalogItemIdFromParent = new Map<Id, Integer>();

        for(Price_Book_Item__c item: items)
        {
          Id catalogItemId = item.Catalog_Item__c;
          Integer level = parentGeneration.get(item.Price_Book__c);

          if(catalogItemIdFromParent.containsKey(catalogItemId))
          {
            Integer prevLevel = catalogItemIdFromParent.get(catalogItemId);
            if(level<prevLevel)
            {
              catalogItemIdFromParent.put(catalogItemId, level); //overwrite old entry
              List<Price_Book_Item__c> itemList = new List<Price_Book_Item__c>();
              itemList.add(item);
              itemsOfInterest.put(catalogItemId, itemList); //overwrite old entry
            } else if (level==prevLevel) {
              if (itemsOfInterest.containsKey(catalogItemId)) {
                List<Price_Book_Item__c> itemList = itemsOfInterest.get(catalogItemId);
                itemList.add(item);
              } else {
                List<Price_Book_Item__c> itemList = new List<Price_Book_Item__c>();
                itemList.add(item);
                itemsOfInterest.put(catalogItemId, itemList);
              }
            }
          } else {
            catalogItemIdFromParent.put(catalogItemId, level);
            List<Price_Book_Item__c> itemList = new List<Price_Book_Item__c>();
            itemList.add(item);
            itemsOfInterest.put(catalogItemId, itemList);
          }
        }

        List<Price_Book_Item__c> allItems = new List<Price_Book_Item__c>();
        for (List<Price_Book_Item__c> itemList: itemsOfInterest.values()) {
          allItems.addAll(itemList);
        }

        result.items = allItems;
        return result;
    }


    public static Result GetPricebookItemsFromParentPricebook(
        String parentPricebookId,
        String objectId,
        String showItemsAlreadyOnTheObject,
        String keyword,
        String classification,
        String itemType,
        String itemLimit,
        String itemOffset,
        String sortby,
        String sortdir,
        String fields)
    {
        return ParentPricebookUtilities.GetPricebookItemsFromParentPricebook(parentPricebookId, objectId, showItemsAlreadyOnTheObject, keyword,
                     classification, itemType, itemLimit, itemOffset, sortby, sortdir, fields, null);
    }

    public static Result GetPricebookItemsFromParentPricebook(
        String parentPricebookId,
        String objectId,
        String showItemsAlreadyOnTheObject,
        String keyword,
        String classification,
        String itemType,
        String itemLimit,
        String itemOffset,
        String sortby,
        String sortdir,
        String fields,
        String sobjectType) {

        String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();

        Result result = new Result();

        Set<Id> ticketCatalogIdsSet = new Set<Id>();
        if (sobjectType == fxNamespacePrefix+'Quote__c') {
            for(Quote_Item__c qi : [SELECT Price_Book_Item__r.Catalog_Item__c FROM Quote_Item__c WHERE IsDeleted=false AND Quote__c =: objectId AND Parent_Quote_Item__c = null])
            {
                ticketCatalogIdsSet.add(qi.Price_Book_Item__r.Catalog_Item__c);
            }
        } else {
            for(Ticket_Item__c ti : [SELECT Catalog_Item__c FROM Ticket_Item__c WHERE IsDeleted=false AND Ticket__c =: objectId AND Parent_Ticket_Item__c = null])
            {
                ticketCatalogIdsSet.add(ti.Catalog_Item__c);
            }
        }

        String commandText = 'SELECT ' + fields + ' FROM {0}Price_Book_Item__c ';
        commandText += ' WHERE Id != null ';
        commandText += ' AND {0}Price_Book__c = \'\'' + parentPricebookId + '\'\' ';
        commandText += ' AND {0}IsArchived__c = false ';
        commandText += ' AND {0}Parent_Price_Book_Item__c = null ';

        commandText = String.format(commandText, new String[]{fxNamespacePrefix});

        if (showItemsAlreadyOnTheObject == 'false' && ticketCatalogIdsSet.size() > 0) {
          commandText += String.format( ' AND {0}Catalog_Item__r.Id not in :ticketCatalogIdsSet ', new String[]{fxNamespacePrefix });
        }

        if (keyword != null && keyword != '') {
          commandText += String.format(' AND ({0}Catalog_Description__c LIKE \'\'%' + keyword + '%\'\' OR {0}Description_Override__c LIKE \'\'%' + keyword + '%\'\' OR {0}Catalog_Item_Code__c LIKE \'\'%' + keyword + '%\'\') ', new String[]{fxNamespacePrefix});
        }

        if (classification != null && classification != '') {
            commandText += ' AND '+fxNamespacePrefix+'Catalog_Classification__c in (' + classification + ') ';
        }

        if (itemType != null && itemType != '') {
            commandText += String.format(' AND {0}Ticket_Item_Record_Type__c = \'\'' + itemType + '\'\' ', new String[]{fxNamespacePrefix});
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

    global class Result {
        public List<Price_Book_Item__c> items;
        public string soql;
        public List<Price_Book__c> parentPricebooks;
    }

    public class GetPriceBookItemsFromParentPricebooksResult {
        public List<Price_Book_Item__c> items;
        public string soql;
        public List<Price_Book__c> parentPricebooks;
        public Map<Id, Id> itemPBIds;
        public Map<Id, Id> qtItemOnObjPBIds;
    }

    public class GetPriceBookItemsFromParentPricebooksRequest {
        public Id pricebookId;
        public String objectId;
        public String relatedObjectId;
        public String showItemsAlreadyOnTheObject;
        public String keyword;
        public String classification;
        public String itemType;
        public String itemLimit;
        public String itemOffset;
        public String sortby;
        public String sortdir;
        public String fields;
        public String sobjectType;
    }

    public class GetPriceBookItemsFromParentPricebookResult {
        public List<Price_Book_Item__c> items;
        public string soql;
        public List<Price_Book__c> parentPricebooks;
        public Map<Id, Id> itemPBIds;
        public Map<Id, Id> qtItemOnObjPBIds;
    }

    public class GetPriceBookItemsFromParentPricebookRequest {
        public String parentPricebookId;
        public String objectId;
        public String relatedObjectId;
        public String showItemsAlreadyOnTheObject;
        public String keyword;
        public String classification;
        public String itemType;
        public String itemLimit;
        public String itemOffset;
        public String sortby;
        public String sortdir;
        public String fields;
        public String sobjectType;
    }

}
