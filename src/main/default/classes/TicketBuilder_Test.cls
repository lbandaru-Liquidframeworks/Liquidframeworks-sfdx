@isTest
private class TicketBuilder_Test 
{    
    static testmethod void Initialize_Test()
    {
        Test.StartTest();
        Integer tktCount = 200;
        List<Ticket__c> tkts =  AlpineTestHelper.CreateTickets(tktCount, false);        
        string jobID = tkts.get(0).Job__c;

        string notes = StringUtility.newGuid();
        for(Integer i=0; i<tktCount; i++)
        {
            tkts.get(i).Notes__c = notes;
        }
        insert tkts;
        Test.StopTest();
        List<Ticket__c> dbTkts = [SELECT SyncID__c, Tracking_Number__c, Status__c FROM Ticket__c WHERE Job__c =:jobID];
        System.assertEquals(dbTkts.size(), tktCount);
        for(Ticket__c tkt : dbTkts)
        {
            System.debug(tkt);
            System.assert(StringUtility.isValidTrackingNumber(StringUtility.EntityObjectType.Ticket, tkt.Tracking_Number__c));          
            System.assert(tkt.SyncID__c != null);
            System.assert(tkt.Status__c != null);
        }
    }


    static testmethod void PopulateTicketWarehouse_Test()
    {
        Warehouse__c wh = new Warehouse__c(Name=StringUtility.newGuid());
        insert wh;
        Job__c job = AlpineTestHelper.CreateJobs(1, false).get(0);
        job.Warehouse__c = wh.Id;
        insert job;

        Test.StartTest();
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job, 1, true).get(0);
        Test.StopTest();

        Ticket__c dbTkt = [SELECT Id, Warehouse__c FROM Ticket__c WHERE Job__c =:job.Id LIMIT 1];
        System.assert(!String.isBlank(dbTkt.Warehouse__c));
        System.assertEquals(wh.Id, dbTkt.Warehouse__c);


    }
    static testmethod void CreateChecklistSteps_Test()
    {
        Test.StartTest();

        string newGuid = StringUtility.newGuid();
        Job__c j = AlpineTestHelper.CreateJobs(1, false).get(0);
        j.Name = newGuid;
        insert j;    
        
        Job__c job = [SELECT Id, CustomerAccount__c, Office__c, RecordTypeId, RecordType.DeveloperName, Segment__c FROM Job__c WHERE Name=:newGuid LIMIT 1];

        Ticket__c t = AlpineTestHelper.CreateTickets(job, 1, false).get(0);
        
        RecordType rt = [SELECT DeveloperName FROM RecordType where IsActive=true AND  Id=:t.RecordTypeId];

        String checklistName = 'Checklist' + newGuid;
        Checklist__c cl = new Checklist__c(Account__c = job.CustomerAccount__c, Name=checklistName, Ticket_Type__c = rt.DeveloperName);
        insert cl;

        List<Checklist_Step__c> checklistSteps = new List<Checklist_Step__c>();
        Integer steps = 5;
        for(Integer i=0; i<steps; i++)
        { 
             Checklist_Step__c cli = new Checklist_Step__c(Checklist__c = cl.Id, Sequence_Number__c = i, Description__c = string.valueOf(i) + newGuid, Screen__c = 'Labor');
             checklistSteps.add(cli);
        }
        insert checklistSteps;   

        insert t;     

        Test.StopTest();

        Ticket__c dbTkt = [SELECT Checklist_Name__c FROM Ticket__c where Id =:t.Id];
        System.assertEquals(checklistName, dbTkt.Checklist_Name__c);

        List<Ticket_Checklist_Step__c> pis = [SELECT Screen__c, Sequence_Number__c, Name, Description__c, SyncID__c FROM Ticket_Checklist_Step__c WHERE Ticket__c = :t.Id ORDER BY Sequence_Number__c];     
        System.assertEquals(steps, pis.size());

        for(Integer i=0; i<steps; i++)
        {
            System.assertEquals(string.valueOf(i) + newGuid, pis.get(i).Description__c);
            System.assert(StringUtility.isValidGuid(pis.get(i).SyncID__c));
        }
       
    }


    
}