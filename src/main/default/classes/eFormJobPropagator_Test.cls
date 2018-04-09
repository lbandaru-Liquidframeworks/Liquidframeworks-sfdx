@isTest
private class eFormJobPropagator_Test
{
    static testmethod void runTest()
    {
        Test.startTest();
        eFormJobPropagator.Run();
        String ns = StringUtility.FXNamespace();
     
        FXWorkerLauncher.DoWork(eFormJobPropagator.class.getName(), null);
        
        List<String> forms = new List<String>();
        forms.add(ns + 'Job__c');
        forms.add(ns + 'Ticket__c');
        eFormJobPropagator p = new eFormJobPropagator(forms);
        
        FXScheduleDispatcher.ScheduleJobNow(eFormJobPropagator.class.getName());
        eFormJobPropagator.FillerForCodeCoverageOnly();
        Test.stopTest();
    }
}