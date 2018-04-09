public class EquipmentPlanningTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> items)
    {
    	EquipmentPlanningHandler.ValidateSourcePriceBook((List<Equipment_Planning__c>)items, null);    	
    	JobQualificationHandler.ValidateQualifications((List<Equipment_Planning__c>)items);
        JobResourcePlanning.ApplyEquipmentPriceBookItem((List<Equipment_Planning__c>)items);
    }
    
    public override void OnBeforeUpdate(List<sObject> items, Map<Id, sObject> oldMap)
    { 
    	EquipmentPlanningHandler.ValidateSourcePriceBook((List<Equipment_Planning__c>)items, (Map<Id, Equipment_Planning__c>)oldMap);    	
    	JobQualificationHandler.ValidateQualifications((List<Equipment_Planning__c>)items);

        List<Equipment_Planning__c> itemsOfInterest = new List<Equipment_Planning__c>();
        for(sObject obj: items)
        {        
            Equipment_Planning__c equipPlanning = (Equipment_Planning__c)obj;
            Equipment_Planning__c old = (Equipment_Planning__c)oldMap.get(obj.Id);    
            if(old.Equipment2__c != equipPlanning.Equipment2__c)
            {
                itemsOfInterest.add(equipPlanning);
            }
        }
        if(!itemsOfInterest.isEmpty())
        {            
            JobResourcePlanning.ApplyEquipmentPriceBookItem(itemsOfInterest);
        }

    }    
}