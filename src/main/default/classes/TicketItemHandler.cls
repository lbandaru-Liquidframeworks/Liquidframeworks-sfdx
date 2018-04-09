public class TicketItemHandler
{
    static String crewPlanningKeyPrefix = Crew_Planning__c.sObjectType.getDescribe().keyPrefix;
    static String equipPlanningKeyPrefix = Equipment_Planning__c.sObjectType.getDescribe().keyPrefix;
    static String priceBookItemKeyPrefix = Price_Book_Item__c.sObjectType.getDescribe().keyPrefix;
    static String quoteItemKeyPrefix = Quote_Item__c.sObjectType.getDescribe().keyPrefix;

    public static String CreateTicketItems(String processStr) {
        JSONParser parser = JSON.createParser(processStr);
        Type resultType = Type.forName('TicketItemHandler.TicketItemHandlerResponse');
        TicketItemHandler.TicketItemHandlerResponse readValueAsResults = (TicketItemHandler.TicketItemHandlerResponse)parser.readValueAs(resultType);

        List<Ticket_Item__c> result = CreateTicketItems(readValueAsResults.tktId, readValueAsResults.sourceIds, readValueAsResults.nextSeqNumber, readValueAsResults.parentTktItemId);

        return JSON.serializePretty(result, false);
    }

    public static List<Ticket_Item__c> CreateTicketItems(Id tktId, List<Id> sourceIds, String parentTktItemId)
    {
        return CreateTicketItems(tktId, sourceIds, null, parentTktItemId);
    }

    public static List<Ticket_Item__c> CreateTicketItems(Id tktId, List<Id> sourceIds, Decimal nextSeqNumber)
    {
      return CreateTicketItems(tktId, sourceIds, nextSeqNumber, null);
    }

    public static List<Ticket_Item__c> CreateTicketItems(Id tktId, List<Id> sourceIds, Decimal nextSeqNumber, String parentTktItemId)
    {
        if(sourceIds.isEmpty()) return null;
        Schema.DescribeSObjectResult rQuoteItem = Quote_Item__c.sObjectType.getDescribe();
        if(!rQuoteItem.isAccessible() || !rQuoteItem.isCreateable()) {
            return null;
        }

        String itemId = sourceIds.get(0);
        List<Ticket_Item__c> newItems = null;

        if(itemId.startsWith(priceBookItemKeyPrefix))
        {
            newItems = CreateTicketItemWithPriceBookItem(tktId, new Set<Id>(sourceIds), parentTktItemId);
        }
        else if(itemId.startsWith(crewPlanningKeyPrefix))
        {
            newItems =  CreateTicketItemWithCrewPlanning(tktId, new Set<Id>(sourceIds), parentTktItemId);
        }
        else if(itemId.startsWith(equipPlanningKeyPrefix))
        {
            newItems =  CreateTicketItemWithEquipmentPlanning(tktId, new Set<Id>(sourceIds), parentTktItemId);
        }
        else if(itemId.startsWith(quoteItemKeyPrefix))
        {
            newItems =  CreateTicketItemWithQuoteItem(tktId, sourceIds, parentTktItemId);
        }

        if(newItems == null || newItems.isEmpty()) return null;

        ApplySequenceNumber(newItems, sourceIds, nextSeqNumber);
        Boolean flagValue = RuleEngineCore.RuleEngineInProgress;
        try
        {
            RuleEngineCore.RuleEngineInProgress = true;
            List<Ticket_Item__c> rootItems = new List<Ticket_Item__c>();
            List<Ticket_Item__c> childItems = new List<Ticket_Item__c>();
            for(Ticket_Item__c ti: newItems)
            {
                if(ti.Parent_Ticket_Item__r ==null) rootItems.add(ti);
                else childItems.add(ti);

            }

            insert rootItems;
            insert childItems;

            Map<Id, Ticket_Item__c> newItemsMap = new Map<Id, Ticket_Item__c>(newItems);
            Set<Id> tktItemIds = newItemsMap.keySet();

            String ns = StringUtility.FXNamespace();
            List<String> fields = new List<String>();
            fields.add('Id');
            fields.add(ns+'Price_Book_Item__c');
            fields.add(ns+'Equipment__c');
            fields.add(ns+'Contact__c');
            fields.add(ns+'Sequence_Number__c');
            fields.add(ns+'Quote_Item__c');
            String fieldsStr = String.join(fields, ',');

            String tiSoql = String.format('SELECT {0} FROM {1} WHERE Id IN :tktItemIds', new String[]{fieldsStr, ns+'Ticket_Item__c'});
            List<Ticket_Item__c> tktItems = (List<Ticket_Item__c>)Database.query(tiSoql);

            Boolean updated = false;
            for(Ticket_Item__c ti : tktItems) {
              Ticket_item__c newItem = newItemsMap.get(ti.Id);
              if(newItem != null) {
                if (newItem.Equipment__c!=null) {
                  ti.Equipment__c = newItem.Equipment__c;
                  updated = true;
                }
                if (newItem.Contact__c!=null) {
                  ti.Contact__c = newItem.Contact__c;
                  updated = true;
                }
              }
            }

            if (updated) {
              Database.update(tktItems);
            }

            tktItems = (List<Ticket_Item__c>)Database.query(tiSoql);

            return tktItems;
        }
        catch (Exception ex)
        {
            throw ex;
        }
        finally
        {
            RuleEngineCore.RuleEngineInProgress = flagValue;
        }
    }

    static List<Ticket_Item__c> CreateTicketItemWithPriceBookItem(Id tktId, Set<Id> sourceItemIds, String parentTktItemId)
    {

        List<Ticket_Item__c> newItems = new List<Ticket_Item__c>();
        Map<String, Id> rtLookup = GetTicketItemRecordTypeLookup();

        List<Price_Book_Item__c> sources = [SELECT Id, Ticket_Item_Record_Type__c FROM Price_Book_Item__c WHERE IsDeleted=false and Id IN :sourceItemIds];

        SobjectType tktItemType = Ticket_Item__c.SobjectType;

        for(Price_Book_Item__c obj: sources)
        {
            Id tiRecordType = rtLookup.containsKey(obj.Ticket_Item_Record_Type__c)? rtLookup.get(obj.Ticket_Item_Record_Type__c) : null;
            Ticket_Item__c ti = (Ticket_Item__c)tktItemType.newSObject(tiRecordType, true);
            ti.Ticket__c = tktId;
            ti.Price_Book_Item__c = obj.Id;
            ti.Parent_Ticket_Item__c = parentTktItemId;
            newItems.add(ti);
        }
        return newItems;

    }

    static List<Ticket_Item__c> CreateTicketItemWithQuoteItem(Id tktId, List<Id> sourceItemIds, String parentTktItemId)
    {

        List<Ticket_Item__c> newItems = new List<Ticket_Item__c>();

        String ns = UtilityGetNamespace.CurrentNamespace();

        Map<String, Id> rtLookup = GetTicketItemRecordTypeLookup();

        Set<String> quoteItemFields = Quote_Item__c.sObjectType.getDescribe().fields.getMap().keySet();
        Set<String> quoteItemQueryFields = new Set<String>();
        quoteItemQueryFields.addAll(quoteItemFields);
        quoteItemQueryFields.add('RecordType.DeveloperName');
        quoteItemQueryFields.add('RecordType.Name');

        String soql = String.format('SELECT {1} FROM {0}Quote_Item__c WHERE IsDeleted=false AND (Id IN :sourceItemIds OR {0}Parent_Quote_Item__c IN :sourceItemIds) ORDER BY {0}Parent_Quote_Item__c NULLS FIRST',
            new String[]{ns, String.join(new List<String>(quoteItemQueryFields), ',')});

        List<Quote_Item__c> sources = (List<Quote_Item__c>)Database.query(soql);
        Map<Id, Quote_Item__c> sourcesLookup = new Map<Id, Quote_Item__c>(sources);

        Map<String, String> tktItemToQuoteItemFieldMapping =  GetTicketItemToQuoteItemFieldMapping(ns.toLowercase(), quoteItemFields);

        SobjectType tktItemType = Ticket_Item__c.SobjectType;

        //for setting up TicketItem parent/child relationship with QuoteItem parent/child info
        Map<Id, Ticket_Item__c> quoteItemToTktItemLookup = new Map<Id, Ticket_Item__c>();

        for(Id sourceItemId: sourceItemIds)
        {
            Quote_Item__c obj = sourcesLookup.get(sourceItemId);
            Id tiRecordType = rtLookup.containsKey(obj.RecordType.DeveloperName)? rtLookup.get(obj.RecordType.DeveloperName) : null;
            Ticket_Item__c ti = (Ticket_Item__c)tktItemType.newSObject(tiRecordType, true);
            for(String f: tktItemToQuoteItemFieldMapping.keySet())
            {
                ti.put(f, obj.get(tktItemToQuoteItemFieldMapping.get(f)));
            }
            ti.Ticket__c = tktId;
            ti.Quote_Item__c = obj.Id;
            ti.SyncID__c = StringUtility.newGuid();

            if (!String.IsEmpty(parentTktItemId)) {
              ti.Parent_Ticket_Item__c = parentTktItemId;
            } else if(!String.isBlank(obj.Parent_Quote_Item__c) && quoteItemToTktItemLookup.containsKey(obj.Parent_Quote_Item__c))
            {
                ti.Parent_Ticket_Item__r = new Ticket_Item__c(SyncID__c = quoteItemToTktItemLookup.get(obj.Parent_Quote_Item__c).SyncID__c);
            }
            newItems.add(ti);
            quoteItemToTktItemLookup.put(obj.Id, ti);

        }
        return newItems;
    }

    static List<Ticket_Item__c> CreateTicketItemWithCrewPlanning(Id tktId, Set<Id> sourceItemIds, String parentTktItemId)
    {
        List<Ticket_Item__c> newItems = new List<Ticket_Item__c>();
        Map<String, Id> rtLookup = GetTicketItemRecordTypeLookup();

        List<Crew_Planning__c> cps = [SELECT Id, Role_on_Job__c, Role_on_Job__r.Ticket_Item_Record_Type__c, Crew_Member__c FROM Crew_Planning__c WHERE IsDeleted=false and Id IN :sourceItemIds];

        SobjectType tktItemType = Ticket_Item__c.SobjectType;

        for(Crew_Planning__c cp: cps)
        {
            if(String.isBlank(cp.Role_on_Job__c)) continue;
            Id tiRecordType = rtLookup.containsKey(cp.Role_on_Job__r.Ticket_Item_Record_Type__c)? rtLookup.get(cp.Role_on_Job__r.Ticket_Item_Record_Type__c) : null;
            Ticket_Item__c ti = (Ticket_Item__c)tktItemType.newSObject(tiRecordType, true);
            ti.Ticket__c = tktId;
            ti.Contact__c = cp.Crew_Member__c;
            ti.Price_Book_Item__c = cp.Role_on_Job__c;
            ti.SyncID__c = StringUtility.newGuid();
            ti.Parent_Ticket_Item__c = parentTktItemId;
            newItems.add(ti);

            if (String.IsEmpty(parentTktItemId)) {
              List<Price_Book_Item__c> childPbItems = [SELECT Id, Ticket_Item_Record_Type__c FROM Price_Book_Item__c WHERE IsDeleted=false AND Parent_Price_Book_Item__c = :ti.Price_Book_Item__c];

              for(Price_Book_Item__c childPbItem : childPbItems)
              {
                  Id recordType = rtLookup.containsKey(childPbItem.Ticket_Item_Record_Type__c) ? rtLookup.get(childPbItem.Ticket_Item_Record_Type__c) : null;
                  Ticket_Item__c childTi = (Ticket_Item__c)tktItemType.newSObject(recordType, true);
                  childTi.Ticket__c = tktId;
                  childTi.Price_Book_Item__c = childPbItem.Id;
                  childTi.Parent_Ticket_Item__r = new Ticket_Item__c(SyncID__c = ti.SyncID__c);
                  newItems.add(childTi);
              }
            }
        }

        return newItems;
    }

    static List<Ticket_Item__c> CreateTicketItemWithEquipmentPlanning(Id tktId, Set<Id> sourceItemIds, String parentTktItemId)
    {
        List<Ticket_Item__c> newItems = new List<Ticket_Item__c>();

        Map<String, Id> rtLookup = GetTicketItemRecordTypeLookup();

        List<Equipment_Planning__c> sources = [SELECT Id, Price_Book_Item__c, Price_Book_Item__r.Ticket_Item_Record_Type__c, Equipment2__c FROM Equipment_Planning__c WHERE IsDeleted=false and Id IN :sourceItemIds];

        SobjectType tktItemType = Ticket_Item__c.SobjectType;

        for(Equipment_Planning__c p: sources)
        {
            if(String.isBlank(p.Price_Book_Item__c)) continue;
            Id tiRecordType = rtLookup.containsKey(p.Price_Book_Item__r.Ticket_Item_Record_Type__c)? rtLookup.get(p.Price_Book_Item__r.Ticket_Item_Record_Type__c) : null;
            Ticket_Item__c ti = (Ticket_Item__c)tktItemType.newSObject(tiRecordType, true);
            ti.Ticket__c = tktId;
            ti.Equipment__c = p.Equipment2__c;
            ti.Price_Book_Item__c = p.Price_Book_Item__c;
            ti.SyncID__c = StringUtility.newGuid();
            ti.Parent_Ticket_Item__c = parentTktItemId;
            newItems.add(ti);

            if (String.IsEmpty(parentTktItemId)) {
              List<Price_Book_Item__c> childPbItems = [SELECT Id, Ticket_Item_Record_Type__c FROM Price_Book_Item__c WHERE IsDeleted=false AND Parent_Price_Book_Item__c = :ti.Price_Book_Item__c];

              for(Price_Book_Item__c childPbItem : childPbItems)
              {
                  Id recordType = rtLookup.containsKey(childPbItem.Ticket_Item_Record_Type__c) ? rtLookup.get(childPbItem.Ticket_Item_Record_Type__c) : null;
                  Ticket_Item__c childTi = (Ticket_Item__c)tktItemType.newSObject(recordType, true);
                  childTi.Ticket__c = tktId;
                  childTi.Price_Book_Item__c = childPbItem.Id;
                  childTi.Parent_Ticket_Item__r = new Ticket_Item__c(SyncID__c = ti.SyncID__c);
                  newItems.add(childTi);
              }
            }
        }

        return newItems;
    }

    static Map<String, String> GetTicketItemToQuoteItemFieldMapping(String nsLowercase, Set<String> quoteItemFields)
    {
        Map<String, String> tiToQuoteFieldMapping = new Map<String, String>();
        Boolean isInDev = String.isBlank(nsLowercase);

        for(Schema.SObjectField f: Schema.sObjectType.Ticket_Item__c.fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe();

            if (!fd.isCustom() || !fd.isAccessible() || !fd.isCreateable() || fd.isCalculated() || fd.isAutoNumber())
            {
                continue;
            }
            String tiFieldName = fd.getName().toLowercase();
            if(quoteItemFields.contains(tiFieldName))
            {
                tiToQuoteFieldMapping.put(tiFieldName, tiFieldName);
            }
            else if(!isInDev)
            {
                String qiField = '';
                if(tiFieldName.startsWith(nsLowercase))
                {
                    qiField = tiFieldName.replace(nsLowercase, '');
                }
                else
                {
                    qiField = nsLowercase + tiFieldName;
                }
                if(quoteItemFields.contains(qiField))
                {
                    tiToQuoteFieldMapping.put(tiFieldName, qiField);
                }
            }
        }
        tiToQuoteFieldMapping.remove(nsLowercase + 'syncid__c');
        tiToQuoteFieldMapping.remove(nsLowercase + 'auto_added__c');
        tiToQuoteFieldMapping.remove(nsLowercase + 'rule_required_item__c');

        tiToQuoteFieldMapping.put(nsLowercase+'input_qty__c' , nsLowercase + 'qty__c');
        return tiToQuoteFieldMapping;
    }

    static void ApplySequenceNumber(List<Ticket_Item__c> items, List<Id> sourceIds, Decimal nextSeqNumber)
    {
        if(nextSeqNumber == null || nextSeqNumber<0) return;

        for(Ticket_Item__c ti : items)
        {
            ti.Sequence_Number__c = nextSeqNumber;
            nextSeqNumber++;
        }
    }

    static Map<String, Id> GetTicketItemRecordTypeLookup()
    {
        String ns = StringUtility.FXNamespace();
        String tktItemFullName = ns + 'Ticket_Item__c';
        Map<String, Id> rtLookup = new Map<String, Id>();
        for(RecordType rt : [SELECT Id, Name, DeveloperName FROM RecordType WHERE IsActive=true AND SobjectType = :tktItemFullName])
        {
            rtLookup.put(rt.Name, rt.Id);
            rtLookup.put(rt.DeveloperName, rt.Id);
        }
        return rtLookup;
    }

    public class TicketItemHandlerResponse {
      public Id tktId;
      public List<Id> sourceIds;
      public Decimal nextSeqNumber;
      public String parentTktItemId;
    }
}
