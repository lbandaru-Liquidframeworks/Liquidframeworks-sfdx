@RestResource(urlMapping='/CreatePricebookItemsFromCatalogItems/*')
global with sharing class CreatePricebookItemsFromCatalogItems
{       
    @HttpPost
    global static List<Price_Book_Item__c> CreatePricebookItems(Id newPricebookId, List<Id> catalogItemIds, String parentId)
    {
        String ns = UtilityGetNamespace.CurrentNamespace();

        Schema.DescribeSObjectResult rCatalogItem = Catalog_Item__c.sObjectType.getDescribe();
        List<SObjectField> catalogItemFields = rCatalogItem.fields.getMap().values();

        Set<String> pbItemFieldNames = new Set<String>();        
        for(Schema.SObjectField f: Schema.sObjectType.Price_Book_Item__c.fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe(); 

            if (!fd.isAccessible() || !fd.isCreateable() || fd.isCalculated() || fd.isAutoNumber()) 
            {
                continue;
            }

            pbItemFieldNames.add(fd.getName());
        }
        String fieldsStr = String.join(new List<String>(pbItemFieldNames), ',');

        String fields = '';
        String sep = '';
        for(SObjectField fCatalogItem: catalogItemFields)
        {
            DescribeFieldResult dfrCatalogItem = fCatalogItem.getDescribe();
            fields += sep + dfrCatalogItem.getName();
            sep = ',';
        }       

        String soql = 'SELECT ';
        soql += fields;
        soql += ' FROM '+rCatalogItem.getName();
        soql += ' WHERE Id IN :catalogItemIds ';

        List<Catalog_Item__c> sourceCatalogItems = Database.query(soql);
        if(sourceCatalogItems == null) return null;

        Map<String, Catalog_Item__c> sourceCatalogItemsIdLookup = new Map<String, Catalog_Item__c>();
        for(Catalog_Item__c ci : sourceCatalogItems)
        {
            sourceCatalogItemsIdLookup.put(ci.Id, ci);
        }

        Map<Id, Catalog_Item__c> sourceCiLookup = new Map<Id, Catalog_Item__c>(sourceCatalogItems);

        List<Price_Book_Item__c> newPriceBookItems = new List<Price_Book_Item__c>();
        List<Price_Book_Item__c> pbItems = CreatePriceBookItemsUsingCatalogItems(newPricebookId, catalogItemIds, sourceCiLookup, parentId);
        insert pbItems;

        Map<Integer, Id> newPbiLookup = new Map<Integer, Id>();
        //need to preserve order so we can lookup matching quoteItem and ticketItem
        for(Integer i=0; i<pbItems.size(); i++)
        {
            newPbiLookup.put(i, pbItems.get(i).Id);            
        }

        List<Price_Book_Item__c> dbItems = refreshPricebookItemsList(pbItems, fieldsStr);
        Map<Id, Price_Book_Item__c> dbItemLookup = new Map<Id, Price_Book_Item__c>(dbItems);

        pbItems = UpdatePricebookItemsUsingCatalogItems(dbItems, catalogItemIds, sourceCiLookup, 
                        pbItemFieldNames, catalogItemFields,
                        sourceCatalogItemsIdLookup);

        newPriceBookItems.addAll(pbItems);

        return newPriceBookItems;
    }

    public static List<Price_Book_Item__c> refreshPricebookItemsList(List<Price_Book_Item__c> pbItems, String fieldsStr) {
        String ns = UtilityGetNamespace.CurrentNamespace();
        Set<Id> pbItemIds = new Map<Id, Price_Book_Item__c>(pbItems).keySet();
        String pbiSoql = String.format('SELECT {0} FROM {1} WHERE Id IN :pbItemIds', new String[]{fieldsStr, ns+'Price_Book_Item__c'});
        return (List<Price_Book_Item__c>)Database.query(pbiSoql);
    }

    public static List<Price_Book_Item__c> UpdatePricebookItemsUsingCatalogItems(
            List<Price_Book_Item__c> pbItems, List<Id> catalogItemIds, Map<Id, Catalog_Item__c> sourceCiLookup,
            Set<String> pbItemFieldNames, List<SObjectField> catalogItemFields,
            Map<String, Catalog_Item__c> sourceCatalogItemsIdLookup
    ) {
        String ns = UtilityGetNamespace.CurrentNamespace();

        Integer m = 0;
        Map<String, String> newIdToOriginalIdLookup = new Map<String, String>();
        for(String origId : sourceCatalogItemsIdLookup.keySet())
        {
            Price_Book_Item__c newPbi = pbItems.get(m);
            newIdToOriginalIdLookup.put(origId, newPbi.Id);

            m++;
        }

        Map<String, Price_Book_Item__c> targetPbItemIdsIdLookup = new Map<String, Price_Book_Item__c>();
        for(Price_Book_Item__c dbpbi : pbItems)
        {
            targetPbItemIdsIdLookup.put(dbpbi.Id, dbpbi);
        }

        Map<Id, Price_Book_Item__c> pbiLookup = new Map<Id, Price_Book_Item__c>(pbItems);
        //Map<Id, Price_Book_Item__c> tiToPbiLookup = new Map<Id, Ticket_Item__c>();

        for(Id catalogItemId: catalogItemIds) {
            Catalog_Item__c sourceCatalogItem = sourceCiLookup.get(catalogItemId);
            String targetId = newIdToOriginalIdLookup.get(sourceCatalogItem.Id);
            Price_Book_Item__c targetPbItem = targetPbItemIdsIdLookup.get(targetId);

            //copy fields
            for(SObjectField fCatalogItem: catalogItemFields)
            {
                DescribeFieldResult dfrCatalogItem = fCatalogItem.getDescribe();
                String origf = dfrCatalogItem.getName();
                String f = ns + origf.replace(ns,''); //make sure fieldname has namespace
                String nf = origf.replace(ns,'');

                //skip system fields, and Sequence_Number__c. 
                //PriceBook has a flag AddTktItemsByPBSeqNum__c to control how the sequence number should be assigned 
                //and codes are down below to do that.
                if(!f.endsWith('__c')) continue;

                if(pbItemFieldNames.contains(f)) 
                {
                    targetPbItem.put(f, sourceCatalogItem.get(origf));
                } else if(pbItemFieldNames.contains(nf)) 
                {
                    targetPbItem.put(nf, sourceCatalogItem.get(origf));
                }
            }
        }

        update pbItems;

        return pbItems;
    }

    public static List<Price_Book_Item__c> CreatePriceBookItemsUsingCatalogItems(Id newPricebookId, List<Id> catalogItemIds, Map<Id, Catalog_Item__c> ciLookup, String parentId) {
        List<Price_Book_Item__c> pbItems = new List<Price_Book_Item__c>();

        for(Id catalogItemId: catalogItemIds) {
            Catalog_Item__c ci = ciLookup.get(catalogItemId);
            String recName = Schema.SObjectType.Catalog_Item__c.getRecordTypeInfosById().get(ci.RecordTypeId).getName();

            RecordTypeInfo recordInfo = Schema.SObjectType.Price_Book_Item__c.getRecordTypeInfosByName().get(recName);
            if (recordInfo != null) {
                ID recId = recordInfo.getRecordTypeId();
                Price_Book_Item__c pbItem  = (Price_Book_Item__c)Price_Book_Item__c.sObjectType.newSObject(recId, true);
                pbItem.Price_Book__c = newPricebookId;
                pbItem.Catalog_Item__c = catalogItemId;

                if (!String.isBlank(parentId)) {
                    //pbItem.Parent_Price_Book_Item__r = new Price_Book_Item__c(Id = parentId);
                    pbItem.Parent_Price_Book_Item__c = parentId;
                }

                pbItems.add(pbItem);
            }
        }

        return pbItems;
    }
}