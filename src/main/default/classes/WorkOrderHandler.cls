public class WorkOrderHandler
{
    public static void SetTrackingNumberSyncId(List<Work_Order__c> workOrders)
    {        
        for(Work_Order__c w : workOrders)
        {
            if(String.isBlank(w.Tracking_Number__c))
            {
              w.Tracking_Number__c = StringUtility.getTrackingNumber('W-');
            }
            if(String.isBlank(w.SyncID__c))
            {
                w.SyncID__c =  StringUtility.newGuid();
            }
        }
    }
    
    
    public static void SetActualFinishDate(List<Work_Order__c> workOrders)
    {        
        for(Work_Order__c w : workOrders)
        {
            if(w.IsCompleted__c == true && w.Actual_Finish_Date__c == null )
            {
              w.Actual_Finish_Date__c = Datetime.now();
            }           
        }
    }
    
    public static void ProcessWorkOrderCompleted(List<Work_Order__c> workOrders, Map<Id, Work_Order__c> oldMap)
    {
        Map<Id, Id> equipWorkOrder = new Map<Id, Id>();
        for(Work_Order__c wo: workOrders)
        {
            if(wo.IsCompleted__c == true && (oldMap == null || oldMap.get(wo.Id).IsCompleted__c !=true))
            {
                if(!String.isBlank(wo.Equipment__c)) 
                {  
                    equipWorkOrder.put(wo.Equipment__c, wo.Id);
                }
            }
        }
        Datetime dt = Datetime.now();
        Set<Id> equipIds = equipWorkOrder.keySet();
        List<Id> woIds = equipWorkOrder.values();
        
        List<Service_History__c> shs = [SELECT Id, Equipment__c, Returned_to_Service__c FROM Service_History__c WHERE Work_Order__c IN :woIds AND Returned_to_Service__c=null];
        for(Service_History__c sh: shs)
        {
            sh.Returned_to_Service__c = dt;
            equipWorkOrder.remove(sh.Equipment__c);
        }
        update shs;
        
        Map<Id, Equipment__c> equipItems = new Map<Id, Equipment__c>([SELECT Id, Out_of_Service__c, (SELECT Id FROM Service_History__r WHERE Work_Order__c=null AND Returned_to_Service__c=null ORDER BY CreatedDate LIMIT 1) FROM Equipment__c WHERE Id IN :equipIds]);
           
           
        if(!equipWorkOrder.isEmpty())
        {
            Set<Id> equipWithNoServiceHistory = equipWorkOrder.keySet();
            List<Service_History__c> shToUpdate = new List<Service_History__c>();
           
            for(Id equipId : equipWithNoServiceHistory)                
            {
                Equipment__c e = equipItems.get(equipId);
                if(e.Service_History__r.isEmpty()) continue;
                Service_History__c sh = e.Service_History__r.get(0);
                sh.Work_Order__c = equipWorkOrder.get(e.Id);
                sh.Returned_to_Service__c = dt;
                shToUpdate.add(sh);                
            }
            update shToUpdate;
        }
        
        List<Equipment__c> equipToUpdate = new List<Equipment__c >();
        for(Equipment__c e: equipItems.values())
        {
            if(e.Out_of_Service__c == false) continue;
            e.Out_of_Service__c = true;
            equipToUpdate.add(e);
        }
        update equipToUpdate;
        
    }
    
    public static List<Preventative_Maintenance_Schedule__c> SetLastWorkOrderForPMS(List<Work_Order__c> workOrders, Boolean autoSave)
    {     
        List<Preventative_Maintenance_Schedule__c> pmsItems = new List<Preventative_Maintenance_Schedule__c>();
           
        Set<Id> pmsIds = new Set<Id>();
        
        Map<Id, Id> pmsLastWorkOrder = new Map<Id, Id>();
        for(Work_Order__c w : workOrders)
        {            
            if(String.isBlank(w.Source_PMS__c)) continue;
            pmsIds.add(w.Source_PMS__c);   
            pmsLastWorkOrder.put(w.Source_PMS__c, w.Id);
                             
        }
         
        
        if(pmsIds.isEmpty()) return pmsItems;
        
        for(Preventative_Maintenance_Schedule__c pms : [SELECT Id, Last_Work_Order__c FROM Preventative_Maintenance_Schedule__c WHERE Id IN :pmsIds])
        {         
            pms.Last_Work_Order__c = pmsLastWorkOrder.get(pms.Id);
            pmsItems.add(pms);
        }
        if(autoSave==true) Database.update(pmsItems , false);
        return pmsItems;
    }
    
    public static List<Preventative_Maintenance_Schedule__c> FlagHasOpenOrderOnPMS(List<Work_Order__c> workOrders, Boolean autoSave)
    {   
      
        Set<Id> pmsIds = new Set<Id>();
        for(Work_Order__c w : workOrders)
        {            
            if(String.isBlank(w.Source_PMS__c)) continue;
            pmsIds.add(w.Source_PMS__c);                             
        }
        
        List<Preventative_Maintenance_Schedule__c> pms = [SELECT Id, HasOpenWorkOrder__c, (SELECT Id FROM Work_Orders__r WHERE IsCompleted__c=false AND IsTemplate__c=false) FROM Preventative_Maintenance_Schedule__c WHERE Id IN :pmsIds];
        
        List<Preventative_Maintenance_Schedule__c> pmsToUpdate = new List<Preventative_Maintenance_Schedule__c>();
        
        for(Preventative_Maintenance_Schedule__c p : pms)
        {
            if(p.HasOpenWorkOrder__c == !p.Work_Orders__r.isEmpty()) continue;            
            p.HasOpenWorkOrder__c = !p.Work_Orders__r.isEmpty();
            pmsToUpdate.add(p);            
        }
        if(autoSave==true) Database.update(pmsToUpdate, false);
        return pmsToUpdate;
    } 
}