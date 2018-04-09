trigger TicketItemTrigger_JobPropagator on Ticket_Item__c (before insert, before update) {
    JobPropagator.SetJobId((List<Ticket_Item__c>)trigger.new);
}