public class AuditLogTruncatorScheduler implements Schedulable 
{
   public void execute(SchedulableContext sc)
   {
       String ns = StringUtility.FXNamespace().replace('__', '.');
       QueueableAdapter q = new QueueableAdapter(ns + 'AuditLogTruncator', null);
       System.enqueueJob(q);
   }
}