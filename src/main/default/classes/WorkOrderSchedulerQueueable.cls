public class WorkOrderSchedulerQueueable implements Queueable
{ 
    Set<Id> equipIds {get;set;}
    
    public WorkOrderSchedulerQueueable(Set<Id> paramEquipIds)
    {
        equipIds = paramEquipIds;
    }
    public void execute(QueueableContext context)
    {   
        Database.executeBatch(new WorkOrderSchedulerBatchable(equipIds));   
    }
}