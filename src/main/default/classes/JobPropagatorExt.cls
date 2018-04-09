global class JobPropagatorExt
{
    global static void Run(List<sObject> objs)
    {
        JobPropagator.SetJobId(objs);
    }
    
/*    
trigger [CustomObject]Trigger_JobPropagator on [CustomObject](after insert, after update) 
{  
    FX5.JobPropagatorExt.Run(trigger.new);
}    
*/

}