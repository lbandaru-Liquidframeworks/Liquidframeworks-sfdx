public class QuoteItemHandler
{
	public static void InitQuoteItems(List<Quote_Item__c> items)
	{
		Set<Id> pbiIds = new Set<Id>();
		Set<Id> quoteIds = new Set<Id>();
		for(Quote_Item__c obj: items)
		{
			pbiIds.add(obj.Price_Book_Item__c);
			quoteIds.add(obj.Quote__c);
		}
		String ns = StringUtility.FXNamespace();	

		List<String> soqlFields = new List<String>();
		String[] params = new String[]{ns};
		
		soqlFields.add(String.format('{0}Price_Book__r.{0}AddTktItemsByPBSeqNum__c', params));
		soqlFields.add(String.format('{0}Catalog_Item__r.{0}Description__c', params));
        soqlFields.add(String.format('{0}Catalog_Item__r.{0}Ticket_Item_Record_Type__c', params));
        soqlFields.add(String.format('{0}Catalog_Item__r.{0}UOM__c', params));

		Set<String> priceBookItemFields = new Set<String>();

		for(Schema.SObjectField f: Schema.sObjectType.Price_Book_Item__c.fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe();    
            String fName = fd.getName();         
            soqlFields.add(fName);
            if(fd.isNameField() || fd.isCustom() || fName == 'CurrencyIsoCode')
            {
            	priceBookItemFields.add(fName);
            }
        }

        String soql = String.format('SELECT {1} FROM {0}Price_Book_Item__c WHERE Id IN :pbiIds AND IsDeleted=false', new String[]{ns, String.join(soqlFields, ',')});

        Map<Id, Price_Book_Item__c> pbiItems = new Map<Id, Price_Book_Item__c>((List<Price_Book_Item__c>)Database.query(soql));

        
        Map<Id, Decimal> quoteItemMaxSequenceNumber = new Map<Id, Decimal>();
        
        String quoteFieldName = ns + 'Quote__c';

        for(AggregateResult ar : [SELECT Quote__c, max(Sequence_Number__c) maxseq FROM Quote_Item__c WHERE IsDeleted=false AND Quote__c in :quoteIds GROUP BY Quote__c])
        {
        	quoteItemMaxSequenceNumber.put((Id)ar.get(quoteFieldName), (Decimal)ar.get('maxseq'));
        }	

        Map<String, String> fieldMapping = GetQuoteItemFieldMapping(ns, priceBookItemFields);
        Set<String> qiFields = fieldMapping.keySet();

        String objType = ns  + 'Quote_Item__c';
        
        Map<string, Id> recordTypeLookup = new Map<string, Id>();           
        for(RecordType rt : [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType=:objType])
        {   
            recordTypeLookup.put(rt.Name, rt.Id);
            recordTypeLookup.put(rt.DeveloperName, rt.Id);
        }


        for(Quote_Item__c qi : items)
        {  
        	if(String.isBlank(qi.SyncID__c))  
            {      
                qi.SyncID__c = StringUtility.newGuid();
            }

        	if(pbiItems.containsKey(qi.Price_Book_Item__c)) 
        	{
	            Price_Book_Item__c pli = pbiItems.get(qi.Price_Book_Item__c);
	            for(String f: qiFields)
	            {
	            	qi.put(f, pli.get(fieldMapping.get(f)));                
	            }
	            if(qi.Description__c == NULL) 
	            {
	            	qi.Description__c = String.isBlank(pli.Description_Override__c)? pli.Catalog_Description__c : pli.Description_Override__c;               
	            } 

	            if ((qi.Sequence_Number__c == NULL || qi.Sequence_Number__c == 0) && pli.Price_Book__r.AddTktItemsByPBSeqNum__c == true) 
                {
                    qi.Sequence_Number__c = pli.Sequence_Number__c; 
                } 

                if( qi.Qty__c == null)
                {
                    qi.Qty__c = (pli.Default_Quantity__c != null) ? pli.Default_Quantity__c : 1;
                }
                if (qi.PBI_Maximum_Quantity__c == 0) 
                {
                    qi.PBI_Maximum_Quantity__c = 1;
                }
                qi.Catalog_UOM__c = pli.Catalog_Item__r.UOM__c;

                if(recordTypeLookup.containsKey(pli.Catalog_Item__r.Ticket_Item_Record_Type__c)) 
                {      
                    qi.RecordTypeId = recordTypeLookup.get(pli.Catalog_Item__r.Ticket_Item_Record_Type__c);
                }
            }     


            if(qi.Sequence_Number__c == NULL || qi.Sequence_Number__c == 0) 
            {                
                if(quoteItemMaxSequenceNumber.containsKey(qi.Quote__c))
                {
                    qi.Sequence_Number__c = quoteItemMaxSequenceNumber.get(qi.Quote__c) + 1;
                }
                else
                {
                	qi.Sequence_Number__c = 1;
                }               
            }
            quoteItemMaxSequenceNumber.put(qi.Quote__c, qi.Sequence_Number__c);
        }
	}

	public static void AddChildren(List<Quote_Item__c> items) 
    {
        Set<Id> pliIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();

        List<Quote_Item__c> itemsOfInterest = new List<Quote_Item__c>();

        String ns = StringUtility.FXNamespace();

        

        for(Quote_Item__c obj : items)
        {
            if(obj.Auto_Added__c == true || obj.Created_in_Mobile__c == true) continue;

            pliIds.add(obj.Price_Book_Item__c);
            quoteIds.add(obj.Quote__c);              
            itemsOfInterest.add(obj);            
        }
        if(itemsOfInterest.isEmpty()) return;       

        String quoteItemTypeName = ns + 'Quote_Item__c';
        Map<String, Id> quoteItemRecordTypeLookup = new Map<String, Id>();
        for(RecordType rt: [SELECT Id, Name, DeveloperName FROM RecordType WHERE IsActive=true AND  SobjectType=:quoteItemTypeName])
        {
        	quoteItemRecordTypeLookup.put(rt.Name, rt.Id);
        	quoteItemRecordTypeLookup.put(rt.DeveloperName, rt.Id);
        }


        List<Price_Book_Item__c> childPriceBookItems = [SELECT Id, Price_Book__c, Catalog_Item__r.Ticket_Item_Record_Type__c, Parent_Price_Book_Item__c FROM Price_Book_Item__c WHERE IsDeleted=false AND Parent_Price_Book_Item__c IN :pliIds];
        
        Map<Id, Price_Book_Item__c> pbiLookup = new Map<Id, Price_Book_Item__c>(childPriceBookItems);

        Map<Id, Set<Id>> childItems = new Map<Id, Set<Id>>();
        Set<Id> pbiItemIds = new Set<Id>();
        Map<String, Id> quoteItemRecordType = new Map<String, Id>();
        for(Price_Book_Item__c pbi : childPriceBookItems)
        {
            if(!childItems.containsKey(pbi.Parent_Price_Book_Item__c))
            {
                childItems.put(pbi.Parent_Price_Book_Item__c, new Set<Id>());
            }
            childItems.get(pbi.Parent_Price_Book_Item__c).add(pbi.Id);
            pbiItemIds.add(pbi.Id);

            String rt = pbi.Catalog_Item__r.Ticket_Item_Record_Type__c;
            if(String.isBlank(rt) || !quoteItemRecordTypeLookup.containsKey(rt)) continue;

            quoteItemRecordType.put(pbi.Id, quoteItemRecordTypeLookup.get(rt));
        }

        List<Quote_Item__c> newQuoteItems = new List<Quote_Item__c>();

       
        SobjectType quoteItemSObjectType = Quote_Item__c.sObjectType;


        for(Quote_Item__c qi : itemsOfInterest)
        {
            if(!childItems.containsKey(qi.Price_Book_Item__c)) continue;

            for(Id pbi : childItems.get(qi.Price_Book_Item__c))
            {
            	Quote_Item__c newItem = (Quote_Item__c)quoteItemSObjectType.newSObject(quoteItemRecordType.containsKey(pbi)? quoteItemRecordType.get(pbi) : null, true);

                newItem.Price_Book_Item__c = pbi;
                newItem.Quote__c = qi.Quote__c;
                newItem.Parent_Quote_Item__c = qi.Id;
                newItem.SyncID__c = StringUtility.newGuid();
                newQuoteItems.add(newItem);
            }
        }
        insert newQuoteItems;
    }

    public static void DeleteChildItems(List<Quote_Item__c> items)
    {
    	Set<Id> itemIds = new Map<Id, Quote_Item__c>(items).keySet();
        Map<Id, Quote_Item__c> dbTktItems = new Map<Id, Quote_Item__c>([SELECT Id, (SELECT Id FROM Quote_Items__r WHERE IsDeleted=false AND Id NOT IN :itemIds) FROM Quote_Item__c WHERE IsDeleted=false AND Id IN :itemIds]);
        
        List<Quote_Item__c> childItemsToDelete = new List<Quote_Item__c>();
        for(Quote_Item__c ti: items)
        {  
            if (RuleEngineCore.RuleEngineInProgress!=true && ti.Auto_Added__c == true 
                && ti.Rule_Required_Item__c ==true) 
            {                
                ti.addError('Cannot delete a required quote item.');
                continue;
            }            
            
            if(!dbTktItems.get(ti.Id).Quote_Items__r.isEmpty())
            {
                childItemsToDelete.addAll(dbTktItems.get(ti.Id).Quote_Items__r);
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

	static Map<String, String> GetQuoteItemFieldMapping(String ns, Set<String> priceBookItemFields)
	{
		Boolean isDevOrg = String.isBlank(ns);

        Set<String> quoteItemFields = new Set<String>();        
        Map<String, String> quoteItemToPriceBookItemMapping = new Map<String, String>();

        for(Schema.SObjectField f: Schema.sObjectType.Quote_Item__c.fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe(); 
            String qiFieldName = fd.getName();

            if(!fd.isAccessible() 
            	|| !fd.isCreateable() || fd.isCalculated() 
            	|| fd.isAutoNumber() || fd.isExternalId() || fd.isUnique()
            	|| (!fd.isNameField() && !fd.isCustom() && qiFieldName != 'CurrencyIsoCode'))
            {
                continue;
            }            
            
            quoteItemFields.add(qiFieldName);

            String mappingField = '';

            if(priceBookItemFields.contains(qiFieldName))
            {
            	mappingField = qiFieldName;
            }
            else
            {
            	String qiFieldNameVaried = qiFieldName.replace(ns, '').replace('PBI_', '');
            	if(priceBookItemFields.contains(qiFieldNameVaried))
            	{	
            		mappingField = qiFieldNameVaried;
            	}
            	else if(priceBookItemFields.contains(ns + qiFieldNameVaried))
            	{
            		mappingField = ns + qiFieldNameVaried;
            	} 
            }
            if(!String.isBlank(mappingField))
            {
            	quoteItemToPriceBookItemMapping.put(qiFieldName, mappingField);
            }
            
        }
        quoteItemToPriceBookItemMapping.remove(ns + 'Sequence_Number__c');

        quoteItemToPriceBookItemMapping.put(ns + 'Item_Code__c', ns + 'Catalog_Item_Code__c');
        if (quoteItemFields.contains('Cost__c')) {
            quoteItemToPriceBookItemMapping.put('Cost__c', ns + 'Catalog_Cost__c');
        }


        return quoteItemToPriceBookItemMapping;
	}
}