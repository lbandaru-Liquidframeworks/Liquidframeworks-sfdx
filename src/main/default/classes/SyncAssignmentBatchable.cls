public class SyncAssignmentBatchable extends FXBatchableBase 
{    
    Map<string, Id> JobTypePickListToRecordType { get; set;}
    Set<Id> Users { get; set;}
    Set<Id> JobIds { get; set;}

    Set<Id> JobAccounts { get; set;}
    Set<Id> JobRecordTypes { get; set;}
    Set<Id> JobOffices { get; set;}
    Set<string> JobSegments {get; set;}

    Boolean SyncJobCrewOnly;   
    List<Sync_Configuration__c> SyncConfigs;

    public SyncAssignmentBatchable()
    {
        List<Sync_Configuration__c> configs = [SELECT Id, Contact__c, Account__c, Office__c, Segment__c, Job_Type__c, Sync_JobCrewOnly__c, Contact__r.User__c FROM Sync_Configuration__c WHERE IsDeleted=false AND Contact__r.User__c!=null AND Contact__r.User__r.IsActive=true];
        Init(configs, SyncAssignmentManager.GetJobTypePickListToRecordType(), false);
    }

    public SyncAssignmentBatchable (List<Sync_Configuration__c> configs,  Map<string, Id> jobTypePickListToRecordType0, Boolean syncJobCrewOnly0)
    {
        Init(configs, jobTypePickListToRecordType0, syncJobCrewOnly0);
    }

    void Init(List<Sync_Configuration__c> configs,  Map<string, Id> jobTypePickListToRecordType0, Boolean syncJobCrewOnly0) 
    {
        SyncConfigs = configs;
        JobTypePickListToRecordType=jobTypePickListToRecordType0;
        SyncJobCrewOnly = syncJobCrewOnly0;

        Users = new Set<id>();
        JobAccounts = new Set<id>();
        JobRecordTypes = new Set<id>();
        JobOffices = new Set<id>();
        JobSegments = new Set<string>();

        for(Sync_Configuration__c sc : configs)
        {           
            Users.add(sc.Contact__c);
            if(!syncJobCrewOnly0)
            {
                if(sc.Account__c!=null) JobAccounts.add(sc.Account__c);
                if(sc.Office__c!=null) JobOffices.add(sc.Office__c);
                if(sc.Segment__c!=null) JobSegments.add(sc.Segment__c);
                if(sc.Job_Type__c!=null && sc.Job_Type__c!='' && jobTypePickListToRecordType0.containsKey(sc.Job_Type__c)) 
                    JobRecordTypes.add(jobTypePickListToRecordType0.get(sc.Job_Type__c));
            }
        }
     
        if(SyncJobCrewOnly)
        {   
            String quoteStr = (QuoteExtension.HasQuoteV1 == true)? String.format(',{0}Job__r.{0}Quote__c', new String[]{StringUtility.FXNamespace()}) : '';

            soqlQuery = String.format('SELECT Id, {0}Crew_Member__c, {0}Job__r.{0}CustomerAccount__c, {0}Job__r.RecordTypeId, {0}Job__r.{0}Office__c, {0}Job__r.{0}Segment__c {1} FROM {0}Crew_Planning__c WHERE {0}Job__r.{0}Sync__c=true AND {0}Crew_Member__c in :Users',
                    new String[]{StringUtility.FXNamespace(), quoteStr});
        }
        else
        { 

            String soql = 'SELECT Id, {0}CustomerAccount__c, RecordTypeId, {0}Office__c, {0}Segment__c {1} FROM {0}Job__c WHERE {0}Sync__c=true ';
            String whereClause = '';
            String sep='';
            if(!JobAccounts.isEmpty())
            {
                whereClause += sep + '{0}CustomerAccount__c IN :JobAccounts ';
                sep = ' OR ';
            }

            if(!JobRecordTypes.isEmpty())
            {
                whereClause += sep + 'RecordTypeId IN :JobRecordTypes ';
                sep = ' OR ';
            }


            if(!JobOffices.isEmpty())
            {
                whereClause += sep + '{0}Office__c IN :JobOffices ';
                sep = ' OR ';
            }

            if(!JobSegments.isEmpty())
            {
               // whereClause += sep + '{0}Segment__c IN :JobSegments ';
               // sep = ' OR ';
            }
            if(whereClause!='') soql += ' AND (' + whereClause + ')';
            
            String quoteField = (QuoteExtension.HasQuoteV1 == true)? ',' + QuoteExtension.QuoteV1FieldName : '';

            soqlQuery = String.format(soql, new String[]{StringUtility.FXNamespace(), quoteField});
        }
        System.debug('soql query: ' + soqlQuery);
    }
    
    public override Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(soqlQuery);
    }

    public override void execute(Database.BatchableContext BC, List<SObject> scope)
    {
        if(SyncJobCrewOnly)
        {
            SyncAssignmentManager.UpdateJobCrewSyncAssignments(scope, SyncConfigs);
        }
        else
        {
            SyncAssignmentManager.UpdateSyncAssignments(scope, SyncConfigs);
        }       
    }
 
    public override void finish(Database.BatchableContext BC)
    {       
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        
        AsyncApexJob a = [SELECT Id, Status, ApexClass.Name, JobType, CompletedDate, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
              FROM AsyncApexJob WHERE Id = :BC.getJobId()];
        if(a.NumberOfErrors>0)   
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('force.com System Error - ' + a.Status);
            mail.setPlainTextBody('Please forward this to your tech support team. '
                +' AsyncApexJob Id:' + a.Id 
                + ', ApexClass.Name:' + a.ApexClass.Name 
                + ', Status:' + a.Status
                + ', ExtendedStatus:' + a.ExtendedStatus
                + ', NumberOfErrors:' + a.NumberOfErrors
                + ', JobItemsProcessed:' + a.JobItemsProcessed
                + ', TotalJobItems:' + a.TotalJobItems
                + ', CreatedBy.Email:' + a.CreatedBy.Email);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}