global with sharing class FXRemoter {

    global FXRemoter() {  }

    global FXRemoter (ApexPages.StandardController controller) { }

    public FXRemoter(FXBaseController controller) {  }

    global Boolean jsdLicense {
        get{ return FXLicenseController.isCurrentUserLicensed('FXJSD');}
        private set;
    }

    @RemoteAction
    global static List<sObject> queryObject(String soql) {
        return Database.query(soql);
    }

    @RemoteAction
    global static Database.UpsertResult upsertObject(sObject obj, Boolean allOrNothing) {
        return Database.upsert(obj, false);
    }

    @RemoteAction
    global static SvcResult doWork(String svcClassName, String param) {
        return FXWorkerLauncher.DoWork(svcClassName, param);
    }


    @RemoteAction
    global static UpdateResult updateObject(string objStr, string typeStr) {
        Type objType = Type.forName(typeStr);

        sObject obj = (sObject)JSON.deserialize(objStr, objType);

        sObject[] objs = new sObject[]{ obj };
        Database.SaveResult[] res = Database.update(objs, false);

        UpdateResult results = new UpdateResult();
        results.id = obj.id;
        results.success = res[0].success;
        results.errors = new List<UpdateError>();

        for (Database.SaveResult sr : res) {
            for(Database.Error err : sr.getErrors()) {
                UpdateError ue = new UpdateError();
                ue.message = err.getMessage();
                ue.fields = err.getFields();
                results.errors.add(ue);
            }
        }

        return results;
    }
    @RemoteAction
    global static List<UpdateResult> updateObjects(string objStr, string typeStr) {
        Type objType = Type.forName('List<'+typeStr+'>');

        List<sObject> objs = (List<sObject>)JSON.deserialize(objStr, objType);
        Database.SaveResult[] res = Database.update(objs, false);

        List<UpdateResult> results = new List<UpdateResult>();

        for (Database.SaveResult sr : res) {

            UpdateResult result = new UpdateResult();
            result.id = sr.getId();
            result.success = sr.success;

            result.errors = new List<UpdateError>();
            for(Database.Error err : sr.getErrors()) {
                UpdateError ue = new UpdateError();
                ue.message = err.getMessage();
                ue.fields = err.getFields();
                result.errors.add(ue);
            }

            results.add(result);
        }

        return results;
    }

    @RemoteAction
    global static List<UpdateResult> insertObjects(string objStr, string typeStr) {
        Type objType = Type.forName('List<'+typeStr+'>');

        List<sObject> objs = (List<sObject>)JSON.deserialize(objStr, objType);
        Database.SaveResult[] res = Database.insert(objs, false);

        List<UpdateResult> results = new List<UpdateResult>();

        for (Database.SaveResult sr : res) {

            UpdateResult result = new UpdateResult();
            result.id = sr.getId();
            result.success = sr.success;

            result.errors = new List<UpdateError>();
            for(Database.Error err : sr.getErrors()) {
                UpdateError ue = new UpdateError();
                ue.message = err.getMessage();
                ue.fields = err.getFields();
                result.errors.add(ue);
            }

            results.add(result);
        }

        return results;
    }

     @RemoteAction
    global static UpdateResult insertObject(string objStr, string typeStr) {
        Type objType = Type.forName(typeStr);

        sObject obj = (sObject)JSON.deserialize(objStr, objType);

        Database.SaveResult sr=  Database.insert(obj);

        UpdateResult result = new UpdateResult();
        result.id = sr.getId();
        result.success = sr.success;

        result.errors = new List<UpdateError>();
        for(Database.Error err : sr.getErrors()) {
                UpdateError ue = new UpdateError();
                ue.message = err.getMessage();
                ue.fields = err.getFields();
                result.errors.add(ue);
        }



        return result ;
    }

    @RemoteAction
    global static List<UpdateResult> deleteObjects(string objStr, string typeStr) {
        List<UpdateResult> results = new List<UpdateResult>();
        String ns = UtilityGetNamespace.CurrentNamespace().toLowercase();

        Type objType = Type.forName('List<'+typeStr+'>');
        List<sObject> objs = (List<sObject>)JSON.deserialize(objStr, objType);

        if (objs.isEmpty()) {
            return results;
        }

        Schema.DescribeSObjectResult dsr = objs.get(0).getsObjectType().getDescribe();
        typeStr = dsr.getName().toLowercase();

        String parentField = 'parent_' + typeStr.replace(ns, '');
        String parentFieldFull = ns + 'parent_' + typeStr.replace(ns, '');
        System.debug(parentFieldFull);

        Set<String> fields = dsr.fields.getMap().keySet();
        Boolean hasSelfReference = fields.contains(parentFieldFull) || fields.contains(parentField);

        Database.DeleteResult[] res = new List<Database.DeleteResult>();

        if (!hasSelfReference) {
          res = Database.delete(objs, false);
          results.addAll(convertDeleteResults(res));
        } else {
          List<sObject> rootItems = new List<sObject>();
          List<sObject> childItems = new List<sObject>();
          Set<Id> rootItemsSet = new Set<Id>();
          Set<Id> childItemsSet = new Set<Id>();
          Set<Id> objsSet = new Set<Id>();

          for(sObject obj: (List<sObject>)objs)
          {
              objsSet.add(obj.Id);
          }

          String soql = String.format('SELECT Id, {0} FROM {1} WHERE IsDeleted=false AND Id IN :objsSet', new String[]{parentFieldFull, typeStr});
          for(sObject item : Database.query(soql))
          {
              if(item.get(parentField) == null) {
                rootItems.add(item);
                rootItemsSet.add(item.Id);
              } else {
                childItems.add(item);
                childItemsSet.add(item.Id);
              }
          }

          res = Database.delete(childItems, false); //delete child items that were selected for deletion
          results.addAll(convertDeleteResults(res));

          String lookupIdField = parentFieldFull.replace('__c', '__r.Id');
          String childSoql = String.format('SELECT Id FROM {0} WHERE IsDeleted=false AND {1} IN :rootItemsSet AND Id NOT IN :childItemsSet', new String[]{typeStr, lookupIdField});
          System.debug(childSoql);

          List<sObject> childrenOfRootItems = Database.query(childSoql);
          res = Database.delete(childrenOfRootItems, false); //delete children of root items
          results.addAll(convertDeleteResults(res));

          res = Database.delete(rootItems, false); //delete root items
          results.addAll(convertDeleteResults(res));
        }

        return results;
    }

    private static List<UpdateResult> convertDeleteResults(Database.DeleteResult[] res) {
      List<UpdateResult> results = new List<UpdateResult>();

      for (Database.DeleteResult dr : res) {

          UpdateResult result = new UpdateResult();
          result.id = dr.getId();
          result.success = dr.success;

          result.errors = new List<UpdateError>();
          for(Database.Error err : dr.getErrors()) {
              UpdateError ue = new UpdateError();
              ue.message = err.getMessage();
              ue.fields = err.getFields();
              result.errors.add(ue);
          }

          results.add(result);
      }

      return results;
    }

    @RemoteAction
    global static UpdateResult deleteObject(string objStr, string typeStr) {
        Type objType = Type.forName(typeStr);

        sObject obj = (sObject)JSON.deserialize(objStr, objType);

        Database.DeleteResult sr=  Database.delete(obj);

        UpdateResult result = new UpdateResult();
        result.id = sr.getId();
        result.success = sr.success;

        result.errors = new List<UpdateError>();
        for(Database.Error err : sr.getErrors()) {
                UpdateError ue = new UpdateError();
                ue.message = err.getMessage();
                ue.fields = err.getFields();
                result.errors.add(ue);
        }



        return result ;
    }


    @RemoteAction
    global static Schema.DescribeSobjectResult[] describeSobject(String objectType) {
        String[] objectTypes = new String[]{ objectType };
        return Schema.describeSObjects(objectTypes);
    }

    @RemoteAction
    global static SobjectExtended describeSobjectExtended(String objectType) {
        String[] objectTypes = new String[]{ objectType };
        SobjectExtended sObjectExtended = new SobjectExtended();

        Schema.DescribeSobjectResult[] sObjects = Schema.describeSObjects(objectTypes);
        sObjectExtended.obj = null;
        sObjectExtended.extendedInfo = '[]';

        if (sObjects.size() > 0) {
            ExtendedInfo extendedInfo = new ExtendedInfo();

            sObjectExtended.obj = sObjects.get(0);
            extendedInfo.objFieldMap = new Map<String, Schema.DescribeFieldResult>();

            Map<String, Schema.SObjectField> fieldMap = sObjectExtended.obj.fields.getMap();
            for (SObjectField f : fieldMap.values()) {
              Schema.DescribeFieldResult dfr = f.getDescribe();
              extendedInfo.objFieldMap.put(dfr.getName(), dfr);
//                String s = JSON.serialize(f.getDescribe());
//                System.debug(s);
            }

//System.debug(extendedInfo.objString);

//Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Account.fields.getMap();
            List<Schema.RecordTypeInfo> recordTypeInfos = sObjectExtended.obj.getRecordTypeInfos();
            extendedInfo.recordTypeInfos = recordTypeInfos;
            sObjectExtended.extendedInfo = JSON.serialize(extendedInfo);
        }

        return sObjectExtended;
    }

    @RemoteAction
    global static PricebookItemsSvc.Result getPricebookItems(String jobId, String ticketId, String showItemsAlreadyOnTheTicket, String keyword, String classification,
        String itemType, String itemLimit, String itemOffset, String sortby, String sortdir, String fields) {

        return PricebookItemsSvc.searchPricebookItems(jobId, ticketId, showItemsAlreadyOnTheTicket, keyword, classification,
                    itemType, itemLimit, itemOffset, sortby, sortdir, fields);
    }

    @RemoteAction
    global static ScheduledCrewSvc.Result getScheduledCrew(String jobId, String keyword, String itemLimit, String itemOffset, String sortby, String sortdir, String fields) {
        return ScheduledCrewSvc.searchScheduledCrew(jobId, keyword,  itemLimit, itemOffset, sortby, sortdir, fields);
    }

    @RemoteAction
    global static ScheduledEquipmentSvc.Result getScheduledEquipment(String jobId, String keyword, String itemLimit, String itemOffset, String sortby, String sortdir, String fields) {
        return ScheduledEquipmentSvc.searchScheduledEquipment(jobId, keyword,  itemLimit, itemOffset, sortby, sortdir, fields);
    }

    @RemoteAction
    global static PricebookItemsForQuoteSvc.Result getPricebookItemsForQuote(String quoteId, String showItemsAlreadyOnTheQuote, String keyword, String classification,
        String itemType, String itemLimit, String itemOffset, String sortby, String sortdir, String fields) {

        return PricebookItemsForQuoteSvc.searchPricebookItemsForQuote(quoteId, showItemsAlreadyOnTheQuote, keyword, classification,
                    itemType, itemLimit, itemOffset, sortby, sortdir, fields);
    }

    @RemoteAction
    global static QuoteItemsSvc.Result getQuoteItems(String jobId, String ticketId, String showItemsAlreadyOnTheTicket, String keyword, String classification,
        String itemType, String itemLimit, String itemOffset, String sortby, String sortdir) {

        return QuoteItemsSvc.searchQuoteItems(jobId, ticketId, showItemsAlreadyOnTheTicket, keyword, classification,
                    itemType, itemLimit, itemOffset, sortby, sortdir);
    }

    @RemoteAction
    global static QuoteV2ItemsSvc.Result getQuoteV2Items(String quoteId, String ticketId, String showItemsAlreadyOnTheTicket, String keyword,
        String itemType, String itemLimit, String itemOffset, String sortby, String sortdir, String fields) {

        return QuoteV2ItemsSvc.searchQuoteItems(quoteId, ticketId, showItemsAlreadyOnTheTicket, keyword,
                    itemType, itemLimit, itemOffset, sortby, sortdir, fields);
    }

    @RemoteAction
    global static List<Ticket_Item__c> createTicketItemFromQuoteItem(Id newTicketId, List<Id> quoteItemIds, Boolean honorSequenceNumber, Decimal nextSequenceNumber)
    {
        List<Ticket_Item__c> ticketItems = new List<Ticket_Item__c>();
        for(Id quoteItemId: quoteItemIds)
        {
            ticketItems.add(TicketRestHandler.CreateTicketItem(newTicketId, quoteItemId, honorSequenceNumber, nextSequenceNumber));
            nextSequenceNumber++;
        }

        return ticketItems;
    }

    @RemoteAction
    global static List<Ticket_Item__c> createTicketItemFromQuoteV2Item(Id newTicketId, List<Id> quoteItemIds, Boolean honorSequenceNumber, Decimal nextSequenceNumber)
    {
        return CreateTicketItemsFromQuoteItems.CreateTicketItems(newTicketId, quoteItemIds, honorSequenceNumber, nextSequenceNumber);
    }

    @RemoteAction
    global static List<Ticket_Item__c> CreateTicketItems(Id tktId, List<Id> sourceIds, Decimal nextSequenceNumber) {
        return TicketItemHandler.CreateTicketItems(tktId, sourceIds, nextSequenceNumber);
    }

    @RemoteAction
    global static List<Ticket_Item__c> copyTicketItems(Id newTicketId, List<Id> ticketItemIds, Boolean honorSequenceNumber, Decimal nextSequenceNumber)
    {
        return CopyTicketItems.CopyTicketItems(newTicketId, ticketItemIds, honorSequenceNumber, nextSequenceNumber);
    }

    @RemoteAction
    global static TicketItemsSvc.UpdateTktItemResult updateTicketItem(string objStr, string typeStr, string tktFields, string tktItemFields) {
        return TicketItemsSvc.updateTktItem(objStr, typeStr, tktFields, tktItemFields);
    }

    @RemoteAction
    global static List<Quote_Item__c> copyQuoteItems(Id newQuoteId, List<Id> quoteItemIds, Boolean honorSequenceNumber, Decimal nextSequenceNumber)
    {
        return CopyQuoteItems.CopyQuoteItems(newQuoteId, quoteItemIds, honorSequenceNumber, nextSequenceNumber);
    }

    @RemoteAction
    global static List<Price_Book_Item__c> CreatePricebookItems(Id newPricebookId, List<Id> catalogItemIds, String parentId)
    {
        return CreatePricebookItemsFromCatalogItems.CreatePricebookItems(newPricebookId, catalogItemIds, parentId);
    }

    @RemoteAction
    global static QuoteItemsUpdate.UpdateQtItemResult updateQuoteItem(string objStr, string typeStr, string qtFields, string qtItemFields) {
        return QuoteItemsUpdate.QuoteItemUpdate(objStr, typeStr, qtFields, qtItemFields);
    }

    @RemoteAction
    global static ParentPricebookUtilities.Result GetPriceBookItemsFromParentPricebooks(
            Id pricebookId,
            String ticketId, String showItemsAlreadyOnTheTicket, String keyword, String classification,
            String itemType, String itemLimit, String itemOffset, String sortby, String sortdir, String fields)

    {
        return ParentPricebookUtilities.GetPriceBookItems(pricebookId, ticketId, showItemsAlreadyOnTheTicket, keyword, classification,
            itemType, itemLimit, itemOffset, sortby, sortdir, fields, null);
    }


    @RemoteAction
    global static ParentPricebookUtilities.Result GetPriceBookItemsFromParentPricebooksByType(
            Id pricebookId,
            String ticketId, String showItemsAlreadyOnTheTicket, String keyword, String classification,
            String itemType, String itemLimit, String itemOffset, String sortby, String sortdir, String fields, String sobjectType)

    {
        return ParentPricebookUtilities.GetPriceBookItems(pricebookId, ticketId, showItemsAlreadyOnTheTicket, keyword, classification,
            itemType, itemLimit, itemOffset, sortby, sortdir, fields, sobjectType);
    }

    @RemoteAction
    global static ParentPricebookUtilities.Result GetPriceBookItemsFromParentPricebook(
            Id parentPricebookId,
            String ticketId, String showItemsAlreadyOnTheTicket, String keyword, String classification,
            String itemType, String itemLimit, String itemOffset, String sortby, String sortdir, String fields)

    {
        return ParentPricebookUtilities.GetPricebookItemsFromParentPricebook(parentPricebookId, ticketId, showItemsAlreadyOnTheTicket, keyword, classification,
            itemType, itemLimit, itemOffset, sortby, sortdir, fields, null);
    }

    @RemoteAction
    global static ParentPricebookUtilities.Result GetPriceBookItemsFromParentPricebookByType(
            Id parentPricebookId,
            String ticketId, String showItemsAlreadyOnTheTicket, String keyword, String classification,
            String itemType, String itemLimit, String itemOffset, String sortby, String sortdir, String fields, String sobjectType)

    {
        return ParentPricebookUtilities.GetPricebookItemsFromParentPricebook(parentPricebookId, ticketId, showItemsAlreadyOnTheTicket, keyword, classification,
            itemType, itemLimit, itemOffset, sortby, sortdir, fields, sobjectType);
    }

    @RemoteAction
    global static String GetManagedPackageVersion()
    {
        return UtilityGetBaseManagedPackageVersion.BaseManagedPackageVersion(); // returns vers.major() + '.' + vers.minor() of the FX5 managed pkg
    }

    @RemoteAction
    global static Object CheckIfDeleted(String sObjectType, String extIdField, String extId)
    {
        // Name is required if you want to search the Recycle bin for the record (<sf-instance-url>/search/UndeletePage?del_scope=2&recycleSearch=${Name})
        String soql = String.format('SELECT Id, Name, IsDeleted, LastModifiedDate, LastModifiedById, {1} FROM {0} WHERE {1} = :extId ALL ROWS ', new String[]{sObjectType, extIdField});

        SObject[] objs = Database.query(soql);
        return objs;
    }

    @RemoteAction
    global static String Process(string action, string objStr) {
        return FXProcess.Process(action, objStr);
    }

    global class UpdateResult {
        public String id { get; set; }
        public Boolean success  { get; set; }
        public List<UpdateError> errors  { get; set; }
    }

    public class UpdateError {
        public String message { get; set; }
        public List<String> fields { get; set; }
    }

    global class SobjectExtended {
      public Schema.DescribeSobjectResult obj { get; set; }
      public String extendedInfo { get; set; }
    }

    public class ExtendedInfo {
        public List<Schema.RecordTypeInfo> recordTypeInfos { get; set; }
        public Map<String, Schema.DescribeFieldResult> objFieldMap { get; set; }
    }
}
