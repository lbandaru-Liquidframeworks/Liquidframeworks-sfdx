public without sharing class JobPropagatorBatchable extends FXBatchableBase
{
    public static void RunPostInstall()
    {
        String ns = StringUtility.FXNamespace();
        Database.executeBatch(new JobPropagatorBatchable(ns + 'Ticket_Item__c'));
        Database.executeBatch(new JobPropagatorBatchable(ns + 'Ticket_Log__c'));
        Database.executeBatch(new JobPropagatorBatchable(ns + 'Ticket_Checklist_Step__c'));
    }    

    public JobPropagatorBatchable(String objType)
    {
        Init(objType);
    }
    
    void Init(String objType)
    {
        RuleEngineIsActive = RuleEngineCore.IsActive();
        if(RuleEngineIsActive)
        {
            RuleEngineCore.Suspend();
        }
        String ns = StringUtility.FXNamespace();
        String jobField = 'Job_Share__c';
        if(!String.isBlank(ns) 
            || objType.equalsIgnorecase('Ticket_Item__c')
            || objType.equalsIgnorecase('Ticket_Log__c')
            || objType.equalsIgnorecase('Ticket_Checklist_Step__c'))
        {
            jobField = ns + 'Job__c';
        }
        soqlQuery = 'SELECT Id FROM ' + objType + ' WHERE IsDeleted=false AND ' + jobField + '=null'; 
    }
    Boolean RuleEngineIsActive {get;set;}


    public override void execute(Database.BatchableContext BC, List<sObject> scope)
    {   
        Database.update(scope, false);
    } 
    public override void finish(Database.BatchableContext BC)
    {       
        if(RuleEngineIsActive)
        {
            RuleEngineCore.Activate();
        } 
    }
}