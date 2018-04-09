trigger TicketLogTrigger_MixPanelTracking on Ticket_Log__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Ticket_Log__c', trigger.isInsert, trigger.new.size());
}