public class TicketBuilder
{
    public static void OnBeforeInsert(List<Ticket__c> tkts)
    {
        Initialize(tkts);
    }

    public static void OnAfterInsert(List<Ticket__c> tkts)
    {
        List<Id> tktIds = new List<Id>(new Map<Id, Ticket__c>(tkts).keySet());
        TicketBuilder.CreateChecklistSteps(tktIds);        

        ChatterFeedManager.ProcessTicketFeedsOnTicketInsert(tkts);
        List<Status_History__c> shs = new List<Status_History__c>();
        List<Ticket__c> tktsForRuleEngine = new List<Ticket__c>();
        for(Ticket__c t : tkts) 
        {           
            if(t.Created_in_Mobile__c == true || t.Status__c == null) continue;
          
            Status_History__c sh = new Status_History__c();
            sh.Ticket__c = t.Id;
            sh.New_Status__c = t.Status__c;
            sh.Changed_Date__c = Datetime.now();
            sh.Changed_By__c = UserInfo.getUserId();
            shs.add(sh);            
        }
        if(!shs.isEmpty())
        {
            insert shs;
        }
     
        if(SObjectClonerUtility.CloningInProgress !=true)
        {
           RuleEngineConsole.OnTicketInsert(tkts);
        }
    }

    public static void OnBeforeUpdate(List<Ticket__c> tkts, Map<Id, Ticket__c> oldMap)
    {
        List<Ticket__c> items = new List<Ticket__c>();
        for(Ticket__c  t : tkts) 
        {
            if(oldMap.get(t.Id).Status__c != t.Status__c) items.add(t);     
        }
        if(!items.isEmpty()) 
        {
            SyncAssignmentManager.UpdateTicketSyncFlag(items);
        }
    }
    public static void OnTicketUpdate(List<Ticket__c> tkts, Map<Id, Ticket__c> oldMap, Boolean isBefore)
    {
        List<Ticket__c> items = new List<Ticket__c>();
        if(isBefore)
        {
            for(Ticket__c  t : tkts) 
            {
                if(oldMap.get(t.Id).Status__c != t.Status__c) items.add(t);     
            }
            if(!items.isEmpty()) 
            {
                SyncAssignmentManager.UpdateTicketSyncFlag(items);
            }
        }
        else
        {
            for(Ticket__c  t : tkts) 
            {
                if(oldMap.get(t.Id).Sync__c != t.Sync__c) items.add(t);     
            }
            if(!items.isEmpty()) 
            {
                ChatterFeedManager.ProcessTicketFeedsOnTicketUpdate(items);
            }
            RuleEngineConsole.OnTicketUpdate(tkts, oldMap);
        }
    }

    public static void Initialize(List<Ticket__c> tkts)
    {   

        PopulateTicketWarehouse(tkts);
        List<Status__c> statuses = [SELECT Id, SObject_Record_Type__c, Sync__c, Initial_Status_Console__c, Initial_Status_Mobile__c 
                                  FROM Status__c 
                                  WHERE SObject__c='Ticket__c'
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
        for(Ticket__c t: tkts)
        {
            recordTypeIDs.add(t.RecordTypeId);
        }
        Map<Id, RecordType> recordTypes = new Map<Id, RecordType>([SELECT Id, Developername FROM RecordType where IsActive=true AND  Id IN :recordTypeIDs]);

        for(Ticket__c t: tkts)
        {
            if(!StringUtility.isValidTrackingNumber(StringUtility.EntityObjectType.Ticket, t.Tracking_Number__c))
        {        
            t.Tracking_Number__c = StringUtility.getTrackingNumber('T-');
        }
        if(t.SyncID__c == null)
        {
            t.SyncID__c = StringUtility.newGuid();
        }

        string key = null;
            if(t.Status__c==null && !string.isBlank(t.RecordTypeId) && recordTypes.containsKey(t.RecordTypeId))
            {      
                key = string.valueOf(recordTypes.get(t.RecordTypeId).DeveloperName) + (t.Created_in_Mobile__c?  'mobile' : 'console');

                if(defaultStatus.containsKey(key))
                {
                t.Status__c = defaultStatus.get(key).Id;                           
              }
            }

          if(t.Status__c == null)
          {
            key = null + (t.Created_in_Mobile__c ?  'mobile' : 'console');

            if(defaultStatus.containsKey(key))
            {
              t.Status__c = defaultStatus.get(key).Id;                           
            }
          }

            if(t.Status__c!=null && mapStatuses.containsKey(t.Status__c))
            {
                t.Sync__c = mapStatuses.get(t.Status__c).Sync__c;
            }           
        }    
    }   

    public static void PopulateTicketWarehouse(List<Ticket__c> tkts)
    {
        Set<Id> jobIds = new Set<Id>();
        for(Ticket__c t : tkts)
        {
            jobIds.add(t.Job__c);
        }
        Map<Id, Job__c> jobs = new Map<Id, Job__c>([SELECT Id, Warehouse__c FROM Job__c where Id IN :jobIds AND Warehouse__c!=null]);
        for(Ticket__c t : tkts)
        {
            if(String.isBlank(t.Warehouse__c) && jobs.containsKey(t.Job__c))
            {
                t.Warehouse__c = jobs.get(t.Job__c).Warehouse__c;
            }
        }
    }

    public static void CreateChecklistSteps(List<Id> tktIds) 
    {
        List<Ticket__c> tickets = [SELECT Id, RecordType.DeveloperName, RecordType.Name, Checklist_Name__c, 
            job__r.CustomerAccount__c, Job__r.Office__c,  Job__r.Segment__c, Job__r.RecordType.DeveloperName FROM Ticket__c WHERE Id IN :tktIds AND Created_in_Mobile__c=false AND Checklist_Name__c=null];

        if(tickets.isEmpty()) return;

        List<Checklist__c> checkLists = [SELECT Id, 
            Account__r.Id, 
            Name,
            Ticket_Type__c,
            Office__c, 
            Segment__c, 
            Job_Type__c 
           FROM Checklist__c
           ORDER BY WeightingFactor__c DESC];

        if(checkLists.isEmpty()) return;
                                                  
        List<Ticket_Checklist_Step__c> newItems = new List<Ticket_Checklist_Step__c>();

        Map<string, Checklist__c> mapChecklist = new Map<string, Checklist__c>();

        Map<Id, List<Checklist_Step__c>> checklistSteps = new Map<Id, List<Checklist_Step__c>>();

        List<Ticket__c>  tktsWithChange = new List<Ticket__c>();

        for(Ticket__c t : tickets) 
        {   
            Checklist__c cResult = null; 
            for(Checklist__c c: checkLists)
            {
                if((c.Account__c == NULL || c.Account__c == t.Job__r.CustomerAccount__c)
                    && (c.Office__c == NULL || c.Office__c == t.Job__r.Office__c)
                    && (c.Segment__c == NULL || c.Segment__c == t.Job__r.Segment__c)
                    && (c.Job_Type__c == NULL || c.Job_Type__c == t.Job__r.RecordType.DeveloperName)
                    && (c.Ticket_Type__c == NULL || c.Ticket_Type__c == t.RecordType.DeveloperName))
                {
                    cResult = c;
                    break;
                } 
            }   
            if(cResult == null) continue;

            if(!checklistSteps.containsKey(cResult.Id))
            {
                
                checklistSteps.put(cResult.Id, [SELECT Id, Name, Description__c, Required_Step__c, Screen__c, Sequence_Number__c
                                                    FROM Checklist_Step__c
                                                    WHERE Checklist__c = :cResult.Id]);
            }

            List<Checklist_Step__c> steps =  checklistSteps.get(cResult.Id);
            if(steps!=null && !steps.isEmpty()) 
            {
                for(Checklist_Step__c item: steps) 
                {
                    newItems.add(new Ticket_Checklist_Step__c(Ticket__c = t.Id, Name = item.Name, Description__c = item.Description__c, 
                            Screen__c = item.Screen__c, Sequence_Number__c = item.Sequence_Number__c, 
                            Required_Step__c = item.Required_Step__c));
                }                        

                t.Checklist_Name__c = cResult.Name;
                tktsWithChange.add(t);        
            }           
        }    
        if(!newItems.isEmpty())  insert newItems;
        if(!tktsWithChange.isEmpty())  update tktsWithChange;
    }
}