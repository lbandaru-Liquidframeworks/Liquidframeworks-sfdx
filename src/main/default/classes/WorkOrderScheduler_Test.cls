@isTest
private class WorkOrderScheduler_Test
{
    static testMethod void ScheduleWorkOrder_Test1()
    {
        InitData('AND', true);
        Test.startTest();
        WorkOrderSchedulerBatchable b = new WorkOrderSchedulerBatchable(null);
        Database.executeBatch(b);
        Test.stopTest();

        List<Work_Order__c> results = [SELECT Id FROM Work_Order__c WHERE IsTemplate__c = false];
        System.assertEquals(results.size(), 1);

        Id workOrderId = results.get(0).Id;
        List<sObject> items = [SELECT Id FROM Work_Order_Item__c WHERE Work_Order__c = :workOrderId];
        System.assertEquals(items.size(), 1);

        items = [SELECT Id FROM Work_Order_Task__c WHERE Work_Order__c = :workOrderId];
        System.assertEquals(items.size(), 1);

        items = [SELECT Id FROM Work_Order_Qualification__c WHERE Work_Order_Task__r.Work_Order__c = :workOrderId];
        System.assertEquals(items.size(), 1);


    }

    static testMethod void ScheduleWorkOrder_Test2()
    {
        InitData('AND', false);
        Test.startTest();
        WorkOrderSchedulerBatchable b = new WorkOrderSchedulerBatchable(null);
        Database.executeBatch(b);
        Test.stopTest();

        List<Work_Order__c> results = [SELECT Id FROM Work_Order__c WHERE IsTemplate__c = false];
        System.assertEquals(results.size(), 0);

    }


    static testMethod void ScheduleWorkOrder_Test3()
    {
        InitData('OR', false);
        Test.startTest();
        WorkOrderSchedulerBatchable b = new WorkOrderSchedulerBatchable(null);
        Database.executeBatch(b);
        Test.stopTest();

        List<Work_Order__c> results = [SELECT Id, RecordTypeId FROM Work_Order__c WHERE IsTemplate__c = false];
        System.assertEquals(results.size(), 1);

        List<Work_Order__c> results2 = [SELECT Id, RecordTypeId FROM Work_Order__c WHERE IsTemplate__c = true];
        System.assertEquals(results2.size(), 1);

        System.assert(!String.isBlank(results2[0].RecordTypeId), 'Template WordOrder should have RecordTypeId (not null).' );

        System.assert(results[0].RecordTypeId == results2[0].RecordTypeId, 'Template WorkOrder RecordType should be copied to the new work order');



    }

    static testmethod void Schedulable_Test()
    { 
      Test.startTest();

      // This test runs a scheduled job at midnight March 15, 2054
      String CRON_EXP = '0 0 0 15 3 ? 2054';

        // Schedule the test job
        String jobId = System.schedule('ScheduleTimecardTaxableLocationTest',
                        CRON_EXP, 
                        new WorkOrderScheduler());
         
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

    static testMethod void Equipment_NoCriteriaFieldUpdateTest()
    {
        InitData('OR', true);
        Test.startTest();

        List<Equipment__c> items = [SELECT Id, Unit_Number__c FROM Equipment__c];
        Database.update(items);
        Test.stopTest();

        List<Work_Order__c> results = [SELECT Id FROM Work_Order__c WHERE IsTemplate__c = false];
        System.assertEquals(results.size(), 0);
    }

    static testMethod void Equipment_CriteriaFieldUpdateTest()
    {
        InitData('OR', true);
        Test.startTest();

        List<Equipment__c> items = [SELECT Id, Unit_Number__c, Manufactured_Date__c FROM Equipment__c];
        for(Equipment__c e : items)
        {
            e.Manufactured_Date__c = Date.valueOf('2010-04-26');
        }
        Database.update(items);
        Test.stopTest();

        List<Work_Order__c> results = [SELECT Id FROM Work_Order__c WHERE IsTemplate__c = false];
        System.assertEquals(results.size(), 1);


    }


    static testMethod void PMC_TrggerTest()
    {
        InitData('OR', true);
        Test.startTest();
        Preventative_Maintenance_Criterion__c pmc = [SELECT Id, Effective_Date__c, Evaluation_Timestamp__c FROM Preventative_Maintenance_Criterion__c LIMIT 1];
       
        Datetime now = Datetime.now();
        pmc.Evaluation_Timestamp__c = now;
        pmc.Calender_UOM__c = 'Year';
        pmc.Calender_Interval__c = 1;
        update pmc;
        Preventative_Maintenance_Criterion__c dbPmc = [SELECT Id, Next_Run__c FROM Preventative_Maintenance_Criterion__c WHERE Id=:pmc.Id];
        System.assertEquals(now.addYears(1), dbPmc.Next_Run__c);


        pmc.Evaluation_Timestamp__c = now;
        pmc.Calender_UOM__c = 'Month';
        pmc.Calender_Interval__c = 1;           
        update pmc;

        dbPmc = [SELECT Id, Next_Run__c FROM Preventative_Maintenance_Criterion__c WHERE Id=:pmc.Id];
        System.assertEquals(now.addMonths(1), dbPmc.Next_Run__c);

        pmc.Evaluation_Timestamp__c = now;
        pmc.Calender_UOM__c = 'Day';
        pmc.Calender_Interval__c = 1;
        update pmc;
        dbPmc = [SELECT Id, Next_Run__c FROM Preventative_Maintenance_Criterion__c WHERE Id=:pmc.Id];
        System.assertEquals(now.addDays(1), dbPmc.Next_Run__c);


        pmc.Evaluation_Timestamp__c = now;
        pmc.Calender_UOM__c = 'Hour';
        pmc.Calender_Interval__c = 1;
        update pmc;
        dbPmc = [SELECT Id, Next_Run__c FROM Preventative_Maintenance_Criterion__c WHERE Id=:pmc.Id];
        System.assertEquals(now.addHours(1), dbPmc.Next_Run__c);

        pmc.Evaluation_Timestamp__c = now;
        pmc.Calender_UOM__c = 'Minute';
        pmc.Calender_Interval__c = 1;
        update pmc;
        dbPmc = [SELECT Id, Next_Run__c FROM Preventative_Maintenance_Criterion__c WHERE Id=:pmc.Id];
        System.assertEquals(now.addMinutes(1), dbPmc.Next_Run__c);


        Test.stopTest();

    }

    static testMethod void EvalValues_Test()
    {        
        Test.startTest();

        Schema.DisplayType type = Schema.DisplayType.Double;
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '=', 10, 10));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '==', 10, 10));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '>', 10, 9));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '>=', 10, 9));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '<', 9, 10));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '<=', 9, 10));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '!=', 9, 10));

        type = Schema.DisplayType.Integer;
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '=', 10, 10));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '==', 10, 10));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '>', 10, 9));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '>=', 10, 9));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '<', 9, 10));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '<=', 9, 10));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '!=', 9, 10));

        type = Schema.DisplayType.DateTime;
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '=', Datetime.valueOf('2015-03-11 16:00:00'), Datetime.valueOf('2015-03-11 16:00:00')));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '==', Datetime.valueOf('2015-03-11 16:00:00'), Datetime.valueOf('2015-03-11 16:00:00')));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '>', Datetime.valueOf('2015-03-11 16:00:00'), Datetime.valueOf('2015-03-02 16:00:00')));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '>=', Datetime.valueOf('2015-03-11 16:00:00'), Datetime.valueOf('2015-03-02 16:00:00')));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '<', Datetime.valueOf('2015-03-11 16:00:00'), Datetime.valueOf('2015-03-22 16:00:00')));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '<=', Datetime.valueOf('2015-03-11 16:00:00'), Datetime.valueOf('2015-03-22 16:00:00')));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '!=', Datetime.valueOf('2015-03-11 16:00:00'), Datetime.valueOf('2015-03-02 16:00:00')));


        type = Schema.DisplayType.Date;
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '=', Date.valueOf('2015-03-25'), Date.valueOf('2015-03-25')));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '==', Date.valueOf('2015-03-25'), Date.valueOf('2015-03-25')));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '>', Date.valueOf('2015-03-25'), Date.valueOf('2015-03-20')));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '>=', Date.valueOf('2015-03-25'), Date.valueOf('2015-03-20')));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '<', Date.valueOf('2015-03-20'), Date.valueOf('2015-03-25')));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '<=', Date.valueOf('2015-03-20'), Date.valueOf('2015-03-25')));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '!=', Date.valueOf('2015-03-25'), Date.valueOf('2015-03-20')));

       

        type = Schema.DisplayType.String;
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '=', 'abc', 'abc'));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '==', 'abc', 'abc'));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '>', 'bcd', 'abc'));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '>=', 'bcd', 'abc'));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '<', 'abc', 'zabc'));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '<=', 'abc', 'zabc'));
        System.assert(WorkOrderSchedulerBatchable.EvalValues(type, '!=', 'abc', 'zabc'));




        Test.stopTest();

    }

    static void InitData(String groupingOperator, Boolean allTrue)
    {
        String ns = UtilityGetNamespace.CurrentNamespace();
        Catalog_Item__c c = new Catalog_Item__c(Ticket_Item_Record_Type__c='Equipment', Name='Truck', Cost__c=5000);
        insert c;      
       
        Account office = AlpineTestHelper.CreateOffice('Houston');
        
        Equipment__c equip = new Equipment__c(Name='F150 Pickup Truck', Catalog_Item__c=c.Id, Unit_Number__c='987654', 
            Serial_Number__c='SN987654321', Office__c = office.Id,
            Manufactured_Date__c=Date.valueOf('2010-03-25'));
        insert equip;

        RecordType rt = AlpineTestHelper.GetRecordType('Work_Order__c');
        Work_Order__c woTemplate = new Work_Order__c(Name='Oil Change Work Order Template', IsTemplate__c=true, RecordTypeId = rt.Id);
        insert woTemplate;

        Catalog_Item__c ciForWorkOrderItem = new Catalog_Item__c(Ticket_Item_Record_Type__c='Equipment', Name='Oil Filter', Cost__c=20);
        insert ciForWorkOrderItem;

        Work_Order_Item__c woItem = new Work_Order_Item__c(Work_Order__c = woTemplate.Id, Catalog_Item__c = ciForWorkOrderItem.Id);
        insert woItem;

        Work_Order_Task__c woTask = new Work_Order_Task__c(Work_Order__c = woTemplate.Id, Title__c = 'Oil Change', Sequence_Number__c=1);
        insert woTask;

        Qualification__c  q = new Qualification__c(Name='Lube Mechenic Certification', Abbreviation__c='LubeCert');
        insert q;

        Work_Order_Qualification__c woq = new Work_Order_Qualification__c(Work_Order_Task__c = woTask.Id, Qualification__c = q.Id);
        insert woq;

        Preventative_Maintenance_Schedule__c pms = new Preventative_Maintenance_Schedule__c(IsActive__c = true, Description__c = 'Oil Change', Equipment__c = equip.Id, Grouping_Operator__c = groupingOperator, Template_Work_Order__c = woTemplate.Id);
        insert pms;


        Preventative_Maintenance_Criterion__c pmc1 = new Preventative_Maintenance_Criterion__c(Preventative_Maintenance_Schedule__c = pms.Id, Effective_Date__c=Datetime.now(),
        Target_Field__c= ns+ 'Manufactured_Date__c', Operator__c='<', Value__c='2015-03-25');

        String snValue = allTrue? 'SN987654321' : 'JUNKDATA';
        Preventative_Maintenance_Criterion__c pmc2 = new Preventative_Maintenance_Criterion__c(Preventative_Maintenance_Schedule__c = pms.Id, Effective_Date__c=Datetime.now(),
        Target_Field__c=ns+'Serial_Number__c', Operator__c='=', Value__c=snValue);

        insert pmc1;
        insert pmc2;
    }
}