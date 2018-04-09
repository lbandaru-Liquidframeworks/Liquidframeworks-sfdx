public class TicketTriggerHandler extends FXTriggerHandler
{ 
    public override void OnAfterUpdate(List<sObject> items, Map<Id, sObject> oldMap)
    {
        super.OnAfterUpdate(items, oldMap);
        List<Ticket__c> tkts = (List<Ticket__c>)items;
        Set<Id> tktIds = new Set<Id>();
        Set<String> rollupSummaryFields =MetadataHelper.GetRollupSummaryFields(Ticket__c.sObjectType); 
        for(Ticket__c t : tkts)
        {
        	if(t.IsReadOnlyOnConsole__c == true) continue;
            //tktIds.add(t.Id);
            
            Boolean isRollupUpdate = false;
            Ticket__c prev = (Ticket__c)oldMap.get(t.Id);
            for(String f : rollupSummaryFields)
            {
                if(t.get(f) != prev.get(f))
                {
                    isRollupUpdate=true;
                    break;
                }
            }
            if(!isRollupUpdate)
            {
        	   tktIds.add(t.Id);
            }
            
        }
        if(!tktIds.isEmpty()) 
        {
            OverrideBatcher.RunOnTickets(tktIds);
        }
    }
}