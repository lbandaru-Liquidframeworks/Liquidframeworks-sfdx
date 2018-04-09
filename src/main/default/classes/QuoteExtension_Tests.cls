@isTest
private class QuoteExtension_Tests
{
    static testMethod void runTest_Quote()
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
        j.Category__c = 'Deal';

        insert j;

        Ticket__c tkt = AlpineTestHelper.CreateTickets(j, 1, false).get(0);
        tkt.Category__c = 'Quote';

        insert tkt;
        
        QuoteExtension extension = new QuoteExtension(tkt.Id, tkt);
        extension.getForm();

        string jobObjectType = UtilityGetNamespace.CurrentNamespace()  + 'Job__c';
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType WHERE SObjectType =: jobObjectType AND IsActive=true]; // AND Id != :rtJob.Id];

        string newJobRecordType = recordTypes.get(0).Id;
        extension.HiddenTextValue = newJobRecordType;
        extension.convertToJob();

        List<Job__c> jobs = [SELECT Name, Price_Book__c, Office__c, CustomerAccount__c, RecordTypeId FROM Job__c WHERE Id !=:j.Id];
        System.assertEquals(1, jobs.size());

        if(jobs.size()==1)
        {
            Job__c j2 = jobs.get(0);
            System.assert(j2.Name == j.Name);
            System.assert(j2.Price_Book__c == j.Price_Book__c);
            System.assert(j2.Office__c == j.Office__c);
            System.assert(j2.CustomerAccount__c == j.CustomerAccount__c);
            System.assert(j2.RecordTypeId == newJobRecordType);
        }

    }

    static testMethod void runTest_NonQuote()
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
        j.Category__c = 'Job';

        insert j;

        Ticket__c tkt = AlpineTestHelper.CreateTickets(j, 1, false).get(0);
        tkt.Category__c = 'Ticket';

        insert tkt;
        
        QuoteExtension extension = new QuoteExtension(tkt.Id, tkt);
        System.assert(extension.getForm() == null);    

    }
}