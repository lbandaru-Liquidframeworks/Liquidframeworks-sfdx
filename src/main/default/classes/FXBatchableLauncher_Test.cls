@isTest
private class FXBatchableLauncher_Test
{
    static testmethod void RunBatachableTest()
    {
        FXResult r = DoGoodWork();       
        System.debug(r);
        System.assert(r.IsSuccess, 'should have IsSuccess=true');
    }
    static FXResult DoGoodWork()
    {
        String ns = StringUtility.FXNamespace();
        if(!String.isBlank(ns))
        {
            ns = ns.replace('__', '.');
        }
        return FXBatchableLauncher.Run(ns + 'EquipmentPlanningPlaceHolderBatchable');
    }
    
    
    static testmethod void RunBatachableTest_BogusClass()
    {
        String ns = StringUtility.FXNamespace();
        if(!String.isBlank(ns))
        {
            ns = ns.replace('__', '.');
        }
        FXResult r = FXBatchableLauncher.Run(ns + 'BogusClass234234');
        System.debug(r);
        System.assert(!r.IsSuccess, 'should have IsSuccess=false');
    }
    
    static testmethod void RunBatachableTest_ClassNotFXBatchableBase()
    {
        String ns = StringUtility.FXNamespace();
        if(!String.isBlank(ns))
        {
            ns = ns.replace('__', '.');
        }
        FXResult r = FXBatchableLauncher.Run(ns + 'AlpineTestHelper');
        System.debug(r);
        System.assert(!r.IsSuccess, 'should have IsSuccess=false');
        System.assert(!String.isBlank(r.Message) && r.Message.contains('not FXBatchableBase'), 'should catch not FXBatchableBase TypeException');
        
    }
    
    static testmethod void notAdminUser_Test()
    {
        User u = AlpineTestHelper.CreateStandardUser();     
       
        
        System.runAs(u)
        {
            FXResult r = DoGoodWork();
            System.assert(!r.IsSuccess, 'should have IsSuccess=false');
            System.assert(r.Message.contains('Only System Admin can run FXBatchableLauncher'), 'Only System Admin can run FXBatchableLauncher');
        }
    }
    
}