trigger PriceBookRuleActionTrigger_MixPanelTracking on Price_Book_Rule_Action__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Price_Book_Rule_Action__c', trigger.isInsert, trigger.new.size());
}