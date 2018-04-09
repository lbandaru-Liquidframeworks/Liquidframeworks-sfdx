public class WorkOrderTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> workOrders)
    {
        FXLicenseController.EnforceEAMLicense();
        WorkOrderHandler.SetTrackingNumberSyncId((List<Work_Order__c>)workOrders);
        WorkOrderHandler.SetActualFinishDate(workOrders);
    }
    
    public override void OnAfterInsert(List<sObject> workOrders)
    {        
        List<Preventative_Maintenance_Schedule__c> pms = WorkOrderHandler.SetLastWorkOrderForPMS((List<Work_Order__c>)workOrders, false);
        
        Map<Id, Preventative_Maintenance_Schedule__c> pmsMap = pms.isEmpty()? new Map<Id, Preventative_Maintenance_Schedule__c>() : new Map<Id, Preventative_Maintenance_Schedule__c>(pms);
        
        List<Preventative_Maintenance_Schedule__c> pms2 = WorkOrderHandler.FlagHasOpenOrderOnPMS((List<Work_Order__c>)workOrders, false);
        for(Preventative_Maintenance_Schedule__c p : pms2)
        {
            if(pmsMap.containsKey(p.Id))
            {
                pmsMap.get(p.Id).HasOpenWorkOrder__c = p.HasOpenWorkOrder__c;
            }
            else            
            {
                pmsMap.put(p.Id, p);                
            }
        }
        Database.update(pmsMap.values(), false);        
    }
    
    
    public override void OnBeforeUpdate(List<sObject> workOrders, Map<Id, sObject> oldMap)
    {
        FXLicenseController.EnforceEAMLicense();
        WorkOrderHandler.SetActualFinishDate((List<Work_Order__c>)workOrders);
    }
    
    public override void OnAfterUpdate(List<sObject> workOrders, Map<Id, sObject> oldMap)
    {
        WorkOrderHandler.FlagHasOpenOrderOnPMS((List<Work_Order__c>)workOrders, true);
        WorkOrderHandler.ProcessWorkOrderCompleted((List<Work_Order__c>)workOrders, (Map<Id, Work_Order__c>)oldMap);
    }  
    
    public override void OnBeforeDelete(List<sObject> workOrders)
    {
        FXLicenseController.EnforceEAMLicense();
    }
    public override void OnAfterDelete(List<sObject> workOrders)
    {
         WorkOrderHandler.FlagHasOpenOrderOnPMS((List<Work_Order__c>)workOrders, true);
    }
}