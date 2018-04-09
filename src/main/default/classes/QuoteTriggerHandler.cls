public class QuoteTriggerHandler extends FXTriggerHandler
{
	public override void OnBeforeInsert(List<sObject> items)
	{
		super.OnBeforeInsert(items);
		QuoteHandler.InitQuote((List<Quote__c>)items);
	}

	public override void OnAfterInsert(List<sObject> items)
	{
		super.OnAfterInsert(items);
		if(SObjectClonerUtility.CloningInProgress !=true)
        	{
           		RuleEngineDispatcher.Run((List<Quote__c>)items);
        	}		
	}

	public override void OnAfterUpdate(List<sObject> items, Map<Id, sObject> oldMap)
	{
		super.OnAfterUpdate(items, oldMap);
		if(SObjectClonerUtility.CloningInProgress !=true)
        	{
			RuleEngineDispatcher.OnQuoteUpdate((List<Quote__c>)items, (Map<Id, Quote__c>)oldMap);
		}
	}
}