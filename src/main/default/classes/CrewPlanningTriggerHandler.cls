public class CrewPlanningTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> items)
    {
    	JobQualificationHandler.ValidateQualifications((List<Crew_Planning__c>)items);
        JobResourcePlanning.ApplyContactPriceBookItem((List<Crew_Planning__c>)items);
    }
    
    public override void OnBeforeUpdate(List<sObject> items, Map<Id, sObject> oldMap)
    { 
    	JobQualificationHandler.ValidateQualifications((List<Crew_Planning__c>)items);

    	List<Crew_Planning__c> itemsForSyncAssign = new List<Crew_Planning__c>();
        List<Crew_Planning__c> itemsForResourcePlanning = new List<Crew_Planning__c>();

    	List<Crew_Planning__c> cps = (List<Crew_Planning__c>)items;

        for(Crew_Planning__c cp: cps)
        {        
            Crew_Planning__c old = (Crew_Planning__c)oldMap.get(cp.Id);    
            if(old.Crew_Member__c != cp.Crew_Member__c)
            {
                itemsForSyncAssign.add(old);
                itemsForResourcePlanning.add(cp);
            }
        }
        if(!itemsForSyncAssign.isEmpty())
        {
            SyncAssignmentManager.UpdateSyncAssignmentsOnCrewDelete(itemsForSyncAssign);
            JobResourcePlanning.ApplyContactPriceBookItem(itemsForResourcePlanning);
        }
    }    

    public override void OnBeforeDelete(List<sObject> items)
    {
    	SyncAssignmentManager.UpdateSyncAssignmentsOnCrewDelete((List<Crew_Planning__c>)items);
    }

    public override void OnAfterInsert(List<sObject> items)
    {
    	SyncAssignmentManager.UpdateSyncAssignmentsOnCrewAdd((List<Crew_Planning__c>)items);
    }

    public override void OnAfterUpdate(List<sObject> items, Map<Id, sObject> oldMap)
    {
    	SyncAssignmentManager.UpdateSyncAssignmentsOnCrewAdd((List<Crew_Planning__c>)items);
    }
}