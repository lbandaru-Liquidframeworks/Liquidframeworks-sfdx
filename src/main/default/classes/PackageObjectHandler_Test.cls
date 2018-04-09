@isTest
private class PackageObjectHandler_Test
{
    static testMethod void AuditLog_Edit_Test()
    {
       Test.startTest();
       Audit_Log__c log = new Audit_Log__c(Event_Date__c = Datetime.now(), Message__c='Unit test');
       insert log;

       Audit_Log__c dbLog = [SELECT Id, Event_Date__c,  Message__c FROM Audit_Log__c WHERE Id=: log.Id];


       try
       {
            dbLog.Message__c = 'Edit AuditLog';
            update dbLog;
       }
       catch(Exception ex)
       {
            System.assert(ex.getMessage().contains('All Built-in fields are not updateable.'));

            //System.assertEquals('All Built-in fields are not updateable.', ex.getMessage());
       }
       Test.stopTest();
    }

    static testMethod void AuditLog_Edit_Test2()
    {
       Test.startTest();
       Audit_Log__c log = new Audit_Log__c(Cleared__c = false, Event_Date__c = Datetime.now(), Message__c='Unit test');
       insert log;

       Audit_Log__c dbLog = [SELECT Id, Cleared__c FROM Audit_Log__c WHERE Id=: log.Id];

       Boolean didThrow = false;
       try
       {
          dbLog.Cleared__c = true;
          update dbLog;
       }
       catch(Exception ex)
       {
          //System.assert(!ex, 'Should not throw an error.');
          didThrow = true;
       }
       System.assert(didThrow==false, 'Should not throw an error.');
       Test.stopTest();
    }

    static testMethod void AuditLog_Delete_Test()
    {
       Test.startTest();
       Audit_Log__c log = new Audit_Log__c(Event_Date__c = Datetime.now(), Message__c='Unit test');
       insert log;

       Audit_Log__c dbLog = [SELECT Id, Event_Date__c,  Message__c FROM Audit_Log__c WHERE Id=: log.Id];


       try
       {
            delete dbLog;
       }
       catch(Exception ex)
       {
            System.assert(ex.getMessage().contains('Delete is not allowed.'));
       }
       Test.stopTest();
    }


    static testMethod void StatusHistory_Edit_Test()
    {
       Test.startTest();
       PrepareJobStatusHistory();
       Test.stopTest();

       Status_History__c sh = [SELECT Id, Job__c FROM Status_History__c LIMIT 1];
       Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);

       try
       {
            sh.Job__c = job.Id;
            update sh;
       }
       catch(Exception ex)
       {
            System.assert(ex.getMessage().contains('All Built-in fields are not updateable.'));
            //System.assertEquals('All Built-in fields are not updateable.', ex.getMessage());
       }

    }

    static testMethod void StatusHistory_Delete_Test()
    {
       Test.startTest();
       PrepareJobStatusHistory();
       Test.stopTest();

       Status_History__c sh = [SELECT Id, Job__c FROM Status_History__c LIMIT 1];

       try
       {
            delete sh;
       }
       catch(Exception ex)
       {
            System.assert(ex.getMessage().contains('Delete is not allowed.'));
       }

    }

    static void PrepareJobStatusHistory()
    {
         Integer jobCount = 2;
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

        for(Job__c j:dbJobs)
        {
            j.Status__c = syncStatus.Id;
        }
        update dbJobs;
    }

}
