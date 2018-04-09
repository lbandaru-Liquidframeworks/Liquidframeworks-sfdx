trigger PriceBookTrigger_MixPanelTracking on Price_Book__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Price_Book__c', trigger.isInsert, trigger.new.size());
}