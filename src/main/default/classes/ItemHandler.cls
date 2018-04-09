public class ItemHandler
{
  public static String CreateItemUsingExactMatch(String processStr) {
    JSONParser parser = JSON.createParser(processStr);
    Type resultType = Type.forName('ItemHandler.CreateItemUsingExactMatchRequest');
    ItemHandler.CreateItemUsingExactMatchRequest readValueAsResults = (ItemHandler.CreateItemUsingExactMatchRequest)parser.readValueAs(resultType);

    CreateItemUsingExactMatchResult result = CreateItemUsingExactMatch(readValueAsResults);

    return JSON.serializePretty(result, false);
  }

  private static string GetTicketItemsFilterSoql(SiblingFilter siblingFilter) {
    TicketItemsFetch.TktItemsFilterResponse tktItemFilter = new TicketItemsFetch.TktItemsFilterResponse();

    tktItemFilter.keyword = siblingFilter.keyword;
    tktItemFilter.itemType = siblingFilter.itemType;
    tktItemFilter.classification = siblingFilter.classification;
    tktItemFilter.itemLimit = siblingFilter.itemLimit;
    tktItemFilter.itemOffset = siblingFilter.itemOffset;
    tktItemFilter.sortby = siblingFilter.sortby;
    tktItemFilter.sortdir = siblingFilter.sortdir;

    return TicketItemsFetch.GetFilterSoql(tktItemFilter);
  }

  private static string GetQuoteItemsFilterSoql(SiblingFilter siblingFilter) {
    QuoteItemsFetch.QtItemsFilterResponse qtItemFilter = new QuoteItemsFetch.QtItemsFilterResponse();

    qtItemFilter.keyword = siblingFilter.keyword;
    qtItemFilter.itemType = siblingFilter.itemType;
    qtItemFilter.classification = siblingFilter.classification;
    qtItemFilter.itemLimit = siblingFilter.itemLimit;
    qtItemFilter.itemOffset = siblingFilter.itemOffset;
    qtItemFilter.sortby = siblingFilter.sortby;
    qtItemFilter.sortdir = siblingFilter.sortdir;

    return QuoteItemsFetch.GetFilterSoql(qtItemFilter);
  }

  public static CreateItemUsingExactMatchResult CreateItemUsingExactMatch(CreateItemUsingExactMatchRequest request) {
    String pricebookId = request.pricebookId;
    String fieldPbi = request.fieldPbi;
    String fieldEq = request.fieldEq;
    String fieldValue = request.fieldValue;
    Decimal nextSeqNumber = request.nextSeqNumber;
    String objType = request.objType;
    String picklistFields = request.picklistFields;

    if (!picklistFields.contains('LastModifiedDate')) {
        picklistFields += ', LastModifiedDate';
    }

    String ns = StringUtility.FXNamespace();

    List<Price_Book_Item__c> sourcePBIs = new List<Price_Book_Item__c>();
    CreateItemUsingExactMatchResult result = new CreateItemUsingExactMatchResult();
    result.errorMessage = '';
    result.error = false;

    List<Price_Book_Item__c> pbis = new List<Price_Book_Item__c>();
    List<Equipment__c> eqs = new List<Equipment__c>();

    if (fieldPbi!='') {
      String pbiSoql = 'SELECT Id, Requires_Parent_Item__c, Parent_Price_Book_Item__c FROM '+ns+'Price_Book_Item__c WHERE isDeleted=false AND Price_Book__c=:pricebookId AND ' +fieldPbi+ ' = ' + '\'' +fieldValue+'\' LIMIT 2';
      pbis = (List<Price_Book_Item__c>)Database.query(pbiSoql);
    }

    if(pbis.IsEmpty()) {
      if (fieldEq!='') {
        String eqSoql = 'SELECT Id, Catalog_Item__c FROM '+ns+'Equipment__c WHERE isDeleted=false AND ' +fieldEq+ ' = ' + '\'' +fieldValue+'\' LIMIT 2';
        eqs = (List<Equipment__c>)Database.query(eqSoql);

        if(eqs.IsEmpty()) {
          if (fieldPbi!='') {
            result.errorMessage = 'Item not found: [Price_Book_Item__c.'+fieldPbi+']: '+fieldValue+', [Equipment__c.'+fieldEq+']: '+fieldValue;
            result.error = true;
          } else {
            result.errorMessage = 'Item not found: [Equipment__c.'+fieldEq+']: '+fieldValue;
            result.error = true;
          }
        } else if(eqs.size()>1) {
          result.errorMessage = 'Too many Equipment items found: [Equipment__c.'+fieldEq+']: '+fieldValue;
          result.error = true;
        } else {
          System.debug(eqs);
          System.debug(eqs.size());

          if (eqs[0].Catalog_Item__c==null) {
            result.errorMessage = 'Item found: [Equipment__c.'+fieldEq+']: '+fieldValue+'. Catalog_Item__c not set.';
            result.error = true;
          } else {
            List<Catalog_Item__c> catalogItem = [SELECT Name FROM Catalog_Item__c WHERE Id=:eqs[0].Catalog_Item__c LIMIT 1];

            List<Price_Book_item__c> eqpbis = [SELECT Id FROM Price_Book_item__c WHERE IsDeleted=false AND Price_Book__c=:pricebookId AND Catalog_Item__c=:eqs[0].Catalog_Item__c LIMIT 1];

            if (eqpbis.isEmpty()) {
              result.errorMessage = 'Item found: [Equipment__c.'+fieldEq+']: '+fieldValue+'. Catalog_Item__c not valid for this Job\'s Pricebook: ['+eqs[0].Catalog_Item__c+' - '+catalogItem[0].Name+']';
              result.error = true;
            } else if (eqpbis.size()>1) {
              result.errorMessage = 'Item found: [Equipment__c.'+fieldEq+']: '+fieldValue+'. Too many matching Catalog_Item__c in this Job\'s Pricebook: ['+eqs[0].Catalog_Item__c+' - '+catalogItem[0].Name+']';
              result.error = true;
            } else {
              sourcePBIs.add(eqpbis[0]);

              for(Price_Book_item__c pbiChild : [SELECT Id, Parent_Price_Book_Item__c FROM Price_Book_item__c WHERE IsDeleted=false AND Parent_Price_Book_Item__c=:eqpbis[0].Id]) {
                sourcePBIs.add(pbiChild);
              }

              if (objType == 'Ticket_Item__c') {
                result = CreateNewTktItems(request, sourcePBIs, nextSeqNumber, eqs[0].Id);
              } else if (objType == 'Quote_Item__c') {
                result = CreateNewQtItems(request, sourcePBIs, nextSeqNumber, eqs[0].Id);
              }
            }
          }
        }
      } else {
        result.errorMessage = 'Item not found: [Price_Book_Item__c.'+fieldPbi+']: '+fieldValue;
        result.error = true;
      }
    } else if(pbis.size()>1) {
      result.errorMessage = 'Too many Price Book Items found: [Price_Book_Item__c.'+fieldPbi+']: '+fieldValue;
      result.error = true;
    } else {
      Price_Book_Item__c pbi = pbis[0];
      if (pbi.Requires_Parent_Item__c || pbi.Parent_Price_Book_Item__c != null) {
        result.errorMessage = 'Price Book Item is configured as a child item: [Price_Book_Item__c.'+fieldPbi+']: '+fieldValue;
        result.error = true;
      }
      else {
        sourcePBIs.add(pbi);

        for(Price_Book_item__c pbiChild : [SELECT Id, Parent_Price_Book_Item__c FROM Price_Book_item__c WHERE IsDeleted=false AND Parent_Price_Book_Item__c=:pbi.Id]) {
          sourcePBIs.add(pbiChild);
        }

        System.debug(sourcePBIs);

        if (objType == 'Ticket_Item__c') {
          result = CreateNewTktItems(request, sourcePBIs, nextSeqNumber, null);
        } else if (objType == 'Quote_Item__c') {
          result = CreateNewQtItems(request, sourcePBIs, nextSeqNumber, null);
        }
      }
    }

    return result;
  }

  public static CreateItemUsingExactMatchResult CreateNewTktItems(CreateItemUsingExactMatchRequest request, List<Price_Book_Item__c> sourcePBIs, Decimal nextSeqNumber, Id eqId) {
    String ns = StringUtility.FXNamespace();

    String ticketId = request.tktId;
    String parentFields = request.parentFields;
    String siblingFields = request.siblingFields;
    if (!parentFields.contains('LastModifiedDate')) {
        parentFields += ', LastModifiedDate';
    }
    if (!siblingFields.contains('LastModifiedDate')) {
        siblingFields += ', LastModifiedDate';
    }

    CreateItemUsingExactMatchResult result = new CreateItemUsingExactMatchResult();
    result.errorMessage = '';
    result.error = false;

    List<Id> sourceIds = new List<Id>();
    sourceIds.add(sourcePBIs[0].Id);
    List<sObject> newItems = (List<sObject>) TicketItemHandler.CreateTicketItems(ticketId, sourceIds, nextSeqNumber, null);
    List<Ticket_Item__c> newTktItems = [SELECT Id, Equipment__c FROM Ticket_Item__c WHERE Id=:newItems[0].Id];

    if (eqId != null) {
      newTktItems[0].Equipment__c = eqId;
      Database.update(newTktItems);
    }

    newTktItems = [SELECT Id, Equipment__c FROM Ticket_Item__c WHERE Id=:newItems[0].Id];
    result.newItems = newTktItems;

    sourceIds = new List<Id>();
    for(Price_Book_Item__c pbi : sourcePBIs) {
      if (pbi.Parent_Price_Book_Item__c!=null) {
        sourceIds.add(pbi.Id);
      }
    }

    if (sourceIds.size()>0) {
      newItems = (List<sObject>) TicketItemHandler.CreateTicketItems(ticketId, sourceIds, nextSeqNumber, newTktItems[0].Id);
      newTktItems = [SELECT Id, Equipment__c FROM Ticket_Item__c WHERE Id in :newItems];
      result.newItems.addAll((List<SObject>)newTktItems);
    }

    String siblingFilterSoql = GetTicketItemsFilterSoql(request.siblingFilter);

    String soql = String.format('SELECT {0} FROM {1} WHERE IsDeleted=false AND Parent_Ticket_Item__c = NULL AND Ticket__c=:ticketId {2}',
      new String[]{siblingFields, ns+'Ticket_Item__c', siblingFilterSoql});
    result.rootItems = Database.query(soql);
    soql = String.format('SELECT {0} FROM {1} WHERE IsDeleted=false AND Parent_Ticket_Item__c != NULL AND Ticket__c=:ticketId {2}',
      new String[]{siblingFields, ns+'Ticket_Item__c', siblingFilterSoql});
    result.childItems = Database.query(soql);
    soql = String.format('SELECT {0} FROM {1} WHERE IsDeleted=false AND Id=:ticketId', new String[]{parentFields, ns+'Ticket__c'});
    result.parent = Database.query(soql);

    return result;
  }

  public static CreateItemUsingExactMatchResult CreateNewQtItems(CreateItemUsingExactMatchRequest request, List<Price_Book_Item__c> sourcePBIs, Decimal nextSeqNumber, Id eqId) {
    String ns = StringUtility.FXNamespace();

    String quoteId = request.qtId;
    String parentFields = request.parentFields;
    String siblingFields = request.siblingFields;
    if (!parentFields.contains('LastModifiedDate')) {
        parentFields += ', LastModifiedDate';
    }
    if (!siblingFields.contains('LastModifiedDate')) {
        siblingFields += ', LastModifiedDate';
    }

    CreateItemUsingExactMatchResult result = new CreateItemUsingExactMatchResult();
    result.errorMessage = '';
    result.error = false;

    Quote_Item__c newQt = new Quote_Item__c(Quote__c = quoteId, Price_Book_Item__c = sourcePBIs[0].Id); //create parent quote item
    insert newQt;

    List<Quote_Item__c> newQtItems = [SELECT Id FROM Quote_Item__c WHERE Id=:newQt.Id LIMIT 1];

    Boolean quoteHasEqField = CheckQuoteHasEqField();
    System.debug(quoteHasEqField);
    if (quoteHasEqField && eqId != null) {
      newQtItems[0].put('Equipment__c', eqId);
      Database.update(newQtItems);
    }

    newQtItems = [SELECT Id FROM Quote_Item__c WHERE Id=:newQt.Id LIMIT 1];
    result.newItems = newQtItems;

    String siblingFilterSoql = GetQuoteItemsFilterSoql(request.siblingFilter);

    String soql = String.format('SELECT {0} FROM {1} WHERE IsDeleted=false AND Parent_Quote_Item__c = NULL AND Quote__c=:quoteId {2}',
      new String[]{siblingFields, ns+'Quote_Item__c', siblingFilterSoql});
    result.rootItems = Database.query(soql);
    soql = String.format('SELECT {0} FROM {1} WHERE IsDeleted=false AND Parent_Quote_Item__c != NULL AND Quote__c=:quoteId {2}',
      new String[]{siblingFields, ns+'Quote_Item__c', siblingFilterSoql});
    result.childItems = Database.query(soql);

    soql = String.format('SELECT {0} FROM {1} WHERE IsDeleted=false AND Id=:quoteId', new String[]{parentFields, ns+'Quote__c'});
    result.parent = Database.query(soql);

    return result;
  }

  public static Boolean CheckQuoteHasEqField() {
  System.debug(JSON.serializePretty(Quote_Item__c.getSobjectType().getDescribe().fields.getMap().keySet(), false));
    return Quote_Item__c.getSobjectType().getDescribe().fields.getMap().keySet().contains('Equipment__c') ||
            Quote_Item__c.getSobjectType().getDescribe().fields.getMap().keySet().contains('equipment__c');
  }

  public class CreateItemUsingExactMatchRequest {
    public Id tktId;
    public Id qtId;
    public String pricebookId;
    public String fieldPbi;
    public String fieldEq;
    public String fieldValue;
    public Decimal nextSeqNumber;
    public String objType;
    public String parentFields;
    public String siblingFields;
    public String picklistFields;
    public SiblingFilter siblingFilter;
  }

  public class SiblingFilter {
    public string keyword;
    public string itemType;
    public string classification;
    public string itemLimit;
    public string itemOffset;
    public string sortby;
    public string sortdir;
  }

  public class CreateItemUsingExactMatchResult {
    public String errorMessage;
    public Boolean error;
    public List<sObject> newItems;
    public List<sObject> rootItems;
    public List<sObject> childItems;
    public List<sObject> parent;
  }

}
