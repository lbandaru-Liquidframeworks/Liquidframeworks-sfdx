trigger TicketItemTrigger_MixPanelTracking on Ticket_Item__c (after update) {
     MixPanelTracking.TrackEvent('TicketItemEdited', trigger.new.size());
}