trigger QuoteItemTrigger_MixPanelTracking on Quote_Item__c (after insert, after update) {
    MixPanelTracking.TrackEvent(trigger.isInsert? 'QuoteItemCreated' : 'QuoteItemEdited', trigger.new.size());
}