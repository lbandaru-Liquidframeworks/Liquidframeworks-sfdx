@isTest
private class EquipmentWorkOrderTemplatesCtrl_Test
{
    static testmethod void RunTest()
    {
        Test.startTest();
        Equipment__c equip = AlpineTestHelper.CreateEquipment(true);
        
        List<Work_Order__c> workOrders = AlpineTestHelper.CreateWorkOrders(null, 5, false);
        for(Work_Order__c wo: workOrders)
        {
            wo.IsTemplate__c = true;
        }
        insert workOrders;      
        
        PageReference p = Page.EquipmentWorkOrderTemplates;
        p.getParameters().put('templateid', workOrders.get(0).Id);
        p.getParameters().put('id', equip.Id);        

        Test.setCurrentPage(p);
        
        EquipmentWorkOrderTemplatesController ctrl = new EquipmentWorkOrderTemplatesController(new ApexPages.StandardController(equip));

        ctrl.CreateWorkOrder();        
        Test.stopTest();
        
        Integer workOrderCount = [SELECT Count() FROM Work_Order__c WHERE Equipment__c = :equip.Id];
        System.assert(workOrderCount == 1, 'Should have a workOrder created');
        
        Integer shCount = [SELECT Count() FROM Service_History__c WHERE Equipment__c = :equip.Id];
        System.assert(workOrderCount == 1, 'Should have a Service_History__c created');
        
        Equipment__c e = [SELECT Out_of_Service__c FROM Equipment__c WHERE Id=:equip.Id];
        System.assert(e.Out_of_Service__c ==true, 'Equipment should have Out_of_Service__c =true'); 
        
    }
    
    
    
    
}