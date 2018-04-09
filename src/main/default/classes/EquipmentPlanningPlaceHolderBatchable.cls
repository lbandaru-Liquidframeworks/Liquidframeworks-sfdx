public class EquipmentPlanningPlaceHolderBatchable extends FXBatchableBase
{    
    Boolean hasEquipField {get;set;}
    String ns {get;set;}
    
    public EquipmentPlanningPlaceHolderBatchable()
    {
        ns = StringUtility.FXNamespace();
        hasEquipField = Equipment_Planning__c.sObjectType.getDescribe().fields.getMap().containsKey(ns + 'Equipment__c');
        
        soqlQuery = hasEquipField? String.format('SELECT Id, {0}Equipment__c, {0}Equipment2__c FROM {0}Equipment_Planning__c WHERE {0}Equipment2__c=null', new String[]{ns})
            : String.format('SELECT Id FROM {0}Equipment_Planning__c LIMIT 1', new String[]{ns});
    }
   
    public override void execute(Database.BatchableContext BC, List<sObject> scope)
    {   
        if(!hasEquipField) return;
        
        List<Equipment_Planning__c> objs = (List<Equipment_Planning__c>)scope;
        for(Equipment_Planning__c o : objs)
        {
            o.put(ns + 'Equipment2__c', o.get(ns + 'Equipment__c'));
        }
        update objs;
    }    
}