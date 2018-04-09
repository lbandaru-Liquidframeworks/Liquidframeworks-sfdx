public class JobBuilder
{
    public static void OnBeforeInsert(List<Job__c> jobs)
    {
        Initialize(jobs);
    }

    public static void OnAfterInsert(List<Job__c> jobs)
    {
        List<Job__c> syncJobs = new List<Job__c>();
        
        List<Status_History__c> shs = new List<Status_History__c>();

        Set<Id> userIds = new Set<Id>();

        for(Job__c j : jobs) 
        {
            if(j.Sync__c == true) syncJobs.add(j);  
            userIds.add(j.CreatedById);          
           
            if(j.Created_in_Mobile__c == false && j.Status__c != null)
            {          
                shs.add(new Status_History__c(Job__c = j.Id, New_Status__c = j.Status__c, Changed_Date__c = Datetime.now(), Changed_By__c = UserInfo.getUserId()));
            }             
        }
        insert shs;

        if(FX_Settings__c.getOrgDefaults().AutoAddJobCreatorToCrew__c == true)
        {
            List<Contact> contacts = [SELECT Id, User__c FROM Contact WHERE Available_for_Field_Work__c = true AND User__c IN :userIds];
            Map<Id, Id> userToContact = new Map<Id, Id>();
            for(Contact c : contacts)
            {
                userToContact.put(c.User__c, c.Id);
                
            }
            List<Crew_Planning__c> crews = new List<Crew_Planning__c>();
            for(Job__c j : jobs) 
            {
                if(!userToContact.containsKey(j.CreatedById)) continue;
                
                crews.add(new Crew_Planning__c(Job__c = j.Id, Crew_Member__c = userToContact.get(j.CreatedById)));
            }       
            insert crews;
        }

        if(!syncJobs.isEmpty()) SyncAssignmentManager.UpdateSyncAssignments(syncJobs);

    }

    public static void OnBeforeUpdate(List<Job__c> jobs, Map<Id, Job__c> oldMap)
    {
        List<Job__c> items = new List<Job__c>();
        for(Job__c j : jobs) 
        {
            if(oldMap.get(j.Id).Status__c != j.Status__c) items.add(j);         
        }
        if(!items.isEmpty()) SyncAssignmentManager.UpdateJobSyncFlag(items);
    }

    public static void OnAfterUpdate(List<Job__c> jobs, Map<Id, Job__c> oldMap)
    {
        List<Job__c> items = new List<Job__c>();
        for(Job__c j : jobs) 
        {
            Job__c jOld = oldMap.get(j.Id);
            if(jOld.Sync__c != j.Sync__c || jOld.Segment__c != j.Segment__c || jOld.CustomerAccount__c != j.CustomerAccount__c || jOld.Office__c != j.Office__c) 
            {
                items.add(j);     
            }
        }
        if(!items.isEmpty()) SyncAssignmentManager.UpdateSyncAssignments(items);

        RuleEngineConsole.OnJobUpdate(jobs, oldMap); //RuleEngineService.ApplyRuleActionsAsync(jobs, oldMap);


    }  

    public static void Initialize(List<Job__c> jobs)
    {
        Id initialConsoleStatus = null;
        Id initialMobileStatus = null;

        List<Status__c> statuses = [SELECT Id, Sync__c, SObject_Record_Type__c, Initial_Status_Console__c, Initial_Status_Mobile__c, RecordType.DeveloperName 
                                    FROM Status__c 
                                    WHERE SObject__c='Job__c'
                                    AND (Initial_Status_Console__c=true OR Initial_Status_Mobile__c=true)];

        Map<string, Status__c> defaultStatus = new Map<string, Status__c>();
        for (Status__c status: statuses)
        {
            if(status.Initial_Status_Console__c)
            {
                defaultStatus.put(string.valueOf(status.SObject_Record_Type__c)  + 'console', status);  
            }
            if(status.Initial_Status_Mobile__c)
            {
                defaultStatus.put(string.valueOf(status.SObject_Record_Type__c)  + 'mobile', status);  
            }

        }
        Map<Id, Status__c> mapStatuses = new Map<Id, Status__c>(statuses);

        Set<Id> recordTypeIDs = new Set<Id>();
        for(Job__c j: jobs)
        {
            recordTypeIDs.add(j.RecordTypeId);
        }
        Map<Id, RecordType> recordTypes = new Map<Id, RecordType>([SELECT Id, Developername FROM RecordType where IsActive=true AND  Id IN :recordTypeIDs]);

        for(Job__c j : jobs)
        {
            if(!StringUtility.isValidTrackingNumber(StringUtility.EntityObjectType.Job, j.Tracking_Number__c))
            {        
                j.Tracking_Number__c = StringUtility.getTrackingNumber('J-');
            }

            if(j.SyncID__c == null)
            {
                j.SyncID__c = StringUtility.newGuid();
            }

            string key = null;
            if(j.Status__c == null && !string.isBlank(j.RecordTypeId) && recordTypes.containsKey(j.RecordTypeId))
            {                
                key = string.valueOf(recordTypes.get(j.RecordTypeId).DeveloperName) + (j.Created_in_Mobile__c ?  'mobile' : 'console');

                if(defaultStatus.containsKey(key))
                {
                    j.Status__c = defaultStatus.get(key).Id;                           
                }
            }

            if(j.Status__c == null)
            {                
                key = null + (j.Created_in_Mobile__c ?  'mobile' : 'console');

                if(defaultStatus.containsKey(key))
                {
                    j.Status__c = defaultStatus.get(key).Id;                           
                }
            }

            if(j.Status__c !=null && mapStatuses.containsKey(j.Status__c))
            {
                j.Sync__c = mapStatuses.get(j.Status__c).Sync__c;
            }
        } 
    }
}