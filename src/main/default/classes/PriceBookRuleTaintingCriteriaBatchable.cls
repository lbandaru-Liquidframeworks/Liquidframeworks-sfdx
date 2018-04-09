public class PriceBookRuleTaintingCriteriaBatchable extends FXBatchableBase implements Queueable
{    
    Boolean hasEquipField {get;set;}
    String ns {get;set;}
    
    public PriceBookRuleTaintingCriteriaBatchable ()
    {
        ns = StringUtility.FXNamespace();
        hasEquipField = Equipment_Planning__c.sObjectType.getDescribe().fields.getMap().containsKey(ns + 'Equipment__c');
        
        soqlQuery = 'SELECT Id FROM [ns]Price_Book_Rule__c WHERE IsDeleted=false AND [ns]IsCriteriaDirty__c=false';
        soqlQuery = soqlQuery.replace('[ns]', ns);
        
    }
   
    public override void execute(Database.BatchableContext BC, List<sObject> scope)
    {  
        List<Price_Book_Rule__c > objs = (List<Price_Book_Rule__c >)scope;
        for(Price_Book_Rule__c r : objs)
        {
            r.IsCriteriaDirty__c = true;
        }
        Database.update(objs, false);
    }
    
    public void execute(QueueableContext context)
    {   
        Database.executeBatch(new PriceBookRuleTaintingCriteriaBatchable());   
    }    
}