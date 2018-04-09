public class TicketChecklistStepTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> items)
    {
        super.OnBeforeInsert(items);
        JobPropagator.SetJobId((List<Ticket_Checklist_Step__c>)items);
    }

    public override void OnBeforeUpdate(List<sObject> items, Map<Id, sObject> oldMap)
    {
        super.OnBeforeUpdate(items, oldMap);
        JobPropagator.SetJobId((List<Ticket_Checklist_Step__c>)items);
    }
}