@isTest
private class AuditLogTruncator_Test
{
	static testmethod void Schedulable_Test()
    { 
        Test.startTest();

        // This test runs a scheduled job at midnight March 15, 2054
        String CRON_EXP = '0 0 0 15 3 ? 2054';

        // Schedule the test job
        String jobId = System.schedule('AuditLogTruncatorScheduler_Test',
                        CRON_EXP, 
                        new AuditLogTruncatorScheduler());
         
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

    static testMethod void Batchable_NoFX_Setting_Test()
    {        
        Test.startTest();
        
        AuditLogTruncator b = new AuditLogTruncator();
        Database.executeBatch(b);
        Test.stopTest();
    }

    static testMethod void Batchable_WithFX_Setting_Test()
    {        
    	Test.startTest();

    	FX_Settings__c setting = FX_Settings__c.getInstance(UserInfo.getUserId());    
    	setting.AuditLogTypeForTruncation__c = 'SyncComplete,SyncDownloadComplete';
    	setting.AuditLogRetainingDays__c =  -1;
    	upsert setting;

    	List<Audit_Log__c> items = new List<Audit_Log__c>();
    	for(Integer i=0; i<100; i++)
    	{
    		items.add( new Audit_Log__c(Type__c = 'SyncComplete', Event_Date__c = Datetime.now().addMinutes(-10)));
    	}
    	insert items;

    	List<Audit_Log__c> dbItems = [SELECT Id FROM Audit_Log__c WHERE IsDeleted=false];
    	System.assert(dbItems.size()==100, 'should have 100 items instead of ' + dbItems.size());
       
        AuditLogTruncator b = new AuditLogTruncator();
        Database.executeBatch(b);
        Test.stopTest();

        dbItems = [SELECT Id FROM Audit_Log__c WHERE IsDeleted=false];
    	System.assert(dbItems.isEmpty(), 'should have no item after deletion, instead of ' + dbItems.size());
    }

    static testMethod void Batchable_DryRun_Test()
    {        
        Test.startTest();
        AuditLogTruncator b = new AuditLogTruncator();
        b.DryRun();
        Test.stopTest();
    }

}