trigger PriceBookItemTrigger_MixPanelTracking on Price_Book_Item__c (after insert) {
    MixPanelTracking.TrackEvent('PriceBookItemCreated', trigger.new.size());
}