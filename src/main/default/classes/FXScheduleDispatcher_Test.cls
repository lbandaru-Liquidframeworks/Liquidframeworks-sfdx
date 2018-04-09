@isTest
private class FXScheduleDispatcher_Test
{
    static testmethod void scheduleJob_Test()
    {
        Test.startTest();  
        
        String ns = StringUtility.FXNamespace().Replace('__', '.');
        FXResult r =  FXScheduleDispatcher.ScheduleJobNow(ns + 'WorkOrderScheduler');   
        Test.stopTest();         
        System.debug('scheduleJob_Test：' + r);
        System.assert(r.IsSuccess==true, 'should succeed');            
        
        System.assert(!String.isBlank(r.Message) && r.Message.contains('08e'), 'Should return a string scheduled job CronTrigger id (prefix 08e)');    
        System.debug('Job id: ' + r.Message);
    }
    
    static testmethod void scheduleInvalidClass_Test()
    {
    
        String ns = StringUtility.FXNamespace().Replace('__', '.');
        FXResult r =  FXScheduleDispatcher.ScheduleJobNow(ns + 'TheBogusClassName');  
         System.debug('scheduleInvalidClass_Test：' + r);       
        System.assert(r.IsSuccess==false, 'should fail');            
        System.assert(r.Message.contains('not a valid class implementing Schedulable'), 'not a valid class implementing Schedulable');         
     
    }
    
    static testmethod void scheduleClassNoSchedulable_Test()
    {
        
       String ns = StringUtility.FXNamespace().Replace('__', '.');
        FXResult r =  FXScheduleDispatcher.ScheduleJobNow(ns + 'StringUtility');            
         System.debug('scheduleClassNoSchedulable_Test:' + r);
        System.assert(r.IsSuccess==false, 'should fail');            
        System.assert(r.Message.contains('does not implement Schedulable, thus it could not be scheduled to run'), 'does not implement Schedulable, thus it could not be scheduled to run');   
        
    }
    
    
    static testmethod void notAdminUser_Test()
    {
        User u = AlpineTestHelper.CreateStandardUser();
      
        String ns = StringUtility.FXNamespace().Replace('__', '.');
        
        System.runAs(u)
        {
            FXResult r =  FXScheduleDispatcher.ScheduleJobNow(ns + 'WorkOrderScheduler');
             System.debug('notAdminUser_Test:' + r);
            System.assert(r.IsSuccess==false, 'should fail');            
            System.assert(r.Message.contains('Only System Admin can run FXScheduleDispatcher'), 'Only System Admin can run FXScheduleDispatcher');           
        }
       
       
    }
    
}