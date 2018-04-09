@isTest
private class RollupInfoHandler_Test
{
    static testmethod void TestFXWorker()
    {
        Test.startTest();
        String ns = StringUtility.FXNamespace().replace('__', '.');
        
        FXWorkerLauncher.DoWork(ns + 'RollupInfoHandler', null);
        
        Test.stopTest();
    }
    
    static testmethod void TestSchedulable()
    {      
        
        Test.startTest();

        // This test runs a scheduled job at midnight March 15, 2054
        String CRON_EXP = '0 0 0 15 3 ? 2054';

        // Schedule the test job
        String jobId = System.schedule('RollupInfoHandler_Test',
                        CRON_EXP, 
                        new RollupInfoHandler());
         
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        // Verify the next time the job will run
        System.assertEquals('2054-03-15 00:00:00', String.valueOf(ct.NextFireTime));      
        Test.stopTest();
        
        
    }
    
    static testmethod void UpsertRollupFieldsStaticResource_Test()
    {
        String resourceName= StringUtility.newGuid();
        Test.startTest();
        RollupInfoHandler.RefreshRollupSummary();
        Test.stopTest();
        //List<StaticResource> items = [SELECT Id FROM StaticResource WHERE Name=:resourceName];
        //System.assert(items.size() == 1, 'should have one entry for rollup summary, instead of ' + items.size());
    }
    
}