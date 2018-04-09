public class EquipmentHandler
{  
    public static void ApplyPMS(List<Equipment__c> items, Map<Id, Equipment__c> oldmap)
    {
        Set<Id> equipIds = oldMap.keySet();
        Datetime now = Datetime.now();

        Map<Id, Equipment__c> newmap = new Map<Id, Equipment__c>(items);

        Set<Id> equipWithChange = new Set<Id>();

        for(Preventative_Maintenance_Criterion__c c : [SELECT Id, Target_Field__c, Preventative_Maintenance_Schedule__r.Equipment__c FROM Preventative_Maintenance_Criterion__c WHERE IsDeleted=false AND Preventative_Maintenance_Schedule__r.IsActive__c=true AND  Preventative_Maintenance_Schedule__r.Equipment__c IN :equipIds AND Target_Field__c!=null AND Effective_Date__c<=:now AND (Expiration_Date__c=null OR Expiration_Date__c>:now)])
        {
            Id equipId = c.Preventative_Maintenance_Schedule__r.Equipment__c;
            Equipment__c newValues = newmap.get(equipId);
            Equipment__c oldValues = oldmap.get(equipId);

            if(newValues.get(c.Target_Field__c) != oldValues.get(c.Target_Field__c))
            {
                equipWithChange.add(equipId);
            }            
        }

        if(!equipWithChange.isEmpty())
        {
            System.enqueueJob(new WorkOrderSchedulerQueueable(equipWithChange)); 
        }
    }
    public static void ProcessOutOfServiceChanged(List<Equipment__c> items, Map<Id, Equipment__c> oldmap)
    {
        Set<Id> outOfService = new Set<Id>();
        Set<Id> backInService = new Set<Id>();
        
        for(Equipment__c e : items)
        {
            if(e.Out_of_Service__c == oldmap.get(e.Id).Out_of_Service__c) continue;
            if(e.Out_of_Service__c == true)
            {
                outOfService.add(e.Id);
            }            
            else if(e.Out_of_Service__c == false)
            {
                backInService.add(e.Id);
            }           
        }
        if(!outOfService.isEmpty())
        {
            CreateServiceHistory(outOfService);
        }
        if(!backInService.isEmpty())
        {
            UpdateServiceHistoryReturnToService(backInService );
        }
    }
    static void CreateServiceHistory(Set<Id> equipIds)
    {
        if(equipIds.isEmpty()) return;        
        List<Service_History__c> shs = new List<Service_History__c>();
        Map<Id, Service_History__c> equipSerHistory = new Map<Id, Service_History__c>();
       
        for(Id e : equipIds)
        {
            Service_History__c sh = new Service_History__c(Equipment__c = e, Out_of_Service__c = Datetime.now());
            equipSerHistory.put(e, sh);
        }        
        List<Equipment__c> equipItems = [SELECT Id, Meter__c, (SELECT Last_Meter_Value__c FROM Service_History__r ORDER BY CreatedDate DESC LIMIT 1) FROM Equipment__c WHERE Id IN :equipIds];
        for(Equipment__c e : equipItems)
        {
             Service_History__c sh = equipSerHistory.get(e.Id);
             sh.Last_Meter_Value__c = e.Meter__c;
             
             if(!e.Service_History__r.isEmpty())
             {
                 sh.Previous_Meter_Value__c = e.Service_History__r.get(0).Last_Meter_Value__c;
             }            
        }
        insert equipSerHistory.values();
    }
    
    static void UpdateServiceHistoryReturnToService(Set<Id> equipIds)
    {                   
        if(equipIds.isEmpty()) return;
        
        List<Equipment__c> equipItems = [SELECT Id, Meter__c, (SELECT Id, Returned_to_Service__c FROM Service_History__r ORDER BY CreatedDate DESC LIMIT 1) FROM Equipment__c WHERE Id IN :equipIds];
        
        List<Service_History__c> shsToUpdate = new List<Service_History__c>();
        
        Datetime dt = Datetime.now();        
        for(Equipment__c e : equipItems)
        {
             if(e.Service_History__r.isEmpty()) continue;  
             Service_History__c sh = e.Service_History__r.get(0);
             if(sh.Returned_to_Service__c != null) continue;
             sh.Returned_to_Service__c = dt; 
             shsToUpdate.add(sh);
        }      
        update shsToUpdate;
    }  
}