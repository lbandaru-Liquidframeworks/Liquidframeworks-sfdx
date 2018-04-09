trigger PriceBookRuleTrigger_MixPanelTracking on Price_Book_Rule__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Price_Book_Rule__c', trigger.isInsert, trigger.new.size());
}