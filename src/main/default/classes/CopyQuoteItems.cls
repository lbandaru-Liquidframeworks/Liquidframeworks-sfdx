@RestResource(urlMapping='/CopyQuoteItems/*')
global with sharing class CopyQuoteItems
{       
    @HttpPost
    global static List<Quote_Item__c> CopyQuoteItems(Id newQuoteId, List<Id> quoteItemIds, Boolean honorSequenceNumber, Decimal nextSequenceNumber)
    {

        RuleEngineCore.RuleEngineInProgress = true;

        String ns = UtilityGetNamespace.CurrentNamespace();

        Schema.DescribeSObjectResult rQtItem = Quote_Item__c.sObjectType.getDescribe();
        if(!rQtItem.isAccessible() || !rQtItem.isCreateable()) {
            RuleEngineCore.RuleEngineInProgress = false;
            return null;
        }

        List<SObjectField> qtItemFields = rQtItem.fields.getMap().values();

        Set<String> qtItemFieldNames = new Set<String>();        
        for(Schema.SObjectField f: Schema.sObjectType.Quote_Item__c.fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe(); 

            //if (!fd.isAccessible() || !fd.isCreateable() || fd.isCalculated() || fd.isAutoNumber() || fd.isExternalId()|| fd.isUnique()) 
            //{
            //    continue;
            //}

            if (fd.getName().endsWith('Sequence_Number__c') && honorSequenceNumber) continue;

            qtItemFieldNames.add(fd.getName());
        }
        String fieldsStr = String.join(new List<String>(qtItemFieldNames), ',');

        String fields = '';
        String sep = '';
        for(SObjectField fQtItem: qtItemFields)
        {
            DescribeFieldResult dfrQtItem = fQtItem.getDescribe();
            //if(!dfrQuoteItem.isCreateable() || dfrQuoteItem.isUnique()) continue;
            if (dfrQtItem.getName().endsWith('Sequence_Number__c') && honorSequenceNumber) continue;

            fields += sep + dfrQtItem.getName();
            sep = ',';
        }       

        String soql = 'SELECT ';
        soql += fields;
        soql += ' , (SELECT ';
        soql += fields;
        soql += ' FROM '+ns+'Quote_Items__r) ';
        soql += ' FROM '+rQtItem.getName();
        soql += ' WHERE Id IN :quoteItemIds ';

        List<Quote_Item__c> sourceQtItems = Database.query(soql);
        if(sourceQtItems == null) {
            RuleEngineCore.RuleEngineInProgress = false;
            return null;
        }

        Map<String, Quote_Item__c> sourceQtItemsSyncIdLookup = new Map<String, Quote_Item__c>();
        for(Quote_Item__c qi : sourceQtItems)
        {
            sourceQtItemsSyncIdLookup.put(qi.SyncID__c, qi);
        }


        Map<Id, Quote_Item__c> sourceQiLookup = new Map<Id, Quote_Item__c>(sourceQtItems);

        List<Id> parentQtItemIds = new List<Id>();
        Map<String, Quote_Item__c> parentQtItemIdsSyncIdLookup = new Map<String, Quote_Item__c>();
        Map<String, Quote_Item__c> childQtItemIdsSyncIdLookup = new Map<String, Quote_Item__c>();

        List<Id> childQtItemIds = new List<Id>();
        for(Quote_Item__c qtItem: sourceQtItems) {
            if (qtItem.Parent_Quote_Item__c != null) {
                childQtItemIds.add(qtItem.Id);
                childQtItemIdsSyncIdLookup.put(qtItem.SyncID__c, qtItem);
            } else {
                parentQtItemIds.add(qtItem.Id);
                parentQtItemIdsSyncIdLookup.put(qtItem.SyncID__c, qtItem);
            }
        }

        List<Quote_Item__c> newquoteItems = new List<Quote_Item__c>();
        List<Quote_Item__c> parentQtItems = CreateQuoteItemsUsingPriceBookItems(newQuoteId, parentQtItemIds, sourceQiLookup, '');
        insert parentQtItems;

        Map<Integer, Id> newQiLookup = new Map<Integer, Id>();
        //need to preserve order so we can lookup matching quoteItem and quoteItem
        for(Integer i=0; i<parentQtItems.size(); i++)
        {
            newQiLookup.put(i, parentQtItems.get(i).Id);            
        }

        List<Quote_Item__c> dbItems = refreshQtItemsList(parentQtItems, fieldsStr);
        Map<Id, Quote_Item__c> dbItemLookup = new Map<Id, Quote_Item__c>(dbItems);

        parentQtItems = UpdateQuoteItemsUsingQuoteItems(dbItems, parentQtItemIds, sourceQiLookup, 
                        honorSequenceNumber, nextSequenceNumber, qtItemFieldNames, qtItemFields, 
                        parentQtItemIdsSyncIdLookup);

        newquoteItems.addAll(parentQtItems);

        Integer i =0;
        for(Id qtItemId: parentQtItemIds) {
            Quote_Item__c qi = sourceQiLookup.get(qtItemId);
            Quote_Item__c paItem = dbItemLookup.get(newQiLookup.get(i)); //paItems[i];

            if (qi.Quote_Items__r != null) {
                List<Quote_Item__c> sourceChildQtItems = qi.Quote_Items__r;

                Map<String, Quote_Item__c> sourceChildQtItemsSyncIds = new Map<String, Quote_Item__c>();
                Map<Id, Quote_Item__c> qiChildLookup = new Map<Id, Quote_Item__c>(sourceChildQtItems);
                List<Id> sourceChildQtItemsIds = new List<Id>();
                for(Quote_Item__c qi2: sourceChildQtItems) {

                    if (sourceQiLookup.get(qi2.Id) != null) {
                        // if one of the current child qtItem.Ids was in the list of selected children, 
                        // then remove it from the selected children list so it isn't processed twice
                        for (Integer j = childQtItemIds.size() - 1; j >= 0 ; --j) {
                            Id childQtItemId = childQtItemIds.get(j);
                            if (childQtItemId == qi2.Id) {
                                childQtItemIds.remove(j);
                            }
                        }

                        childQtItemIdsSyncIdLookup.remove(qi2.SyncID__c);
                    }

                    sourceChildQtItemsIds.add(qi2.Id);
                    sourceChildQtItemsSyncIds.put(qi2.SyncID__c, qi2);
                }


                List<Quote_Item__c> childItems = CreateQuoteItemsUsingPriceBookItems(newQuoteId, sourceChildQtItemsIds, qiChildLookup, paItem.SyncID__c);
                insert childItems;

                dbItems = refreshQtItemsList(childItems, fieldsStr);

                dbItems = UpdateQuoteItemsUsingQuoteItems(dbItems, sourceChildQtItemsIds, qiChildLookup, 
                                honorSequenceNumber, nextSequenceNumber, qtItemFieldNames, qtItemFields, 
                                sourceChildQtItemsSyncIds);

                newquoteItems.addAll(dbItems);
            }

            i++;
        }

        if (childQtItemIds.size() > 0) {
            List<Quote_Item__c> childQtItems = CreateQuoteItemsUsingPriceBookItems(newQuoteId, childQtItemIds, sourceQiLookup, '');
            insert childQtItems;

            dbItems = refreshQtItemsList(childQtItems, fieldsStr);

            dbItems = UpdateQuoteItemsUsingQuoteItems(dbItems, childQtItemIds, sourceQiLookup, 
                            honorSequenceNumber, nextSequenceNumber, qtItemFieldNames, qtItemFields, 
                            childQtItemIdsSyncIdLookup);

            newquoteItems.addAll(dbItems);

        }

        RuleEngineCore.RuleEngineInProgress = false;

        return newquoteItems;
    }

    public static List<Quote_Item__c> refreshQtItemsList(List<Quote_Item__c> qtItems, String fieldsStr) {
        String ns = UtilityGetNamespace.CurrentNamespace();
        Set<Id> qtItemIds = new Map<Id, Quote_Item__c>(qtItems).keySet();
        String qiSoql = String.format('SELECT {0} FROM {1} WHERE Id IN :qtItemIds', new String[]{fieldsStr, ns+'Quote_Item__c'});
        return (List<Quote_Item__c>)Database.query(qiSoql);
    }

    public static List<Quote_Item__c> UpdateQuoteItemsUsingQuoteItems(
            List<Quote_Item__c> quoteItems, List<Id> qtItemIds, Map<Id, Quote_Item__c> sourceQiLookup,
            Boolean honorSequenceNumber, Decimal nextSequenceNumber, 
            Set<String> qtItemFieldNames, List<SObjectField> qtItemFields,
            Map<String, Quote_Item__c> sourceQiIdsSyncIdLookup
    ) {
        String ns = UtilityGetNamespace.CurrentNamespace();
        String quoteItemExcludeFieldSetName = 'FX_Quote_Item_Copy_Exclusion';

        String quoteItemObjName = ns+'Quote_Item__c';
        Schema.FieldSet fieldset = MetadataHelper.GetFieldSet(quoteItemObjName, quoteItemExcludeFieldSetName);
        List<Schema.FieldSetMember> excludeFields = new List<Schema.FieldSetMember>();

        if (fieldSet != null) excludeFields = fieldSet.getFields();
        
        Set<String> excludedFields = new Set<String>();    
        for(Schema.FieldSetMember field: excludeFields) {
            excludedFields.add(field.getFieldPath());
        }    

        Integer m = 0;
        Map<String, String> newSyncIdToOriginalSyncIdLookup = new Map<String, String>();
        for(String origSyncId : sourceQiIdsSyncIdLookup.keySet())
        {
            Quote_Item__c newQi = quoteItems.get(m);
            newSyncIdToOriginalSyncIdLookup.put(origSyncId, newQi.SyncID__c);

            m++;
        }

        Map<String, Quote_Item__c> targetQtItemIdsSyncIdLookup = new Map<String, Quote_Item__c>();
        for(Quote_Item__c dbqi : quoteItems)
        {
            targetQtItemIdsSyncIdLookup.put(dbqi.SyncID__c, dbqi);
        }

        for(Id qtItemId: qtItemIds) {
            Quote_Item__c sourceQtItem = sourceQiLookup.get(qtItemId);
            String targetSyncId = newSyncIdToOriginalSyncIdLookup.get(sourceQtItem.SyncID__c);
            Quote_Item__c targetQtItem = targetQtItemIdsSyncIdLookup.get(targetSyncId);

            if (targetQtItem == null) continue;

            //copy fields
            for(SObjectField fQtItem: qtItemFields)
            {
                DescribeFieldResult dfrQtItem = fQtItem.getDescribe();
                String origf = dfrQtItem.getName();
                String f = ns + origf.replace(ns,''); //make sure fieldname has namespace
                String nf = origf.replace(ns,'');

                //skip system fields, and Sequence_Number__c. 
                //PriceBook has a flag AddQtItemsByPBSeqNum__c to control how the sequence number should be assigned 
                //and codes are down below to do that.
                if(!f.endsWith('__c') || f.endsWith('Sequence_Number__c') || 
                    f.endsWith('Description__c') || 
                    f.endsWith('Discount_Percent__c') || 
                    f.endsWith('Parent_Quote_Item__c') || 
                    f.endsWith('SyncId__c') ) continue;

                if (!dfrQtItem.isUpdateable() || !dfrQtItem.isAccessible() || !dfrQtItem.isCreateable() || dfrQtItem.isCalculated() || 
                    dfrQtItem.isAutoNumber() || dfrQtItem.isExternalId()|| dfrQtItem.isUnique()) 
                {
                    continue;
                }

                if (excludedFields.contains(f) || excludedFields.contains(nf)) continue;

                if(qtItemFieldNames.contains(f)) 
                {
                    targetQtItem.put(f, sourceQtItem.get(origf));
                } else if(qtItemFieldNames.contains(nf)) 
                {
                    targetQtItem.put(nf, sourceQtItem.get(origf));
                }
            }

            if ((sourceQtItem.PBI_Locked_Description__c == false)  && !excludedFields.contains(ns+'Description__c')) {
                targetQtItem.Description__c = sourceQtItem.Description__c;
            }

            if ((sourceQtItem.PBI_Locked_Discount__c == false) && !excludedFields.contains(ns+'Discount_Percent__c')) {
                targetQtItem.Discount_Percent__c = sourceQtItem.Discount_Percent__c;
            }

            if (!honorSequenceNumber) {
                targetQtItem.Sequence_Number__c = nextSequenceNumber++;
            }

            targetQtItem.Rule_Required_Item__c = false;
            targetQtItem.Auto_Added__c = false;

            nextSequenceNumber++;
        }

        update quoteItems;

        return quoteItems;
    }

    public static List<Quote_Item__c> CreateQuoteItemsUsingPriceBookItems(Id newQuoteId, List<Id> qtItemIds, 
            Map<Id, Quote_Item__c> qiLookup, String parentSyncId) {

        List<Quote_Item__c> qtItems = new List<Quote_Item__c>();

        for(Id qtItemId: qtItemIds) {
            Quote_Item__c qi = qiLookup.get(qtItemId);
            ID recId = qi.RecordTypeId;

            Quote_Item__c qtItem  = (Quote_Item__c)Quote_Item__c.sObjectType.newSObject(recId, true);
            qtItem.Quote__c = newQuoteId;
            qtItem.Price_Book_Item__c = qi.Price_Book_Item__c;
            qtItem.SyncID__c = StringUtility.newGuid();

            if (!String.isBlank(parentSyncId)) {
                qtItem.Parent_Quote_Item__r = new Quote_Item__c(SyncID__c = parentSyncId);
            } else {
                if (qi.Parent_Quote_Item__c != null) {
                    qtItem.Parent_Quote_Item__c = qi.Parent_Quote_Item__c;
                }
            }

            qtItems.add(qtItem);
        }

        return qtItems;
    }    
}