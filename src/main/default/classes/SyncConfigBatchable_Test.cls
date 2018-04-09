@isTest
private class SyncConfigBatchable_Test
{
    static testmethod void runTest()
    {
        Test.StartTest();
       
        Integer jobCount=1;
        List<Job__c> newJobs = AlpineTestHelper.CreateJobs(jobCount, true);       
        Contact user= AlpineTestHelper.CreateUser('Doe', 'Jane', true);
      

        List<Job__c> jobs = [SELECT Id, CustomerAccount__c, Office__c, Segment__c, Sync__c, RecordTypeId FROM Job__c];      
       
           
        Job__c theJob = jobs[0];  

        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = user.Id, Account__c = theJob.CustomerAccount__c, Office__c = theJob.Office__c, Segment__c= theJob.Segment__c);
        insert sc;
        
       SyncConfigBatchable_UpdateExternalIds b = new SyncConfigBatchable_UpdateExternalIds();
       Database.executeBatch(b, 200);
    }
}