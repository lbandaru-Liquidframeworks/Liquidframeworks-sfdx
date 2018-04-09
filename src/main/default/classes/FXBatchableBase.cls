public virtual class FXBatchableBase implements Database.Batchable<sObject>, Database.Stateful
{
    public String soqlQuery {get;set;}

    public virtual String DryRun()
    {
        return 'Dry Run is not implemented.';
    }
    
    public virtual void SetParams(Map<String, Object> params0)
    {   
    }
    public virtual Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(soqlQuery);
    }

    public virtual void execute(Database.BatchableContext BC, List<sObject> scope)
    {   
        
    } 
    public virtual void finish(Database.BatchableContext BC)
    {        
    }
}