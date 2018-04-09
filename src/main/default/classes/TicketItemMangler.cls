public class TicketItemMangler
{
    public static void OnBeforeInsert(List<Ticket_Item__c> items)
    {
        if(SObjectClonerUtility.CloningInProgress !=true)
        {
           InitializeTicketItems(items);
           RuleEngineConsole.OnTicketItemBeforeInsert(items);
        }
        for (Ticket_Item__c ti: items)
        {
            if(String.isBlank(ti.SyncID__c))
            {
                ti.SyncID__c = StringUtility.newGuid();
            }
        }
	
	OverrideHandler.ApplyOverride(items);
    }

    public static void OnBeforeUpdate(List<Ticket_Item__c> items, Map<Id, Ticket_Item__c> oldMap)
    {

	OverrideHandler.ApplyOverride(items);


    }

    public static void OnBeforeDelete(List<Ticket_Item__c> items)
    {
        Set<Id> itemIds = new Map<Id, Ticket_Item__c>(items).keySet();
        Map<Id, Ticket_Item__c> dbTktItems = new Map<Id, Ticket_Item__c>([SELECT Id, (SELECT Id FROM Ticket_Items__r WHERE Id NOT IN :itemIds) FROM Ticket_Item__c WHERE Id IN :itemIds]);

        Set<Id> pbRequiredItems = new Map<Id, Ticket_Item__c>([SELECT Id FROM Ticket_Item__c WHERE Id IN :itemIds AND PBI_Required_Item__c=true AND Price_Book_Item__r.Required_Item__c = true]).keySet();

        List<Ticket_Item__c> childItemsToDelete = new List<Ticket_Item__c>();
        for(Ticket_Item__c ti: items)
        {
            if (RuleEngineCore.RuleEngineInProgress!=true && ti.Auto_Added__c == true
                && ti.Rule_Required_Item__c ==true && (ti.PBI_Required_Item__c == pbRequiredItems.contains(ti.Id)))
            {
                ti.addError('Cannot delete a required ticket item.');
                continue;
            }

            if(!dbTktItems.get(ti.Id).Ticket_Items__r.isEmpty())
            {
                childItemsToDelete.addAll(dbTktItems.get(ti.Id).Ticket_Items__r);
            }
        }

        if(!childItemsToDelete.isEmpty())
        {
            Boolean flag = RuleEngineCore.RuleEngineInProgress;
            try
            {

                RuleEngineCore.RuleEngineInProgress = true;
                delete childItemsToDelete;
            }
            catch(Exception ex)
            {
                throw ex;
            }
            finally
            {
                RuleEngineCore.RuleEngineInProgress = flag;
            }
        }

    }

    public static void OnAfterInsert(List<Ticket_Item__c> items)
    {
        //System.debug('TicketItemManagler OnAfterInsert CloningInProgress=' + SObjectClonerUtility.CloningInProgress);
        if(SObjectClonerUtility.CloningInProgress != true && RuleEngineCore.RuleEngineInProgress != true)
        {
           TicketItemMangler.AddChildren(items);
           RuleEngineConsole.OnTicketItemAfterInsert(items);
        }
        InventoryManager.OnTicketItemAfterInsert(items);
    }

    public static void OnAfterUpdate(List<Ticket_Item__c> items, Map<Id, Ticket_Item__c> oldMap)
    {
        InventoryManager.OnTicketItemAfterUpdate(items, oldMap);
        if(SObjectClonerUtility.CloningInProgress != true && RuleEngineCore.RuleEngineInProgress != true)
        {
           RuleEngineConsole.OnTicketItemUpdate(items);
        }
    }

    public static void OnAfterDelete(List<Ticket_Item__c> items)
    {
        InventoryManager.OnTicketItemAfterDelete(items);
    }

    public static void InitializeTicketItems(List<Ticket_Item__c> items)
    {
        Set<Id> pliIds = new Set<Id>();
        Set<Id> tktIds = new Set<Id>();
        List<Ticket_Item__c> itemsToPocess = new List<Ticket_Item__c>();
        for(Ticket_Item__c ti : items)
        {
            if(ti.Created_in_Mobile__c == true || !String.isBlank(ti.Quote_Item__c) && !String.isBlank(ti.SyncID__c)) continue;

            pliIds.add(ti.Price_Book_Item__c);
            itemsToPocess.add(ti);
            tktIds.add(ti.Ticket__c);
        }
        if(itemsToPocess.isEmpty()) return;

        String ns = UtilityGetNamespace.CurrentNamespace();

        String soql = 'SELECT ' + ns + 'Price_Book__r.' + ns + 'Surcharge_Rate_Env__c,'
                             + ns + 'Price_Book__r.' + ns + 'Surcharge_Rate_Fuel__c,'
                             + ns + 'Price_Book__r.' + ns + 'AddTktItemsByPBSeqNum__c,'
                             + ns + 'Catalog_Item__r.' + ns + 'Classification__c,'
                             + ns + 'Catalog_Item__r.' + ns + 'Track_Inventory__c,'
                             + ns + 'Catalog_Item__r.' + ns + 'Description__c,'
                             + ns + 'Catalog_Item__r.' + ns + 'UOM__c,'
                             + ns + 'Catalog_Item__r.' + ns + 'Cost__c, '
                             + ns + 'Catalog_Item__r.' + ns + 'Ticket_Item_Record_Type__c';
        String sep = ',';

        Set<String> pbiFields = new Set<String>(); //Schema.sObjectType.Price_Book_Item__c.fields.getMap().keySet();

        for(Schema.SObjectField f: Schema.sObjectType.Price_Book_Item__c.fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe();
            pbiFields.add(fd.getName().toLowerCase());
        }

        for(String f: pbiFields)
        {
            soql += sep + f;
        }
        soql += ' FROM ' + ns + 'Price_Book_Item__c WHERE Id IN :pliIds';


        List<Price_Book_Item__c> objs = new List<Price_Book_Item__c>();
        for(sObject o : Database.query(soql))
        {
            objs.add((Price_Book_Item__c)o);
        }

        Map<Id, Price_Book_Item__c> pliMap = new Map<Id, Price_Book_Item__c>(objs);

        String objType = ns  + 'Ticket_Item__c';

        Map<string, Id> recordTypeLookup = new Map<string, Id>();
        for(RecordType rt : [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType=:objType])
        {
            recordTypeLookup.put(rt.Name, rt.Id);
            recordTypeLookup.put(rt.DeveloperName, rt.Id);
        }

        Map<Id, Ticket__c> ticketLookup = new Map<Id, Ticket__c>([SELECT Warehouse__c FROM Ticket__c where Id IN :tktIds AND Warehouse__c != null]);

        AggregateResult[] groupedTicketLookup = [SELECT Ticket__c, max(Sequence_Number__c) maxseq FROM Ticket_Item__c WHERE Ticket__c in :tktIds GROUP BY Ticket__c];



        Map<ID, TicketInfo> ticketInfos = new Map<ID, TicketInfo>();

        for (Id tktId : tktIds)
        {
            TicketInfo tinfo = new TicketInfo();
            tinfo.Ticket = tktId;
            if(ticketLookup.containsKey(tktId))
            {
               tinfo.Warehouse = ticketLookup.get(tktId).Warehouse__c;
            }
            tinfo.MaxSeq = 0;

            for (AggregateResult ar : groupedTicketLookup)  {
                if (tktId == (ID)ar.get(ns + 'Ticket__c')) {
                    tinfo.MaxSeq = (Decimal)ar.get('maxseq');
                    break;
                }
            }
            ticketInfos.put(tktId, tinfo);
        }



        DateTime currDT = System.now();
        Decimal currSeq = Decimal.valueOf(currDT.format('yyyyMMdd.HHmmss'));

        //get the creatable TicketItem fields.
        //Only field in this set might get value from PriceListItem if the field names match with or without 'pbi_' prefix.
        //This is for #76 - Copy fields from price book item to ticket item
        Set<String> tiFields = new Set<String>();
        for(Schema.SObjectField f: Schema.sObjectType.Ticket_Item__c.fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe();

            if (!fd.isAccessible() || !fd.isCreateable() || fd.isCalculated() || fd.isAutoNumber() || fd.isExternalId()|| fd.isUnique())
            {
                continue;
            }
            tiFields.add(fd.getName().toLowerCase());
        }

        Set<String> sameFieldsToCopy = new Set<String>();
        Set<String> pbiPrefixFieldsToCopy = new Set<String>();
        String pbiPrefix = (ns + 'pbi_').toLowerCase();

        Map<String, String> fieldMapping = new Map<String, String>();

        Boolean isInDev = String.isBlank(ns);

        String nsLowercase = ns.toLowerCase();

        for(String f: pbiFields)
        {
            //skip system fields, and Sequence_Number__c.
            //PriceBook has a flag AddTktItemsByPBSeqNum__c to control how the sequence number should be assigned
            //and codes are down below to do that.
            if(!f.endsWith('__c') || f.endsWith('sequence_number__c')) continue;

            String f_no_ns = f.replace(nsLowercase, '');
            String f_with_ns = nsLowercase + f;

System.Debug('f_no_ns'+f_no_ns);
System.Debug('f_with_ns'+f_with_ns);
System.Debug('contains f'+tiFields.contains(f));
System.Debug('contains f_no_ns'+tiFields.contains(f_no_ns));
System.Debug('contains f_with_ns'+tiFields.contains(f_with_ns));

            if(tiFields.contains(f)) //both have ns or both have no ns
            {
               fieldMapping.put(f, f);
            }
            else if(tiFields.contains(f_no_ns)) // tiField has no ns, f has ns
            {
               fieldMapping.put(f, f_no_ns);
            }
            else if(tiFields.contains(f_with_ns)) // tiField has ns, f has no ns
            {
               fieldMapping.put(f, f_with_ns);
            }
            else
            {
                if(isInDev)
                {
                    if(tiFields.contains('pbi_' + f))
                    {
                        fieldMapping.put(f, 'pbi_' + f);
                    }
                }
                else //managed package
                {
                    String tiFieldName = f.startsWith(nsLowercase)? f.replace(nsLowercase, nsLowercase+'pbi_') : ('pbi_' + f);
                    if(tiFields.contains(tiFieldName))
                    {
                        fieldMapping.put(f, tiFieldName);
                    }
                }
            }
        }

        for(Ticket_Item__c ti : itemsToPocess)
        {
            TicketInfo tinfo = ticketInfos.get(ti.Ticket__c);

            Price_Book_Item__c pli = pliMap.get(ti.Price_Book_Item__c);

            for(String f: fieldMapping.keySet())
            {
                String tktField = fieldMapping.get(f);
                //if(ti.get(tktField) == null)
                {
                    ti.put(tktField, pli.get(f));
                }
            }

             //User can never change these values that come from the Catalog on item create
             ti.Catalog_Classification__c = pli.Catalog_Item__r.Classification__c;
             ti.Catalog_Track_Inventory__c = pli.Catalog_Item__r.Track_Inventory__c;
             ti.Catalog_UOM__c = pli.Catalog_Item__r.UOM__c;

             if(recordTypeLookup.containsKey(pli.Catalog_Item__r.Ticket_Item_Record_Type__c))
             {
                ti.RecordTypeId = recordTypeLookup.get(pli.Catalog_Item__r.Ticket_Item_Record_Type__c);
             }

             ti.Catalog_Record_Type__c = pli.Catalog_Item__r.Ticket_Item_Record_Type__c ; //#1711

             ti.Item_Code__c = pli.Catalog_Item_Code__c; //#457
             ti.Surcharge_Rate_Env__c = pli.Price_Book__r.Surcharge_Rate_Env__c;    // maybe one day we will let them change surcharge rates
             ti.Surcharge_Rate_Fuel__c = pli.Price_Book__r.Surcharge_Rate_Fuel__c;  // maybe one day we will let them change surcharge rates

             //All of these items below could be overwritten by the end user in the UI
             //given the right user permissions and config of this item so we check if it has been overriden first
             if(ti.Cost_Plus_Markup_Amount__c == NULL || ti.Cost_Plus_Markup_Amount__c == 0) {
                 ti.Cost_Plus_Markup_Amount__c = pli.Cost_Plus_Markup_Amount__c; }

             if(ti.Cost_Plus_Markup_Percent__c == NULL || ti.Cost_Plus_Markup_Percent__c == 0) {
                 ti.Cost_Plus_Markup_Percent__c = pli.Cost_Plus_Markup_Percent__c; }

             if(ti.Sequence_Number__c == NULL || ti.Sequence_Number__c == 0) {
                if (pli.Price_Book__r.AddTktItemsByPBSeqNum__c) {
                    ti.Sequence_Number__c = pli.Sequence_Number__c;
                } else {
                    ti.Sequence_Number__c = ++tinfo.MaxSeq;
                }
             }

             if(ti.Cost__c == NULL) {
                 ti.Cost__c = pli.Catalog_Item__r.Cost__c;}

             if(ti.Discount_Percent__c == NULL || ti.Discount_Percent__c == 0) {
                 ti.Discount_Percent__c = pli.Discount_Percent__c; }

             if(ti.Warehouse__c == NULL)
             {
                 ti.Warehouse__c = tinfo.Warehouse;
             }

            if(ti.Description__c == NULL)
            {
                if(pli.Description_Override__c == NULL)
                {
                    ti.Description__c = pli.Catalog_Description__c;
                }
                else
                {
                    ti.Description__c = pli.Description_Override__c;
                }
            }

            //default qty to 1 unless the default quantity is set
            if( ti.Input_Qty__c==null)
            {
                ti.Input_Qty__c = (pli.Default_Quantity__c != null) ? pli.Default_Quantity__c : 1;
            }
            //max qty can't be 0 - it can be null tho
            if (ti.PBI_Maximum_Quantity__c == 0)
            {
                ti.PBI_Maximum_Quantity__c = 1;
            }

            if(pbiFields.contains('currencyisocode'))
            {
                ti.put('currencyisocode', pli.get('currencyisocode'));
            }

            if(String.isBlank(ti.SyncID__c))
            {
                ti.SyncID__c = StringUtility.newGuid();
            }
        }
    }

    static void AddChildren(List<Ticket_Item__c> items)
    {
        Set<Id> pliIds = new Set<Id>();
        Set<Id> tktIds = new Set<Id>();

        List<Ticket_Item__c> tktItemsOfInterest = new List<Ticket_Item__c>();
        for(Ticket_Item__c ti : items)
        {
            if(ti.Auto_Added__c!=true &&  ti.Created_in_Mobile__c == false)
            {
                pliIds.add(ti.Price_Book_Item__c);
                tktIds.add(ti.Ticket__c);
                tktItemsOfInterest.add(ti);
            }
        }
        if(pliIds.isEmpty()) return;

        //Map<Id, Ticket__c> tkts = new  Map<Id, Ticket__c>([SELECT Id, Job__r.Price_Book__c FROM Ticket__c WHERE Id IN :tktIds]);

        List<Price_Book_Item__c> childPriceBookItems = [SELECT Id, Price_Book__c, Parent_Price_Book_Item__c, IsArchived__c FROM Price_Book_Item__c WHERE Parent_Price_Book_Item__c IN :pliIds];
        Map<Id, Price_Book_Item__c> pbiLookup = new Map<Id, Price_Book_Item__c>(childPriceBookItems);

        Map<Id, Set<Id>> childItems = new Map<Id, Set<Id>>();
        Set<Id> pbiItemIds = new Set<Id>();
        for(Price_Book_Item__c pbi : childPriceBookItems)
        {
            if(!childItems.containsKey(pbi.Parent_Price_Book_Item__c))
            {
                childItems.put(pbi.Parent_Price_Book_Item__c, new Set<Id>());
            }
            childItems.get(pbi.Parent_Price_Book_Item__c).add(pbi.Id);
            pbiItemIds.add(pbi.Id);
        }

        Map<Id, Set<Id>> tktDisallowedItems = RuleEngineCore.GetDisallowedPriceBookItemsForTickets(tktIds, pliIds, new Map<String, String>());

        List<Ticket_Item__c> newTicketItems = new List<Ticket_Item__c>();

        for(Ticket_Item__c ti : tktItemsOfInterest)
        {
            if(!childItems.containsKey(ti.Price_Book_Item__c)) continue;
            Set<Id> disallowedItems = tktDisallowedItems.containsKey(ti.Ticket__c)? tktDisallowedItems.get(ti.Ticket__c) : new Set<Id>();

            //System.debug('Job.PriceBook: ' + tkts.get(ti.Ticket__c).Job__r.Price_Book__c);

            for(Id pbi : childItems.get(ti.Price_Book_Item__c))
            {
                if(disallowedItems.contains(pbi)) continue;

                //#432
                Price_Book_Item__c pbItem = pbiLookup.get(pbi);
                if (pbItem.IsArchived__c) continue;

                Ticket_Item__c newTktItem = new Ticket_Item__c();
                newTktItem.Price_Book_Item__c = pbi;
                newTktItem.Ticket__c = ti.Ticket__c;
                newTktItem.Parent_Ticket_Item__c = ti.Id;
                newTktItem.SyncID__c = null;
                //newTktItem.Auto_Added__c = ti.Auto_Added__c;

                //add to new ti list
                newTicketItems.add(newTktItem);

                //System.debug('PBI.PriceBook: ' + pbiLookup.get(pbi).Price_Book__c);

            }
        }
        insert newTicketItems;
    }


    private class TicketInfo {
        private ID Ticket { get; set; }
        private ID Warehouse { get; set; }
        private Decimal MaxSeq { get; set; }
    }
}
