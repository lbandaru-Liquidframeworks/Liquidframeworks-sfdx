@RestResource(urlMapping = '/TicketItemInsertSvc/*')
global with sharing class TicketItemInsertSvc{

    @HttpPost
    global static List<Ticket_Item__c> InsertTktItem(Id tktId, List<Id> sourceIds, Decimal nextSequenceNumber) {
        return TicketItemHandler.CreateTicketItems(tktId, sourceIds, nextSequenceNumber); 
    }
}