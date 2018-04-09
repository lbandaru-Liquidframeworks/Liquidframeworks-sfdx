@isTest    
private class FXLicenseController_Test
{
    static testmethod void EnforceFXTKTLicense_Test()
    {
        Test.startTest();
        User u = AlpineTestHelper.CreateStandardUser();
       
        System.runAs(u)
        {
            Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0); 
            
            System.debug('*********************** ' + FXLicenseController.isCurrentUserLicensed('FXTKT'));
            AlpineTestHelper.CreateTickets(j, 1, true);
        }
        Test.stopTest();
    }
    
    static testmethod void RunTest()
    {
        Test.startTest();       
        
        Boolean falseResult = FXLicenseController.isCurrentUserLicensed('FX12345');
        System.assert(falseResult ==false, 'Should be false for bogus namespace');    
        
        Boolean result = FXLicenseController.isCurrentUserLicensed(StringUtility.FXNamespace());
        
        try
        {
            FXLicenseController.EnforceTKTLicense('Job__c');
        }
        catch(FXException ex)
        {
        }

        
        try
        {
            FXLicenseController.EnforceCPQLicense();
        }
        catch(FXException ex)
        {
        }
        
        try
        {
            FXLicenseController.EnforceEAMLicense();
        }
        catch(FXException ex)
        {
        }
        
        
        try
        {
            FXLicenseController.EnforceJSDLicense();
        }
        catch(FXException ex)
        {
        }
        
        
        
        Test.stopTest();
    }
}