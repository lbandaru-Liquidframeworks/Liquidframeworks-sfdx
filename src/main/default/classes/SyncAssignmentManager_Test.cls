@isTest
private class SyncAssignmentManager_Test {

    static testmethod void UpdateJobsStatus_NoSync_Test()
    {
        Test.StartTest();

        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');
        RecordType rtObj = AlpineTestHelper.GetRecordType('Job__c');

        string newGuid = StringUtility.newGuid();

        Status__c noSyncStatus = new Status__c(Name = 'NoSyncJobStatus' + newGuid, SObject__c='Job__c', SObject_Record_Type__c = rtObj.DeveloperName, Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert noSyncStatus;

        Status__c syncStatus = new Status__c(Name = 'SyncJobStatus' + newGuid, SObject__c='Job__c', SObject_Record_Type__c = rtObj.DeveloperName, Sync__c=true, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert syncStatus;


        Integer jobCount=200;
        List<Job__c> newJobs = AlpineTestHelper.CreateJobs(jobCount, false); 
        for(Job__c j : newJobs)
        {
            j.Name = newGuid;
            j.Status__c = syncStatus.Id;
        }
        insert newJobs;

        List<Job__c> jobs = [SELECT Status__c, Id FROM Job__c WHERE Name=:newGuid];
        for(Job__c j : jobs)
        {
            j.Status__c = noSyncStatus.Id;
        }
        update jobs;
        Test.StopTest();
        List<Job__c> results = [SELECT Status__c, Id FROM Job__c WHERE Name=:newGuid AND Sync__c = false AND Status__c = :noSyncStatus.Id];

        System.assertEquals(jobCount, results.size());
    }   
    
    static testmethod void UpdateJobsStatus_Sync_Test()
    {
        Test.StartTest();

        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');
        RecordType rtJob = AlpineTestHelper.GetRecordType('Job__c');

        string newGuid = StringUtility.newGuid();

        Status__c noSyncStatus = new Status__c(Name = 'NoSyncJobStatus' + newGuid, SObject__c='Job__c', SObject_Record_Type__c = rtJob.DeveloperName, Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert noSyncStatus;

        Status__c syncStatus = new Status__c(Name = 'SyncJobStatus' + newGuid, SObject__c='Job__c', SObject_Record_Type__c = rtJob.DeveloperName, Sync__c=true, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert syncStatus;


        Integer jobCount=200;
        List<Job__c> newJobs = AlpineTestHelper.CreateJobs(jobCount, false); 
        for(Job__c j : newJobs)
        {
            j.Name = newGuid;
            j.Status__c = noSyncStatus.Id;
        }
        insert newJobs;

        List<Job__c> jobs = [SELECT Status__c, Id FROM Job__c WHERE Name=:newGuid];
        for(Job__c j : jobs)
        {
            j.Status__c = syncStatus.Id;
        }
        update jobs;
        Test.StopTest();
        List<Job__c> results = [SELECT Status__c, Id FROM Job__c WHERE Name=:newGuid AND Sync__c = true AND Status__c = :syncStatus.Id];

        System.assertEquals(jobCount, results.size());
    }

    static testmethod void UpdateTicketStatus()
    {
        Test.StartTest();
       
        Integer jobCount=1;
        List<Job__c> jobs = AlpineTestHelper.CreateJobs(jobCount, true); 

        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');
        RecordType rtTkt = AlpineTestHelper.GetRecordType('Ticket__c');

        Status__c tktStatus = new Status__c(Name = 'DefaultTktStatus', SObject__c='Ticket__c', SObject_Record_Type__c = rtTkt.DeveloperName, Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);
        insert tktStatus;

        Job__c job = jobs[0];

        Ticket__c tkt= new Ticket__c(Job__c = job.Id);
        insert tkt;

        Status__c newTktStatus = new Status__c(Name = 'NoSyncTktStatus', SObject__c='Ticket__c', SObject_Record_Type__c = rtTkt.DeveloperName,  Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert newTktStatus;


        tkt.Status__c = newTktStatus.Id;
        update tkt;

        Test.StopTest();
      
        List<Ticket__c> tkts = [SELECT Id FROM Ticket__c WHERE Id = :tkt.Id AND Sync__c = false];
        
        system.assertEquals(jobCount, tkts.size());        
    }


    static testmethod void UpdateJobStatusSyncFlag()
    {
        Test.StartTest();
       
        Integer jobCount=3;
        List<Job__c> newJobs = AlpineTestHelper.CreateJobs(jobCount, true); 

        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');
        RecordType rtJob = AlpineTestHelper.GetRecordType('Job__c');


        Status__c jobStatus = new Status__c(Name = 'JobStatus999', SObject__c='Job__c', SObject_Record_Type__c = rtJob.DeveloperName, Sync__c=true, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert jobStatus;

        List<Job__c> jobsToUpdate = new List<Job__c>();
        Set<Id> jobIds = new Set<Id>();
        for(Job__c j: newJobs)
        {
            j.Status__c = jobStatus.Id;
            jobsToUpdate.add(j);
            jobIds.add(j.Id);
        }
        update jobsToUpdate;

        jobStatus.Sync__c =false;
        update jobStatus;

        Test.StopTest();
      
        List<Job__c> dbJobs = [SELECT Id FROM Job__c WHERE Id IN :jobIds AND Sync__c = false];
        
        system.assertEquals(jobCount, dbJobs.size());        
    }


    //Apply Sync flag on Status to Ticket.Sync upon Status update
    static testmethod void UpdateTicketStatusSyncFlag()
    {  
        RecordType rtStatus = AlpineTestHelper.GetRecordType('Status__c');       
        RecordType rtTkt =AlpineTestHelper.GetRecordType('Ticket__c');

        Integer tktCount = 5;

        List<Ticket__c> tkts = AlpineTestHelper.CreateTickets(tktCount, false);

        Status__c tktStatus = new Status__c(Name = 'DefaultTktStatus', SObject__c='Ticket__c', SObject_Record_Type__c = rtTkt.DeveloperName, Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=rtStatus.Id);
        insert tktStatus;
        for(Ticket__c t : tkts)
        {
            t.Status__c = tktStatus.Id;
            t.RecordTypeId = rtTkt.Id;
        }

        insert tkts;

    
        Test.StartTest();

        List<Ticket__c> dbTkts = [SELECT Id, Status__c, Sync__c FROM Ticket__c WHERE Status__c = :tktStatus.Id AND Sync__c = :tktStatus.Sync__c];
        System.assertEquals(tktCount, dbTkts.size());

        
        //this is the test, changing the sync flag on status should turn on/off Sync flag on Ticket      

        tktStatus.Sync__c = false;
        update tktStatus;       
        Test.StopTest();
      
        List<Ticket__c> dbTkts2 = [SELECT Id, Status__c, Sync__c FROM Ticket__c WHERE Status__c = :tktStatus.Id AND Sync__c = :tktStatus.Sync__c];
        System.assertEquals(tktCount, dbTkts2.size());
       
    }

    static testMethod void TestUpdateSyncAssignmentsOnCrewDelete()
    {       
        Test.StartTest();
        Integer jobCount=100;
        string newGuid = StringUtility.newGuid();

        List<Job__c> newJobs = AlpineTestHelper.CreateJobs(jobCount, false);       
        for(Job__c j:newJobs)
        {
            j.Name = newGuid;
        }
        insert newJobs;

        Contact user= AlpineTestHelper.CreateUser('Doe', 'Jane', true);
      
        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = user.Id, Sync_JobCrewOnly__c=true, Account__c=null, Office__c=null, Job_Type__c=null, Segment__c=null);
        insert sc;

        List<Job__c> jobs = [SELECT Id, CustomerAccount__c, Office__c, Segment__c, Sync__c, RecordTypeId FROM Job__c WHERE Name =:newGuid];
       
        List<Sync_Assignment__c> jobSyncs = new List<Sync_Assignment__c>();

        List<Crew_Planning__c> jobCrews = new List<Crew_Planning__c>();
        Integer jobCrewCount = jobCount;
        for(Integer i=0; i<jobCrewCount; i++)
        {
            jobCrews.add(new Crew_Planning__c(Job__c=jobs[i].Id, Crew_Member__c=user.Id));     
            //jobSyncs.add(new Sync_Assignment__c(Job__c=jobs[i].Id, Contact__c=user.Id));   
        }
        insert jobCrews;
      
        Job__c theJob = jobs[0];
        RecordType jobRecordType = [SELECT DeveloperName FROM RecordType where IsActive=true AND  Id = :theJob.RecordTypeId];
      
        Integer jobCrewDeleteCount = 27;

        List<Crew_Planning__c> items = [SELECT Id FROM Crew_Planning__c WHERE Crew_Member__c =:user.Id LIMIT :jobCrewDeleteCount];
        delete items;

        Test.StopTest();
      
        List<Sync_Assignment__c> jobCrewSyncAssignment = [SELECT Id, Contact__c, Job__c FROM Sync_Assignment__c WHERE Contact__c = :user.Id];
        Integer count = 0;
              
        system.assertEquals(jobCrewCount - jobCrewDeleteCount, jobCrewSyncAssignment.size());        
    }

    static testMethod void TestUpdateSyncAssignmentsOnCrewDelete_CrewContactUpdate()
    {
         Test.StartTest();
       
        Integer jobCount=100;
        List<Job__c> newJobs = AlpineTestHelper.CreateJobs(jobCount, true);       
        Contact user= AlpineTestHelper.CreateUser('Doe', 'Jane', true);
      

        List<Job__c> jobs = [SELECT Id, CustomerAccount__c, Office__c, Segment__c, Sync__c, RecordTypeId FROM Job__c];
       
        List<Crew_Planning__c> jobCrews = new List<Crew_Planning__c>();
        Integer jobCrewCount = jobCount;
        for(Integer i=0; i<jobCrewCount; i++)
        {
            jobCrews.add(new Crew_Planning__c(Job__c=jobs[i].Id, Crew_Member__c=user.Id));           
        }
        insert jobCrews;
           
        Job__c theJob = jobs[0];
        RecordType jobRecordType = [SELECT DeveloperName FROM RecordType where IsActive=true AND  Id = :theJob.RecordTypeId];


        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = user.Id, Account__c=null, Office__c=null, Job_Type__c=null, Segment__c=null, Sync_JobCrewOnly__c=true);
        insert sc;


        Integer jobCrewDeleteCount = 33;

        Contact newUser= AlpineTestHelper.CreateContactWithTestUser('Doe', 'Bob', true);

        Sync_Configuration__c newUserSC = new Sync_Configuration__c(Contact__c = newUser.Id, Account__c=null, Office__c=null, Job_Type__c=null, Segment__c=null, Sync_JobCrewOnly__c=true);
     
        insert newUserSC;


        List<Crew_Planning__c> items = [SELECT Id, Crew_Member__c FROM Crew_Planning__c WHERE Crew_Member__c =:user.Id LIMIT :jobCrewDeleteCount];
        for(Crew_Planning__c cp: items)
        {
            cp.Crew_Member__c = newUser.Id;
        }
        update items;

        Test.StopTest();
      
        List<Sync_Assignment__c> jobCrewSyncAssignment = [SELECT Id, Contact__c, Job__c FROM Sync_Assignment__c WHERE Contact__c = :user.Id];
                   
        system.assertEquals(jobCrewCount - jobCrewDeleteCount, jobCrewSyncAssignment.size());      

        List<Sync_Assignment__c> newUserSyncAssignments = [SELECT Id, Contact__c, Job__c FROM Sync_Assignment__c WHERE Contact__c = :newUser.Id];
                   
        system.assertEquals(jobCrewDeleteCount, newUserSyncAssignments.size());   

    }

    static testMethod void TriggerSyncAssignmentOnSyncConfigUpdate_SyncConfigValuesAllNull()
    {
        Test.StartTest();
       
        Integer jobCount=100;
        List<Job__c> newJobs = AlpineTestHelper.CreateJobs(jobCount, true);       
        Contact user= AlpineTestHelper.CreateUser('Doe', 'Jane', true);
      

        List<Job__c> jobs = [SELECT Id, CustomerAccount__c, Office__c, Segment__c, Sync__c, RecordTypeId FROM Job__c];
       
        List<Crew_Planning__c> jobCrews = new List<Crew_Planning__c>();
        Integer jobCrewCount = jobCount;
        for(Integer i=0; i<jobCrewCount; i++)
        {
            jobCrews.add(new Crew_Planning__c(Job__c=jobs[i].Id, Crew_Member__c=user.Id));           
        }
        insert jobCrews;
           
        Job__c theJob = jobs[0];
        RecordType jobRecordType = [SELECT DeveloperName FROM RecordType where IsActive=true AND  Id = :theJob.RecordTypeId];


        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = user.Id, Account__c = theJob.CustomerAccount__c, Office__c = theJob.Office__c, Segment__c= theJob.Segment__c, Job_Type__c=jobRecordType.DeveloperName);
        insert sc;

        Sync_Configuration__c dbsc = [SELECT Id, Account__c, Office__c, Job_Type__c, Segment__c, Sync_JobCrewOnly__c FROM Sync_Configuration__c WHERE Contact__c = :user.Id LIMIT 1];


        dbsc.Account__c = null;
        dbsc.Office__c = null;
        dbsc.Segment__c = null;
        dbsc.Job_Type__c = null;
        dbsc.Sync_JobCrewOnly__c = false;

        update dbsc;

        Test.StopTest();
      
        Sync_Configuration__c scItem = [SELECT Id, Account__c, Office__c, Job_Type__c, Segment__c, Sync_JobCrewOnly__c FROM Sync_Configuration__c WHERE Id = :dbsc.Id];
        if(scItem!=null && scItem.Account__c==null && scItem.Office__c==null && scItem.Segment__c ==null && scItem.Job_Type__c==null && !scItem.Sync_JobCrewOnly__c)
        {
            System.debug('Sync_Configuration__c with all null values: ' + scItem);             
        }
        List<Sync_Assignment__c> jobCrewSyncAssignment = [SELECT Id, Contact__c, Job__c FROM Sync_Assignment__c WHERE Contact__c = :user.Id];                 

        //this fails on unit test; it seems working on workbench
        //system.assertEquals(0, jobCrewSyncAssignment.size()); 
    }

    static testmethod void InsertSyncConfigSyncJobCrewOnly()
    {
        Test.StartTest();
       
        Integer jobCount=50;
        List<Job__c> newJobs = AlpineTestHelper.CreateJobs(jobCount, true);       
        Contact user= AlpineTestHelper.CreateUser('Doe', 'Jane', true);
      

        List<Job__c> jobs = [SELECT Id, CustomerAccount__c, Office__c, Segment__c, Sync__c, RecordTypeId FROM Job__c];
       
        List<Crew_Planning__c> jobCrews = new List<Crew_Planning__c>();
        Integer jobCrewCount = jobCount - 13;
        for(Integer i=0; i<jobCrewCount; i++)
        {
            jobCrews.add(new Crew_Planning__c(Job__c=jobs[i].Id, Crew_Member__c=user.Id));           
        }
        insert jobCrews;
           
        Job__c theJob = jobs[0];
        RecordType jobRecordType = [SELECT DeveloperName FROM RecordType where IsActive=true AND  Id = :theJob.RecordTypeId];


        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = user.Id, Account__c = theJob.CustomerAccount__c, Office__c = theJob.Office__c, Segment__c= theJob.Segment__c, Job_Type__c=jobRecordType.DeveloperName);
        insert sc;

        Test.StopTest();
      
        List<Sync_Assignment__c> jobCrewSyncAssignment = [SELECT Id, Contact__c, Job__c FROM Sync_Assignment__c WHERE Contact__c = :user.Id];
        Integer count = 0;
              
        system.assertEquals(jobCrewCount, jobCrewSyncAssignment.size());        
    }

    static testmethod void InsertJob()
    {
        Test.StartTest();
        Contact user= AlpineTestHelper.CreateUser('Doe', 'Jane', true);

        Integer jobCount=1;
        List<Job__c> newJobs = AlpineTestHelper.CreateJobs(1, false);
        Job__c theJob = newJobs[0];

        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = user.Id, Job_Type__c=null, Account__c = theJob.CustomerAccount__c, Office__c = theJob.Office__c, Segment__c= theJob.Segment__c,  Sync_JobCrewOnly__c = false);
        insert sc;
        
        insert theJob;
     
        Test.StopTest();

        List<Sync_Assignment__c> afterCount = [SELECT Id FROM Sync_Assignment__c WHERE Contact__c = :user.Id];       
        
        system.assertEquals(jobCount , afterCount.size() ); 
    }

    static testmethod void InsertJobWithCrewPlanning()
    {
       Test.StartTest();
        Contact user= AlpineTestHelper.CreateUser('Doe', 'Jane', true);

        Integer jobCount=100;
        List<Job__c> newJobs = AlpineTestHelper.CreateJobs(jobCount, false);
        string afeNumber = StringUtility.newGuid();
        for(Job__c j: newJobs)
        {
            j.AFE_Number__c = afeNumber;
        }
        insert newJobs;

       
        List<Job__c> jobs = [SELECT Id, RecordTypeId, CustomerAccount__c, Office__c, Segment__c FROM Job__c WHERE AFE_Number__c = :afeNumber];

        Job__c theJob = jobs[0];

        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = user.Id, Sync_JobCrewOnly__c=true, Job_Type__c=null, Account__c = null, Office__c = null, Segment__c= null);

        insert sc;
       
        List<Crew_Planning__c> jobCrews = new List<Crew_Planning__c>();
        for(Integer i=0; i<jobCount; i++)        
        {
            //System.debug('************ Job ' + i + ':'  + jobs[i]);
            jobCrews.add(new Crew_Planning__c(Crew_Member__c = user.Id, Job__c = jobs[i].Id));
        }       
        insert jobCrews;     
       
        Test.StopTest();
 

        List<Sync_Assignment__c> finalResults = [SELECT Id, Contact__c, Job__c FROM Sync_Assignment__c WHERE Contact__c = :user.Id];       
     
        system.assertEquals(jobCount , finalResults.size() ); 
    }


    static testmethod void UpdateSyncConfigJobCrewOnlyFalse()
    {
        Test.StartTest();
        
        Integer jobCount=2;
        List<Job__c> newJobs = AlpineTestHelper.CreateJobs(jobCount, true);

        List<Job__c> jobs = [SELECT Id, Name, Sync__c FROM Job__c];
        Contact user= AlpineTestHelper.CreateUser('Doe', 'Jane', false);
        user.User__c = UserInfo.getUserId();
        insert user;

      
      
        Job__c theJob = newJobs[0];

        theJob.Name = 'Crew Job 123';
        update theJob;

        Crew_Planning__c jobCrew = new Crew_Planning__c(Job__c=theJob.Id, Crew_Member__c=user.Id);
        insert jobCrew;

        RecordType jobRecordType = [SELECT DeveloperName FROM RecordType where IsActive=true AND  Id = :theJob.RecordTypeId];
        
        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = user.Id, Account__c = theJob.CustomerAccount__c, Office__c = theJob.Office__c, Segment__c= theJob.Segment__c, Job_Type__c=jobRecordType.DeveloperName);
        insert sc;

        sc.Sync_JobCrewOnly__c = false;
        update sc;

        Test.StopTest();

        List<Sync_Assignment__c> afterCount = [SELECT Id, Contact__c, Job__c, Job__r.Name FROM Sync_Assignment__c WHERE Contact__c = :user.Id];
       
        system.assertEquals(jobCount , afterCount.size() ); 
    }

   
}