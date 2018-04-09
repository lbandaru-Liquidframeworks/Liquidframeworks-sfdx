trigger AddSyncIDToTicketLog on Ticket_Log__c (before insert) {

    for(Ticket_Log__c item : Trigger.new)
     {
         if(item.SyncID__c == null)
         {
             item.SyncID__c = StringUtility.newGuid();
         }
     }    
}