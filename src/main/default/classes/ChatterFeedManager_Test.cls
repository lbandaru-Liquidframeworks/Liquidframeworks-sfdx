@isTest
private class ChatterFeedManager_Test
{

   static void turnOnAutoFollowJobTicket()
   {
      if(!Schema.SObjectType.User.isFeedEnabled())
      {
          throw new AlpineTestHelper.TesterException('Chatter is NOT on in the org');
      }
      if(!Schema.SObjectType.Job__c.isFeedEnabled())
      {
           throw new AlpineTestHelper.TesterException('Job__c Chatter Feed Tracking  is OFF on in the org');
      }     
      if(!Schema.SObjectType.Ticket__c.isFeedEnabled())
      {
           throw new AlpineTestHelper.TesterException('Job__c Chatter Feed Tracking  is OFF on in the org');
      }

      if(!FX_Settings__c.getOrgDefaults().AutoFollowJobTicket__c)
      {
        FX_Settings__c fs = new FX_Settings__c();
        fs.SetupOwnerId = UserInfo.getOrganizationId();
        fs.AutoFollowJobTicket__c = true;
        insert fs;
      }
   }

   
   static testMethod void FollowNewJob_NoTicket() 
   { 
       System.debug('FollowNewJob_NoTicket');

        Test.StartTest();
        turnOnAutoFollowJobTicket();
        Contact cp = AlpineTestHelper.CreateContactWithTestUser('Doe', 'Jane', true);
        Id userId = cp.User__c;

        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
       
        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = cp.Id, Sync_JobCrewOnly__c=true, Job_Type__c=null, Account__c = null, Office__c = null, Segment__c= null);

        insert sc;
       
        insert new Crew_Planning__c(Crew_Member__c = cp.Id, Job__c = job.Id);
       
        Test.StopTest();


        List<EntitySubscription> items = [select Id, parentid, subscriberid from EntitySubscription 
               where subscriberid = :userId AND parentid = :job.Id ];

        if(ChatterFeedManager.AutoFollowJob(userId)) System.assert(items.size() == 1);

   }
  

   static testMethod void FollowNewJob_WithTicket() 
   { 
     System.debug('FollowNewJob_WithTicket');

        Test.StartTest();
        turnOnAutoFollowJobTicket();
        Contact cp = AlpineTestHelper.CreateContactWithTestUser('Doe', 'Jane', true);
        Id userId = cp.User__c;

        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = cp.Id, Sync_JobCrewOnly__c=true, Job_Type__c=null, Account__c = null, Office__c = null, Segment__c= null);

        insert sc;

        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        System.debug('JobID=' + job.Id);
       
        Integer tktCount = 20;
        List<Ticket__c> tkts = AlpineTestHelper.CreateTickets(job, tktCount, true);     
       

        insert new Crew_Planning__c(Crew_Member__c = cp.Id, Job__c = job.Id);
       
        Test.StopTest();

        List<Ticket__c> tkts2 = [SELECT Id, Sync__c FROM Ticket__c where Job__c = :job.Id AND Sync__c=true];
        System.assertEquals(tktCount, tkts2.size());

        Set<Id> tktIds = new Map<Id, Ticket__c>(tkts).keySet();

        List<EntitySubscription> items = [select Id, parentid, subscriberid from EntitySubscription 
               where subscriberid = :userId AND (parentid = :job.Id OR parentid IN :tktIds)];
        
        Integer totalCount =0;
        if(Schema.SObjectType.Job__c.isFeedEnabled())
        {
           totalCount += 1;
        }
        if(Schema.SObjectType.Ticket__c.isFeedEnabled())
        {
           totalCount += tktCount;
        }

        if(ChatterFeedManager.AutoFollowJob(userId)) System.assertEquals(totalCount,  items.size());
   }

   
    static testMethod void FollowNewTicket_UponInsert() 
    {  
     System.debug('FollowNewTicket_UponInsert');
    
        turnOnAutoFollowJobTicket(); 
         Contact cp = AlpineTestHelper.CreateContactWithTestUser('Doe', 'Jane', true);
         Id userId = cp.User__c;

        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = cp.Id, Sync_JobCrewOnly__c=true, Job_Type__c=null, Account__c = null, Office__c = null, Segment__c= null);

        insert sc;

        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);       
        insert new Crew_Planning__c(Crew_Member__c = cp.Id, Job__c = job.Id);
      
        Test.StartTest();
        

        List<EntitySubscription> items = [select Id, parentid, subscriberid from EntitySubscription 
               where subscriberid = :userId AND parentid = :job.Id];

      if(ChatterFeedManager.AutoFollowJob(userId))  System.assert(items.size() ==1);
        
        Integer tktCount = 20;
        List<Ticket__c> tkts = AlpineTestHelper.CreateTickets(job, tktCount, true);     
            

        Set<Id> tktIds = new Map<Id, Ticket__c>(tkts).keySet();

        Test.StopTest();

         items = [select Id, parentid, subscriberid from EntitySubscription 
               where subscriberid = :userId AND parentid IN :tktIds];


        Integer totalCount =0;       
        if(Schema.SObjectType.Ticket__c.isFeedEnabled())
        {
           totalCount += tktCount;
        }


        if(ChatterFeedManager.AutoFollowJob(userId))  System.assertEquals(totalCount,  items.size());
      
   }

   static testMethod void UnfollowNewJob_NoTicket() 
   { 
     System.debug('UnfollowNewJob_NoTicket');

         turnOnAutoFollowJobTicket();
        Contact cp = AlpineTestHelper.CreateContactWithTestUser('Doe', 'Jane', true);
        Id userId = cp.User__c;

        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
       
        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = cp.Id, Sync_JobCrewOnly__c=true, Job_Type__c=null, Account__c = null, Office__c = null, Segment__c= null);

        insert sc;
       
        insert new Crew_Planning__c(Crew_Member__c = cp.Id, Job__c = job.Id);
       
        Test.StartTest();
       

        List<EntitySubscription> items = [select Id, parentid, subscriberid from EntitySubscription 
               where subscriberid = :userId AND parentid = :job.Id ];

        if(ChatterFeedManager.AutoFollowJob(userId)) System.assert(items.size() == 1);

        Job__c dbJob = [SELECT Status__c, Status__r.RecordTypeId FROM Job__c WHERE Id = :job.Id LIMIT 1];

        string statusName = 'NoSyncJobStatus ' + dbJob.Status__c;

        Status__c st = new Status__c(Name = statusName, SObject__c='Job__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=dbJob.Status__r.RecordTypeId);
        insert st;

        dbjob.Status__c = st.Id;
        update dbJob;

        Test.StopTest();


    items = [select Id, parentid, subscriberid from EntitySubscription 
               where subscriberid = :userId AND parentid = :job.Id ];

        if(ChatterFeedManager.AutoFollowJob(userId)) System.assert(items.size() == 0);

   }


   static testMethod void UnfollowNewJob_WithTicket() 
   { 
         System.debug('UnfollowNewJob_WithTicket');

         turnOnAutoFollowJobTicket();
        Contact cp = AlpineTestHelper.CreateContactWithTestUser('Doe', 'Jane', true);
        Id userId = cp.User__c;

        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = cp.Id, Sync_JobCrewOnly__c=true, Job_Type__c=null, Account__c = null, Office__c = null, Segment__c= null);

        insert sc;

        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
       
        Integer tktCount = 20;
        List<Ticket__c> tkts = AlpineTestHelper.CreateTickets(job, tktCount, true);     
       

        insert new Crew_Planning__c(Crew_Member__c = cp.Id, Job__c = job.Id);
       
      

        Set<Id> tktIds = new Map<Id, Ticket__c>(tkts).keySet();     

        Test.StartTest();
       

        List<EntitySubscription> items = [select Id, parentid, subscriberid from EntitySubscription 
               where subscriberid = :userId AND (parentid = :job.Id OR parentid IN :tktIds)];

        if(ChatterFeedManager.AutoFollowJob(userId)) System.assertEquals(tktCount + 1,  items.size());

        Job__c dbJob = [SELECT Status__c, Status__r.RecordTypeId FROM Job__c WHERE Id = :job.Id LIMIT 1];

        string statusName = 'NoSyncJobStatus ' + dbJob.Status__c;

        Status__c st = new Status__c(Name = statusName, SObject__c='Job__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=dbJob.Status__r.RecordTypeId);
        insert st;

        dbjob.Status__c = st.Id;
        update dbJob;

        Test.StopTest();

        items = [select Id, parentid, subscriberid from EntitySubscription 
               where subscriberid = :userId AND (parentid = :job.Id OR parentid IN :tktIds)];

        if(ChatterFeedManager.AutoFollowJob(userId))  System.assert(items.size() == 0);       
   }

   static testMethod void UnfollowTicket_UponTicketSyncOff() 
   { 
        System.debug('UnfollowTicket_UponTicketSyncOff');

        turnOnAutoFollowJobTicket();
        Contact cp = AlpineTestHelper.CreateContactWithTestUser('Doe', 'Jane', true);
        Id userId = cp.User__c;

        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = cp.Id, Sync_JobCrewOnly__c=true, Job_Type__c=null, Account__c = null, Office__c = null, Segment__c= null);

        insert sc;

        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        insert new Crew_Planning__c(Crew_Member__c = cp.Id, Job__c = job.Id);
       
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, true).get(0); 

        Test.StartTest();
        

        List<EntitySubscription> items = [select Id, parentid, subscriberid from EntitySubscription 
               where subscriberid = :userId AND parentid = :tkt.Id];

        if(ChatterFeedManager.AutoFollowJob(userId)) System.assertEquals(1,  items.size());

        Ticket__c dbTkt = [SELECT Id, Sync__c, Status__c, Status__r.RecordTypeId FROM Ticket__c WHERE Id = :tkt.Id LIMIT 1];

        System.debug('tkt=' + dbTkt);

        System.assert(dbTkt.Sync__c);

        string statusName = 'NoSyncJobStatus ' + dbTkt.Status__c;

        Status__c st = new Status__c(Name = statusName, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=dbTkt.Status__r.RecordTypeId);
        insert st;

        dbTkt.Status__c = st.Id;
        update dbTkt;

        dbTkt = [SELECT Id, Sync__c, Status__c, Status__r.RecordTypeId FROM Ticket__c WHERE Id = :tkt.Id LIMIT 1];

        System.debug('after update, tkt=' + dbTkt);

        Test.StopTest();

        List<Sync_Assignment__c> jobSubs = [SELECT Contact__c, Contact__r.User__c, Job__c from Sync_Assignment__c WHERE Job__c =:job.Id AND Contact__r.User__c=:userId];
        System.assertEquals(1, jobSubs.size());
       

        Ticket__c dbTkt2 = [SELECT Sync__c, Status__c FROM Ticket__c WHERE Id = :tkt.Id LIMIT 1];
        System.assertEquals(st.Id, dbTkt2.Status__c);
        System.assert(!dbTkt2.Sync__c);


        items =  [select Id, parentid, subscriberid from EntitySubscription 
               where subscriberid = :userId AND parentid = :tkt.Id];

        if(ChatterFeedManager.AutoFollowJob(userId)) System.assertEquals(0, items.size());       
   }


}