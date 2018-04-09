@isTest
private class WorkflowControllerExtensionTests
{
    static testMethod void runTest()
    {
        RecordType rtJob = AlpineTestHelper.GetRecordType('Job__c');

        Status__c oldStatus = new Status__c(Name = 'Old Status', SObject__c = 'Job__c', SObject_Record_Type__c = rtJob.DeveloperName);
        insert oldStatus;
        
        Status__c newStatus = new Status__c(Name = 'New Status', SObject__c = 'Job__c', SObject_Record_Type__c = rtJob.DeveloperName);
        insert newStatus;

        Status_Workflow__c workflow = new Status_Workflow__c(SObject__c = 'Job__c', SObject_Record_Type__c = rtJob.DeveloperName, New_Status__c = newStatus.Id, Old_Status__c = oldStatus.id);
        insert workflow;   

        Job__c j = AlpineTestHelper.CreateJobs(1, false).get(0);
        
        j.RecordTypeId = rtJob.Id;
        j.Status__c = oldStatus.Id;

        insert j;
        
        WorkflowControllerExtension extension = new WorkflowControllerExtension(j.id, j);
        extension.getForm();
    }
}