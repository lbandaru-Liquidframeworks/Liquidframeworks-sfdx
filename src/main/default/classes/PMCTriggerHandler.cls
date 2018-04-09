public class PMCTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> items)
    {
        PreventativeMaintenanceCriterionHandler.UpdateNextRunForRecurringPMC((List<Preventative_Maintenance_Criterion__c>)items);
    }
    
    public override void OnBeforeUpdate(List<sObject> items, Map<Id, sObject> oldmap)
    {
        PreventativeMaintenanceCriterionHandler.UpdateNextRunForRecurringPMC((List<Preventative_Maintenance_Criterion__c>)items);
    }
    
}