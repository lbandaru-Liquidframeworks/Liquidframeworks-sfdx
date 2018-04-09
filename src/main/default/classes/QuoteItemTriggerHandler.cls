public class QuoteItemTriggerHandler extends FXTriggerHandler
{
	public override void OnBeforeInsert(List<sObject> items)
	{
		super.OnBeforeInsert(items);
		List<Quote_Item__c> quoteItems = (List<Quote_Item__c>)items;

		if(SObjectClonerUtility.CloningInProgress !=true) 
        {
            List<Quote_Item__c> itemsOfInterest = new List<Quote_Item__c>();
            for(Quote_Item__c item: quoteItems)
            {
                if(item.Created_in_Mobile__c ==true) continue;
                itemsOfInterest.add(item);
            }
            if(!itemsOfInterest.isEmpty())
            {
            	QuoteItemHandler.InitQuoteItems(itemsOfInterest);   
                RuleEngineDispatcher.RunDisallowedRules(itemsOfInterest);      
            }
        }
        for(Quote_Item__c item: quoteItems)
        {  
            if(!String.isBlank(item.SyncID__c))  continue;
            item.SyncID__c = StringUtility.newGuid();            
        }
        OverrideHandler.ApplyOverride(items);

	}

	public override void OnAfterInsert(List<sObject> items)
    {         
        super.OnAfterInsert(items);
        if(SObjectClonerUtility.CloningInProgress != true && RuleEngineCore.RuleEngineInProgress != true) 
        {
            List<Quote_Item__c> quoteItems = (List<Quote_Item__c>)items;
            List<Quote_Item__c> itemsOfInterest = new List<Quote_Item__c>();
            for(Quote_Item__c item: quoteItems)
            {
                if(item.Created_in_Mobile__c ==true) continue;
                itemsOfInterest.add(item);
            }
            if(!itemsOfInterest.isEmpty())
            {
                QuoteItemHandler.AddChildren(itemsOfInterest);
                RuleEngineDispatcher.Run(itemsOfInterest, false);
            }
        }    
    }   

    public override void OnBeforeUpdate(List<sObject> items, Map<Id, sObject> oldMap)
    {            
        super.OnBeforeUpdate(items, oldMap);
        OverrideHandler.ApplyOverride(items);
    }  

	public override void OnBeforeDelete(List<sObject> items)
	{
        super.OnBeforeDelete(items);
		List<Quote_Item__c> quoteItems = (List<Quote_Item__c>)items;
		List<Quote_Item__c> itemsOfInterest = new List<Quote_Item__c>();

		for(Quote_Item__c o: quoteItems)
        {  
            if (RuleEngineCore.RuleEngineInProgress!=true && o.Auto_Added__c == true 
                && o.Rule_Required_Item__c ==true) 
            {                
                o.addError('Cannot delete a required Quote Item.');
                continue;
            } 
            itemsOfInterest.add(o);
        }

		QuoteItemHandler.DeleteChildItems(itemsOfInterest);
	}

	public override void OnAfterUpdate(List<sObject> items, Map<Id, sObject> oldMap)
    {     
        super.OnAfterUpdate(items, oldMap);   
        if(SObjectClonerUtility.CloningInProgress != true && RuleEngineCore.RuleEngineInProgress != true) 
        {
           RuleEngineDispatcher.Run((List<Quote_Item__c>)items, true);
        }
    }
}