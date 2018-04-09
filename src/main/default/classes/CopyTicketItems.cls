@RestResource(urlMapping='/CopyTicketItems/*')
global with sharing class CopyTicketItems
{
    @HttpPost
    global static List<Ticket_Item__c> CopyTicketItems(Id newTicketId, List<Id> ticketItemIds, Boolean honorSequenceNumber, Decimal nextSequenceNumber)
    {

        RuleEngineCore.RuleEngineInProgress = true;

        String ns = UtilityGetNamespace.CurrentNamespace();

        Schema.DescribeSObjectResult rTktItem = Ticket_Item__c.sObjectType.getDescribe();
        if(!rTktItem.isAccessible() || !rTktItem.isCreateable()) {
            RuleEngineCore.RuleEngineInProgress = false;
            return null;
        }

        List<SObjectField> tktItemFields = rTktItem.fields.getMap().values();

        Set<String> tktItemFieldNames = new Set<String>();
        for(Schema.SObjectField f: Schema.sObjectType.Ticket_Item__c.fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe();

            //if (!fd.isAccessible() || !fd.isCreateable() || fd.isCalculated() || fd.isAutoNumber() || fd.isExternalId()|| fd.isUnique())
            //{
            //    continue;
            //}

            if (fd.getName().endsWith('Sequence_Number__c') && honorSequenceNumber) continue;

            tktItemFieldNames.add(fd.getName());
        }
        String fieldsStr = String.join(new List<String>(tktItemFieldNames), ',');

        String fields = '';
        String sep = '';
        for(SObjectField fTktItem: tktItemFields)
        {
            DescribeFieldResult dfrTktItem = fTktItem.getDescribe();
            //if(!dfrQuoteItem.isCreateable() || dfrQuoteItem.isUnique()) continue;
            if (dfrTktItem.getName().endsWith('Sequence_Number__c') && honorSequenceNumber) continue;

            fields += sep + dfrTktItem.getName();
            sep = ',';
        }

        String soql = 'SELECT ';
        soql += fields;
        soql += ' , (SELECT ';
        soql += fields;
        soql += ' FROM '+ns+'Ticket_Items__r) ';
        soql += ' FROM '+rTktItem.getName();
        soql += ' WHERE Id IN :ticketItemIds ';

        List<Ticket_Item__c> sourceTktItems = Database.query(soql);
        if(sourceTktItems == null) {
            RuleEngineCore.RuleEngineInProgress = false;
            return null;
        }

        Map<String, Ticket_Item__c> sourceTktItemsSyncIdLookup = new Map<String, Ticket_Item__c>();
        for(Ticket_Item__c ti : sourceTktItems)
        {
            sourceTktItemsSyncIdLookup.put(ti.SyncID__c, ti);
        }


        Map<Id, Ticket_Item__c> sourceTiLookup = new Map<Id, Ticket_Item__c>(sourceTktItems);

        List<Id> parentTktItemIds = new List<Id>();
        Map<String, Ticket_Item__c> parentTktItemIdsSyncIdLookup = new Map<String, Ticket_Item__c>();
        Map<String, Ticket_Item__c> childTktItemIdsSyncIdLookup = new Map<String, Ticket_Item__c>();

        List<Id> childTktItemIds = new List<Id>();
        for(Ticket_Item__c tktItem: sourceTktItems) {
            if (tktItem.Parent_Ticket_Item__c != null) {
                childTktItemIds.add(tktItem.Id);
                childTktItemIdsSyncIdLookup.put(tktItem.SyncID__c, tktItem);
            } else {
                parentTktItemIds.add(tktItem.Id);
                parentTktItemIdsSyncIdLookup.put(tktItem.SyncID__c, tktItem);
            }
        }

        List<Ticket_Item__c> newticketItems = new List<Ticket_Item__c>();
        List<Ticket_Item__c> parentTktItems = CreateTicketItemsUsingPriceBookItems(newTicketId, parentTktItemIds, sourceTiLookup, '');
        insert parentTktItems;

        Map<Integer, Id> newTiLookup = new Map<Integer, Id>();
        //need to preserve order so we can lookup matching quoteItem and ticketItem
        for(Integer i=0; i<parentTktItems.size(); i++)
        {
            newTiLookup.put(i, parentTktItems.get(i).Id);
        }

        List<Ticket_Item__c> dbItems = refreshTktItemsList(parentTktItems, fieldsStr);
        Map<Id, Ticket_Item__c> dbItemLookup = new Map<Id, Ticket_Item__c>(dbItems);

        parentTktItems = UpdateTicketItemsUsingTicketItems(dbItems, parentTktItemIds, sourceTiLookup,
                        honorSequenceNumber, nextSequenceNumber, tktItemFieldNames, tktItemFields,
                        parentTktItemIdsSyncIdLookup);

        newticketItems.addAll(parentTktItems);

        Integer i =0;
        for(Id tktItemId: parentTktItemIds) {
            Ticket_Item__c ti = sourceTiLookup.get(tktItemId);
            Ticket_Item__c paItem = dbItemLookup.get(newTiLookup.get(i)); //paItems[i];

            if (ti.Ticket_Items__r != null) {
                List<Ticket_Item__c> sourceChildTktItems = ti.Ticket_Items__r;

                Map<String, Ticket_Item__c> sourceChildTktItemsSyncIds = new Map<String, Ticket_Item__c>();
                Map<Id, Ticket_Item__c> tiChildLookup = new Map<Id, Ticket_Item__c>(sourceChildTktItems);
                List<Id> sourceChildTktItemsIds = new List<Id>();
                for(Ticket_Item__c ti2: sourceChildTktItems) {

                    if (sourceTiLookup.get(ti2.Id) != null) {
                        // if one of the current child tktItem.Ids was in the list of selected children,
                        // then remove it from the selected children list so it isn't processed twice
                        for (Integer j = childTktItemIds.size() - 1; j >= 0 ; --j) {
                            Id childTktItemId = childTktItemIds.get(j);
                            if (childTktItemId == ti2.Id) {
                                childTktItemIds.remove(j);
                            }
                        }

                        childTktItemIdsSyncIdLookup.remove(ti2.SyncID__c);
                    }

                    sourceChildTktItemsIds.add(ti2.Id);
                    sourceChildTktItemsSyncIds.put(ti2.SyncID__c, ti2);
                }


                List<Ticket_Item__c> childItems = CreateTicketItemsUsingPriceBookItems(newTicketId, sourceChildTktItemsIds, tiChildLookup, paItem.SyncID__c);
                insert childItems;

                dbItems = refreshTktItemsList(childItems, fieldsStr);

                dbItems = UpdateTicketItemsUsingTicketItems(dbItems, sourceChildTktItemsIds, tiChildLookup,
                                honorSequenceNumber, nextSequenceNumber, tktItemFieldNames, tktItemFields,
                                sourceChildTktItemsSyncIds);

                newticketItems.addAll(dbItems);
            }

            i++;
        }

        if (childTktItemIds.size() > 0) {
            List<Ticket_Item__c> childTktItems = CreateTicketItemsUsingPriceBookItems(newTicketId, childTktItemIds, sourceTiLookup, '');
            insert childTktItems;

            dbItems = refreshTktItemsList(childTktItems, fieldsStr);

            dbItems = UpdateTicketItemsUsingTicketItems(dbItems, childTktItemIds, sourceTiLookup,
                            honorSequenceNumber, nextSequenceNumber, tktItemFieldNames, tktItemFields,
                            childTktItemIdsSyncIdLookup);

            newticketItems.addAll(dbItems);

        }

        RuleEngineCore.RuleEngineInProgress = false;

        return newticketItems;
    }

    public static List<Ticket_Item__c> refreshTktItemsList(List<Ticket_Item__c> tktItems, String fieldsStr) {
        String ns = UtilityGetNamespace.CurrentNamespace();
        Set<Id> tktItemIds = new Map<Id, Ticket_Item__c>(tktItems).keySet();
        String tiSoql = String.format('SELECT {0} FROM {1} WHERE Id IN :tktItemIds', new String[]{fieldsStr, ns+'Ticket_Item__c'});
        return (List<Ticket_Item__c>)Database.query(tiSoql);
    }

    public static List<Ticket_Item__c> UpdateTicketItemsUsingTicketItems(
            List<Ticket_Item__c> ticketItems, List<Id> tktItemIds, Map<Id, Ticket_Item__c> sourceTiLookup,
            Boolean honorSequenceNumber, Decimal nextSequenceNumber,
            Set<String> tktItemFieldNames, List<SObjectField> tktItemFields,
            Map<String, Ticket_Item__c> sourceTiIdsSyncIdLookup
    ) {
        String ns = UtilityGetNamespace.CurrentNamespace();
        String ticketItemExcludeFieldSetName = 'FX_Ticket_Item_Copy_Exclusion';

        String ticketItemObjName = ns+'Ticket_Item__c';
        Schema.FieldSet fieldset = MetadataHelper.GetFieldSet(ticketItemObjName, ticketItemExcludeFieldSetName);
        List<Schema.FieldSetMember> excludeFields = new List<Schema.FieldSetMember>();

        if (fieldSet != null) excludeFields = fieldSet.getFields();

        Set<String> excludedFields = new Set<String>();
        for(Schema.FieldSetMember field: excludeFields) {
            excludedFields.add(field.getFieldPath());
        }

        Integer m = 0;
        Map<String, String> newSyncIdToOriginalSyncIdLookup = new Map<String, String>();
        for(String origSyncId : sourceTiIdsSyncIdLookup.keySet())
        {
            Ticket_Item__c newTi = ticketItems.get(m);
            newSyncIdToOriginalSyncIdLookup.put(origSyncId, newTi.SyncID__c);

            m++;
        }

        Map<String, Ticket_Item__c> targetTktItemIdsSyncIdLookup = new Map<String, Ticket_Item__c>();
        for(Ticket_Item__c dbti : ticketItems)
        {
            targetTktItemIdsSyncIdLookup.put(dbti.SyncID__c, dbti);
        }

        Map<Id, Ticket_Item__c> tiLookup = new Map<Id, Ticket_Item__c>(ticketItems);
        Map<String, Ticket_Item__c> tiToPbiLookup = new Map<String, Ticket_Item__c>();

        for(Id tktItemId: tktItemIds) {
            Ticket_Item__c sourceTktItem = sourceTiLookup.get(tktItemId);
            String targetSyncId = newSyncIdToOriginalSyncIdLookup.get(sourceTktItem.SyncID__c);
            Ticket_Item__c targetTktItem = targetTktItemIdsSyncIdLookup.get(targetSyncId);

            if (targetTktItem == null) continue;

            //copy fields
            for(SObjectField fTktItem: tktItemFields)
            {
                DescribeFieldResult dfrTktItem = fTktItem.getDescribe();
                String origf = dfrTktItem.getName();
                String f = ns + origf.replace(ns,''); //make sure fieldname has namespace
                String nf = origf.replace(ns,'');

                //skip system fields, and Sequence_Number__c.
                //PriceBook has a flag AddTktItemsByPBSeqNum__c to control how the sequence number should be assigned
                //and codes are down below to do that.
                if(!f.endsWith('__c') || f.endsWith('Sequence_Number__c') ||
                    f.endsWith('Description__c') ||
                    f.endsWith('Discount_Percent__c') ||
                    f.endsWith('Price__c') ||
                    f.endsWith('Parent_Ticket_Item__c') ||
                    f.endsWith('SyncId__c') ) continue;

                if (!dfrTktItem.isUpdateable() || !dfrTktItem.isAccessible() || !dfrTktItem.isCreateable() || dfrTktItem.isCalculated() ||
                    dfrTktItem.isAutoNumber() || dfrTktItem.isExternalId()|| dfrTktItem.isUnique())
                {
                    continue;
                }

                if (excludedFields.contains(f) || excludedFields.contains(nf)) continue;

                if(tktItemFieldNames.contains(f))
                {
                    targetTktItem.put(f, sourceTktItem.get(origf));
                } else if(tktItemFieldNames.contains(nf))
                {
                    targetTktItem.put(nf, sourceTktItem.get(origf));
                }
            }

            targetTktItem.Created_in_Mobile__c = false;

            if ((sourceTktItem.PBI_Locked_Description__c == false) && !excludedFields.contains(ns+'Description__c')) {
                targetTktItem.Description__c = sourceTktItem.Description__c;
            }

            if ((sourceTktItem.PBI_Locked_Discount__c == false) && !excludedFields.contains(ns+'Discount_Percent__c')) {
                targetTktItem.Discount_Percent__c = sourceTktItem.Discount_Percent__c;
            }

            if (!(targetTktItem.PBI_Locked_Price_Markup__c == true || targetTktItem.On_Standby__c == true) && !excludedFields.contains(ns+'Price__c')) {
                targetTktItem.Price__c = sourceTktItem.Price__c;
            }

            if (!honorSequenceNumber) {
                targetTktItem.Sequence_Number__c = nextSequenceNumber++;
            }

            targetTktItem.Invoice_Item__c = null; //#1062
            targetTktItem.PBI_Required_Item__c = false;
            targetTktItem.Rule_Required_Item__c = false;
            targetTktItem.Auto_Added__c = false;

            nextSequenceNumber++;
        }

        update ticketItems;

        return ticketItems;
    }

    public static List<Ticket_Item__c> CreateTicketItemsUsingPriceBookItems(Id newTicketId, List<Id> tktItemIds,
            Map<Id, Ticket_Item__c> tiLookup, String parentSyncId) {

        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();

        for(Id tktItemId: tktItemIds) {
            Ticket_Item__c ti = tiLookup.get(tktItemId);
            ID recId = ti.RecordTypeId;

            Ticket_Item__c tktItem  = (Ticket_Item__c)Ticket_Item__c.sObjectType.newSObject(recId, true);
            tktItem.Ticket__c = newTicketId;
            tktItem.Price_Book_Item__c = ti.Price_Book_Item__c;
            tktItem.SyncID__c = StringUtility.newGuid();

            if (!String.isBlank(parentSyncId)) {
                tktItem.Parent_Ticket_Item__r = new Ticket_Item__c(SyncID__c = parentSyncId);
            } else {
                if (ti.Parent_Ticket_Item__c != null) {
                    tktItem.Parent_Ticket_Item__c = ti.Parent_Ticket_Item__c;
                }
            }

            tktItems.add(tktItem);
        }

        return tktItems;
    }
}
