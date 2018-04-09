@isTest
private class EquipmentHandler_Test
{
    static testmethod void SetEquipOutOfService_Test()
    {
        Equipment__c e = AlpineTestHelper.CreateEquipment(false);
        String meterValue = '5000';
        e.Meter__c = meterValue;
        insert e;
        Test.startTest();
        e.Out_of_Service__c = true;
        update e;
        Test.stopTest();
        
        List<Service_History__c> shs = [SELECT Id, Last_Meter_Value__c, Previous_Meter_Value__c, Equipment__c FROM Service_History__c WHERE Equipment__c =:e.Id];
        
        System.assert(shs.size()==1, 'set Equipment out of service should create a ServiceHistory');
        System.assert(shs.get(0).Last_Meter_Value__c == meterValue , 'ServiceHistory should have Equipment meter value: ' + meterValue  + ', but instead having ' + shs.get(0).Last_Meter_Value__c);
    }
    
    static testmethod void ReturnEquipToService_Test()
    {
        Equipment__c e = AlpineTestHelper.CreateEquipment(false);
        String meterValue = '5000';
        e.Meter__c = meterValue;
        e.Out_of_Service__c = true;
        insert e;
      
        Datetime outDate= Datetime.now().addDays(-5);
        
        Service_History__c sh = new Service_History__c(Equipment__c = e.Id, Last_Meter_Value__c = meterValue, Out_of_Service__c = outDate);
        insert sh;
        
        Test.startTest();        
        e.Out_of_Service__c = false;
        update e;        
        Test.stopTest();
        
        
        Datetime dtNow = Datetime.now();
        
        List<Service_History__c> shs = [SELECT Id, Last_Meter_Value__c, Previous_Meter_Value__c, Equipment__c, Returned_to_Service__c FROM Service_History__c WHERE Equipment__c =:e.Id];        
        
         
        System.assert(shs.get(0).Returned_to_Service__c !=null, 'Return Equipment to service should update Datetime Returned_to_Service__c');
        
    }
    
    
    static testmethod void UpdateServiceHistoryPreviousMeterValue_Test()
    {
        Equipment__c e = AlpineTestHelper.CreateEquipment(false);
        String meterValue = '5000';
        e.Meter__c = meterValue;
        insert e;
        
        Datetime outDate= Datetime.now().addDays(-5);
        Service_History__c sh = new Service_History__c(Equipment__c = e.Id, Last_Meter_Value__c = meterValue, Out_of_Service__c = outDate);
        insert sh;
        
      
        
        Test.startTest();
        
        String newMeterValue = '9500';
        Equipment__c dbItem = [SELECT Id, Meter__c, Out_of_Service__c  FROM Equipment__c where Id=:e.Id];
        dbItem.Meter__c = newMeterValue;
        dbItem.Out_of_Service__c = true;
        update dbItem;       
        
          
       
        Test.stopTest();
        
        List<Service_History__c> shs = [SELECT Id, Last_Meter_Value__c, Previous_Meter_Value__c, Equipment__c FROM Service_History__c WHERE Equipment__c =:e.Id AND Id != :sh.Id];    
      
        
        System.assert(shs.size()==1, 'Every time setting Equipment out of service should create a ServiceHistory');
        
        System.assert(shs.get(0).Last_Meter_Value__c == newMeterValue, 'ServiceHistory should have Equipment meter value: ' + newMeterValue+ ', but instead having ' + shs.get(0).Last_Meter_Value__c);
        
        System.assert(shs.get(0).Previous_Meter_Value__c == meterValue, 'ServiceHistory should have Previous_Meter_Value__c value: ' + meterValue+ ', but instead having ' + shs.get(0).Previous_Meter_Value__c );
        
    }
    
    
}