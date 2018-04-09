trigger AddSyncIDToTicketChecklistStep  on Ticket_Checklist_Step__c (before insert) {

    for(Ticket_Checklist_Step__c item : Trigger.new)
     {
         if(item.SyncID__c == null)
         {
             item.SyncID__c = StringUtility.newGuid();
         }
     }    
}