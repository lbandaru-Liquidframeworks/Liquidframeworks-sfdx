@isTest
private class WorkOrder_Test
{
    static testmethod void SetTrackingNumberSyncId_Test()
    {
        List<Work_Order__c> workOrders = AlpineTestHelper.CreateWorkOrders(null, 5, true);
        Set<Id> ids = new Map<Id, Work_Order__c>(workOrders).keySet();
        List<Work_Order__c> dbItems = [SELECT Id, Tracking_Number__c, SyncId__c FROM Work_Order__c WHERE Id IN :ids];
        for(Work_Order__c wo : dbItems )
        {
            System.assert(!String.isBlank(wo.Tracking_Number__c), 'TrackingNumber should have been set by insert trigger.');
            System.assert(!String.isBlank(wo.SyncId__c ), 'SyncId__c  should have been set by insert trigger.');            
        }
    }
    
    
    static testmethod void SetLastWorkOrderForPMS_Test()
    {   
        Test.startTest();     
        
        Work_Order__c workOrderTemplate = AlpineTestHelper.CreateWorkOrders(null, 1, false).get(0);
        workOrderTemplate.IsTemplate__c =true;
        insert workOrderTemplate;
        
        Preventative_Maintenance_Schedule__c pms = AlpineTestHelper.CreatePMS(workOrderTemplate, true);
        
        Preventative_Maintenance_Schedule__c  dbPMS = [SELECT Id, Last_Work_Order__c FROM Preventative_Maintenance_Schedule__c WHERE Id =:pms.Id];
        
        System.assert(String.isBlank(dbPMS.Last_Work_Order__c), 'Last_Work_Order__c should be null');        
        
        List<Work_Order__c> workOrders = AlpineTestHelper.CreateWorkOrders(pms, 1, true);
        
        Test.stopTest();
        
        dbPMS = [SELECT Id, Last_Work_Order__c FROM Preventative_Maintenance_Schedule__c WHERE Id =:pms.Id];
         
        System.assert(!String.isBlank(dbPMS.Last_Work_Order__c), 'Last_Work_Order__c should not be null after workOrder insertion.');  
        System.assertEquals(workOrders.get(0).Id, dbPMS.Last_Work_Order__c );      
    
        
    }


    static testmethod void FlagHasOpenOrderOnPMS_DeleteWorkOrder_Test()
    {   
           
        
        Work_Order__c workOrderTemplate = AlpineTestHelper.CreateWorkOrders(null, 1, false).get(0);
        workOrderTemplate.IsTemplate__c =true;
        insert workOrderTemplate;
        
        Preventative_Maintenance_Schedule__c pms = AlpineTestHelper.CreatePMS(workOrderTemplate, true);
        
        Preventative_Maintenance_Schedule__c  dbPMS = [SELECT Id, Last_Work_Order__c FROM Preventative_Maintenance_Schedule__c WHERE Id =:pms.Id];
        
        System.assert(String.isBlank(dbPMS.Last_Work_Order__c), 'Last_Work_Order__c should be null');        
        
        List<Work_Order__c> workOrders = AlpineTestHelper.CreateWorkOrders(pms, 1, true);
       
        Id workOrderId = workOrders.get(0).Id;


        Test.startTest();
        
        dbPMS = [SELECT Id, Last_Work_Order__c, HasOpenWorkOrder__c FROM Preventative_Maintenance_Schedule__c WHERE Id =:pms.Id];

        System.assert(!String.isBlank(dbPMS.Last_Work_Order__c), 'Last_Work_Order__c should not be null after workOrder insertion.');  
        System.assert(dbPMS.HasOpenWorkOrder__c==true, 'should have one open WorkOrder');

        delete [SELECT Id FROM Work_Order__c WHERE Id=:workOrderId];

        Test.stopTest();
         
        dbPMS = [SELECT Id, Last_Work_Order__c, HasOpenWorkOrder__c FROM Preventative_Maintenance_Schedule__c WHERE Id =:pms.Id];

        System.assert(String.isBlank(dbPMS.Last_Work_Order__c), 'Last_Work_Order__c should be null after workOrder deletion.');  
        System.assert(dbPMS.HasOpenWorkOrder__c==false, 'should have no open WorkOrder after workorder deletion');  
    
        
    }

    

    static testmethod void AssignWorkOrderToServiceHistory_Test()
    {
        Equipment__c e = AlpineTestHelper.CreateEquipment(false);
        String meterValue = '5900';
        e.Meter__c = meterValue;
        insert e;

        Datetime outDate= Datetime.now().addDays(-5);

        Service_History__c sh = new Service_History__c(Equipment__c = e.Id, Last_Meter_Value__c = meterValue, Out_of_Service__c = outDate);
        insert sh;

        Work_Order__c wo = AlpineTestHelper.CreateWorkOrders(null, 1, false).get(0);
        wo.Equipment__c = e.Id;
        wo.IsTemplate__c = false;
        insert wo;

        Test.startTest();
        Work_Order__c dbItem  = [SELECT Id, IsCompleted__c FROM Work_Order__c WHERE Id=:wo.Id];
        dbItem.IsCompleted__c = true;
        update dbItem;
        Test.stopTest();

        Service_History__c shResult = [SELECT Id, Work_Order__c FROM Service_History__c WHERE Id=:sh.Id];

        
        System.assert(shResult.Work_Order__c == wo.Id, 'Completing a WorkOrder should assign the WorkOrder ID to a ServiceHistory entry');        
    }

    static testmethod void SyncID_Test()
    {
        Test.startTest();
        Work_Order__c wo = AlpineTestHelper.CreateWorkOrders(null, 1, false).get(0);
        System.assert(String.isBlank(wo.SyncID__c), 'Before insert SyncID has null default value');

        insert wo;

        Work_Order__c dbwo = [SELECT Id, SyncID__c FROM Work_Order__c WHERE id=:wo.Id];
        System.assert(!String.isBlank(dbwo.SyncID__c), 'Insert Trigger should set SyncID');        
       

        Work_Order_Task__c task1 = new Work_Order_Task__c(Work_Order__c = dbwo.Id, Sequence_Number__c = 10) ;
        insert task1;

        Work_Order_Task__c task2 = [SELECT Id, SyncID__c FROM Work_Order_Task__c WHERE id=:task1.Id];
        System.assert(!String.isBlank(task2.SyncID__c), 'Insert Trigger should set Work_Order_Task__c SyncID');
        
        

        Work_Order_Item__c wi = new Work_Order_Item__c(Work_Order__c = dbwo.Id) ;
        insert wi;
        Work_Order_Item__c workItem  = [SELECT Id, SyncID__c FROM Work_Order_Item__c WHERE id=:wi.Id];
        System.assert(!String.isBlank(workItem.SyncID__c), 'Insert Trigger should set Work_Order_Item__c SyncID');        
       
    }

}