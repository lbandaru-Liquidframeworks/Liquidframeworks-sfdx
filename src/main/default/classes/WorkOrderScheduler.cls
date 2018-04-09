public class WorkOrderScheduler implements Schedulable 
{
   public void execute(SchedulableContext sc)
   {
       System.enqueueJob(new WorkOrderSchedulerQueueable(null));
   }
}