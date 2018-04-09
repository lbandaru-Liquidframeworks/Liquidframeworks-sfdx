@isTest
private class JobBuilder_Test 
{    

    static testmethod void Initialize_Test()
    {
        Test.StartTest();
        string newGuid = StringUtility.newGuid();

        RecordType officeRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = 'Account' and DeveloperName = 'office' ];

        Account office = new Account(name= 'Office ' + StringUtility.newGuid(), RecordTypeId = officeRecordType.Id);

        insert office;
    
        Account a = new Account(Name = 'Acct ' + newGuid);
        string priceListName = 'Price List ' + newGuid;
        Price_Book__c pl = new Price_Book__c(Name = priceListName);
        insert a;
        insert pl;
        
      
        Price_Book__c priceBook = [SELECT Id FROM Price_Book__c WHERE Name =:priceListName LIMIT 1]; 
              

        String objType = UtilityGetNamespace.CurrentNamespace()  + 'Status__c';
        RecordType rtStatus = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SObjectType = :objType LIMIT 1];

        String jobObjType = UtilityGetNamespace.CurrentNamespace()  + 'Job__c';
        RecordType rtJob = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SObjectType = :jobObjType LIMIT 1];


        string statusName = 'JobStatus ' + newGuid;
        Status__c consoleStatus = new Status__c(Name = 'console' + statusName, SObject__c='Job__c', SObject_Record_Type__c= rtJob.DeveloperName, Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=rtStatus.Id);
        insert consoleStatus;

        Status__c mobileStatus = new Status__c(Name = 'mobile' + statusName, SObject__c='Job__c', SObject_Record_Type__c= rtJob.DeveloperName, Sync__c=true, Initial_Status_Mobile__c =true,  RecordTypeId=rtStatus.Id);
        insert mobileStatus;       
               
           
          
        string consoleJobName = StringUtility.newGuid();
        string mobileJobName = StringUtility.newGuid();

        Job__c j1 = new Job__c(Name= consoleJobName, CustomerAccount__c = a.Id, Office__c = office.Id, Price_Book__c = priceBook.Id, Segment__c='Default', RecordTypeId= rtJob.Id); 

        Job__c j2 = new Job__c(Name= mobileJobName, Created_in_Mobile__c = true, CustomerAccount__c = a.Id, Office__c = office.Id, Price_Book__c = priceBook.Id, Segment__c='Default', RecordTypeId= rtJob.Id); 

        insert j1;
        insert j2;
        Test.StopTest();

        Job__c consoleJob = [SELECT Tracking_Number__c, SyncID__c, Status__c FROM Job__c where Name = :consoleJobName LIMIT 1];
        
        System.assert(StringUtility.isValidTrackingNumber(StringUtility.EntityObjectType.Job, consoleJob.Tracking_Number__c));

        System.assert(consoleJob.SyncID__c != null);

        System.assert(consoleJob.Status__c == consoleStatus.Id);


        Job__c mobileJob = [SELECT Tracking_Number__c, SyncID__c, Status__c FROM Job__c where Name = :mobileJobName LIMIT 1];
        
        System.assert(StringUtility.isValidTrackingNumber(StringUtility.EntityObjectType.Job, mobileJob.Tracking_Number__c));

        System.assert(mobileJob.SyncID__c != null);

        System.assert(mobileJob.Status__c == mobileStatus.Id);
    }
    

    static testmethod void UpdateJob_SyncStatus_Test()
    {
       
        Test.StartTest();
        
        Integer jobCount = 200;
        List<Job__c> newJobs = AlpineTestHelper.CreateJobs(jobCount, false);

        String newGuid = StringUtility.newGuid();   

        String objType = UtilityGetNamespace.CurrentNamespace()  + 'Status__c';
        RecordType rt = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SObjectType = :objType LIMIT 1];

        String jobObjType = UtilityGetNamespace.CurrentNamespace()  + 'Job__c';
        RecordType rtJob = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SObjectType = :jobObjType LIMIT 1];

    
        Status__c noSyncStatus = new Status__c(Name = 'noSync' + newGuid, SObject__c='Job__c', SObject_Record_Type__c = rtJob.DeveloperName, Initial_Status_Console__c =false, Sync__c = false, Initial_Status_Mobile__c=false, RecordTypeId=rt.Id);

        Status__c syncStatus = new Status__c(Name = 'Sync' + newGuid, SObject__c='Job__c', SObject_Record_Type__c = rtJob.DeveloperName, Initial_Status_Console__c =false, Sync__c = true, Initial_Status_Mobile__c=false, RecordTypeId=rt.Id);

        insert syncStatus;
        insert noSyncStatus;

        for(Job__c j : newJobs)
        {
            j.Name = newGuid;
            j.RecordTypeId = rtJob.Id;
            j.Status__c = noSyncStatus.Id;
        }
        insert newJobs;

      
        
        List<Job__c> dbJobs = [SELECT Id, Sync__c, Status__c FROM Job__c WHERE Status__c = :noSyncStatus.Id AND Sync__c=false];  

        System.assertEquals(jobCount, dbJobs.size());

        for(Job__c j:dbJobs)
        {
            j.Status__c = syncStatus.Id;            
        }
        update dbJobs;  
      
       
        Test.StopTest();

        List<Job__c> results = [SELECT Id, Sync__c, Status__c FROM Job__c WHERE Sync__c=true AND Status__c = :syncStatus.Id];   

        System.assertEquals(jobCount, results.size());        
    }


    static testmethod void UpdateJob_NoSyncStatus_Test()
    {
       
        Test.StartTest();
        Integer jobCount = 200;

        List<Job__c> newJobs = AlpineTestHelper.CreateJobs(jobCount, false);

        String newGuid = StringUtility.newGuid();  

        String objType = UtilityGetNamespace.CurrentNamespace()  + 'Status__c';
        RecordType rt = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SObjectType=:objType LIMIT 1];
    
        String jobObjType = UtilityGetNamespace.CurrentNamespace()  + 'Job__c';
        RecordType rtJob = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SObjectType = :jobObjType LIMIT 1];


        Status__c noSyncStatus = new Status__c(Name = 'noSync' + newGuid, SObject__c='Job__c', SObject_Record_Type__c=rtJob.DeveloperName, Initial_Status_Console__c=true, Sync__c=false, Initial_Status_Mobile__c=false, RecordTypeId=rt.Id);

        Status__c syncStatus = new Status__c(Name = 'Sync' + newGuid, SObject__c='Job__c', SObject_Record_Type__c=rtJob.DeveloperName, Initial_Status_Console__c=false, Sync__c=true, Initial_Status_Mobile__c=true, RecordTypeId=rt.Id);

        insert syncStatus;
        insert noSyncStatus;

        for(Job__c j : newJobs)
        {
            j.RecordTypeId = rtJob.Id;
            j.Status__c = syncStatus.Id;
        }
        insert newJobs;

        List<Job__c> dbJobs = [SELECT Id, Sync__c, Status__c FROM Job__c WHERE Status__c =:syncStatus.Id AND Sync__c=true];       
        System.assertEquals(jobCount, dbJobs.size());

        for(Job__c j:dbJobs)
        {
            j.Status__c = noSyncStatus.Id;            
        }
        update dbJobs;  
      
        Test.StopTest();
 
        List<Job__c> results = [SELECT Id, Sync__c, Status__c FROM Job__c WHERE Sync__c=false AND Status__c = :noSyncStatus.Id];   

        System.assertEquals(jobCount, results.size());        
    }

    static testmethod void AutoAddJobCreatorToCrew_Test()
    {       
        Test.StartTest();
        FX_Settings__c fs = FX_Settings__c.getOrgDefaults();
        fs.SetupOwnerId = UserInfo.getOrganizationId();
        fs.AutoAddJobCreatorToCrew__c = true;
        insert fs;

        Id userId = UserInfo.getUserId();
        Contact c= null;

        List<Contact> contacts = [SELECT Id FROM Contact WHERE User__c = :userId];
        if(contacts.isEmpty())
        {
            c = AlpineTestHelper.CreateContactWithNoUser('Jane', 'Joe', false);
            c.User__c = userId;
            c.Available_for_Field_Work__c = true;
            insert c;
        }
        else
        {
            c = contacts.get(0);
        }

        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        Test.StopTest();

        List<Crew_Planning__c> cps = [SELECT Id FROM Crew_Planning__c WHERE Job__c = :j.Id AND Crew_Member__c = :c.Id];
        System.assert(cps.size()==1);
    }

    static testmethod void AutoAddJobCreatorToCrew_Negative_Test()
    {       
        Test.StartTest();
        FX_Settings__c fs = FX_Settings__c.getOrgDefaults();
        fs.SetupOwnerId = UserInfo.getOrganizationId();
        fs.AutoAddJobCreatorToCrew__c = false;
        insert fs;
        
        Id userId = UserInfo.getUserId();
        Contact c= null;

        List<Contact> contacts = [SELECT Id FROM Contact WHERE User__c = :userId];
        if(contacts.isEmpty())
        {
            c = AlpineTestHelper.CreateContactWithNoUser('Jane', 'Joe', false);
            c.User__c = userId;
            c.Available_for_Field_Work__c = true;
            insert c;
        }
        else
        {
            c = contacts.get(0);
        }

        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        Test.StopTest();

        List<Crew_Planning__c> cps = [SELECT Id FROM Crew_Planning__c WHERE Job__c = :j.Id AND Crew_Member__c = :c.Id];
        System.assert(cps.isEmpty());
    }

    //contact with Available_for_Field_Work__c = false
    static testmethod void AutoAddJobCreatorToCrew_Negative_Test2()
    {       
        Test.StartTest();
        FX_Settings__c fs = FX_Settings__c.getOrgDefaults();
        fs.SetupOwnerId = UserInfo.getOrganizationId();
        fs.AutoAddJobCreatorToCrew__c = true;
        insert fs;
        
        Id userId = UserInfo.getUserId();
        Contact c= null;

        List<Contact> contacts = [SELECT Id FROM Contact WHERE User__c = :userId];
        if(contacts.isEmpty())
        {
            c = AlpineTestHelper.CreateContactWithNoUser('Jane', 'Joe', false);
            c.User__c = userId;
            c.Available_for_Field_Work__c = false;
            insert c;
        }
        else
        {
            c = contacts.get(0);
        }

        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        Test.StopTest();

        List<Crew_Planning__c> cps = [SELECT Id FROM Crew_Planning__c WHERE Job__c = :j.Id AND Crew_Member__c = :c.Id];
        System.assert(cps.isEmpty());
    }
    
}