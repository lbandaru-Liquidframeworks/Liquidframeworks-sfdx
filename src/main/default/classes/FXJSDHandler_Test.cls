@isTest
private class FXJSDHandler_Test
{
    static testmethod void runTest()
    {
        FXJSDHandler h = new FXJSDHandler();
        FXJSDHandler h1 = new FXJSDHandler(new FXBaseController());        
        Boolean hasLicense =  h1.jsdLicense;
        Boolean faMapLicense =  h1.fxmapLicense;

        Boolean jsdLicense = FXJSDHandler.hasJsdLicense();

        
        FXBaseController c  = new FXBaseController();
        String ns = c.getNamespace();
        String ns2= c.getNamespaceWithoutUnderscores();
        
        String userInfo = c.getFxUserInfo();
        
        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        
        String ns3 = ns.replace('__', '.');

        Map<String, String> params = new Map<String, String>();
        params.put('service', ns + 'JobQualificationService');
        params.put('method', 'getjobqualifications');
        params.put('jobId', j.Id);


        
        SvcResult  r = FXJSDHandler.doWork(JSON.serialize(params));
        SvcResult  r2 = FXJSDHandler.getJobQualifications(String.valueOf(j.Id));        
        
    }
    
    static testmethod void queryObject_Test()
    {
        Test.startTest();
        Integer jobCount = 10;
        List<Job__c> jobs = AlpineTestHelper.CreateJobs(jobCount, true);
        Set<Id> jobIds = new Map<Id, Job__c>(jobs).keySet();
        
        
        String soql = 'SELECT Id FROM [ns]Job__c';
        soql = soql.replace('[ns]', UtilityGetNamespace.CurrentNamespace());
        
        List<sObject> dbObjs = FXJSDHandler.queryObject(soql);       
        Test.stopTest();
        System.assert(dbObjs.size() == jobCount, 'Should have ' + jobCount + ' items');
        for(Integer i=0; i<jobCount; i++)
        {
            System.assert(jobIds.contains(dbObjs.get(i).Id), 'Item id should match');
        }
    }
   
    static testmethod void upsertObject_InsertTest() 
    {
        Test.startTest();
        Job__c j = AlpineTestHelper.CreateJobs(1, false).get(0);
        Database.upsertResult r = FXJSDHandler.upsertObject(j);

        Job__c j2 = AlpineTestHelper.CreateJobs(1, false).get(0);
        Database.saveResult r2 = FXJSDHandler.insertObject(j2);

        Test.stopTest();
    }
    
    static testmethod void upsertObject_updateTest() 
    {
        Test.startTest();
        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        Database.upsertResult r = FXJSDHandler.upsertObject(j);

        Job__c j2= AlpineTestHelper.CreateJobs(1, true).get(0);
        List<String> fieldsToNull = new List<String>();
        fieldsToNull.add(UtilityGetNamespace.CurrentNamespace() + 'Notes__c');
        Database.SaveResult r2 = FXJSDHandler.updateObject(j2, fieldsToNull);

        Test.stopTest();
    }
     
    static testmethod void  deleteObject_Test() 
    {
        Test.startTest();
        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        Database.DeleteResult r = FXJSDHandler.deleteObject(j);
        Test.stopTest();
        
        List<Job__c> jobs = [SELECT Id FROM Job__c WHERE Id=:j.Id];
        System.assert(jobs.isEmpty(), 'Item should have been deleted');
    }
     

     static testmethod void insertObjects_Test() 
     {
        Test.startTest();
        Integer jobCount = 10;
        List<Job__c> jobs = AlpineTestHelper.CreateJobs(jobCount , false);
        Database.SaveResult[] results = FXJSDHandler.insertObjects(jobs, false);
        Test.stopTest();
        System.assert(results.size() == jobCount, 'Should have ' + jobCount + ' items');
     }
    
     static testmethod void updateObjects_Test()
     {
        Test.startTest();
        Integer jobCount = 10;
        List<Job__c> jobs = AlpineTestHelper.CreateJobs(jobCount , true);
        Database.SaveResult[] results = FXJSDHandler.updateObjects(jobs, false);
        Test.stopTest();
        System.assert(results.size() == jobCount, 'Should have ' + jobCount + ' items');
     }
     
     static testmethod void deleteObjects_Test()
     {
        Test.startTest();
        Integer jobCount = 10;
        List<Job__c> jobs = AlpineTestHelper.CreateJobs(jobCount , true);
        Database.DeleteResult[] results = FXJSDHandler.deleteObjects(jobs, false);
        Test.stopTest();
        System.assert(results.size() == jobCount, 'Should have ' + jobCount + ' DeleteResult items');
        
     }
}