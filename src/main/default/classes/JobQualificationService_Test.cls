@isTest
private class JobQualificationService_Test
{
    @testSetup static void setup() 
    {
        List<Job__c> jobs = AlpineTestHelper.CreateJobs(1, true);
        Job__c j1 = jobs.get(0);

        List<Qualification__c> qItems = new List<Qualification__c>();
        for(Integer i=0; i<5; i++)
        {
            qItems.add(new Qualification__c(Name='Q ' + StringUtility.newGuid(), Abbreviation__c='Abbrev ' + i, Category__c='Contact'));
        }
        //insert qItems;

        for(Integer i=5; i<10; i++)
        {
            qItems.add(new Qualification__c(Name='Q ' + StringUtility.newGuid(), Abbreviation__c='Abbrev ' + i, Category__c='Equipment'));
        }
        insert qItems;

        List<Qualification_Requirement__c> qrs = new List<Qualification_Requirement__c>();

        qrs.add(new Qualification_Requirement__c(Qualification__c = qItems.get(0).Id, Required__c = true));
        qrs.add(new Qualification_Requirement__c(Qualification__c = qItems.get(1).Id, Required__c = true, Job__c = j1.Id));
        qrs.add(new Qualification_Requirement__c(Qualification__c = qItems.get(2).Id, Required__c = true, Account__c = j1.CustomerAccount__c));

        qrs.add(new Qualification_Requirement__c(Qualification__c = qItems.get(3).Id));
        qrs.add(new Qualification_Requirement__c(Qualification__c = qItems.get(4).Id));

        qrs.add(new Qualification_Requirement__c(Qualification__c = qItems.get(5).Id, Required__c = true, Job__c = j1.Id));
        qrs.add(new Qualification_Requirement__c(Qualification__c = qItems.get(6).Id, Required__c = true, Job__c = j1.Id));
        qrs.add(new Qualification_Requirement__c(Qualification__c = qItems.get(7).Id, Required__c = true, Job__c = j1.Id));
        qrs.add(new Qualification_Requirement__c(Qualification__c = qItems.get(8).Id, Required__c = true, Job__c = j1.Id));
        qrs.add(new Qualification_Requirement__c(Qualification__c = qItems.get(9).Id, Required__c = true, Job__c = j1.Id));


        insert qrs;
    }
    
    static testmethod void GetQualifiedItems_FullyQualified()
    {
        List<Qualification__c> qItems = [SELECT Id, Category__c FROM Qualification__c ORDER BY Category__c];
        Contact c = AlpineTestHelper.CreateContact(true);
        Equipment__c equip = AlpineTestHelper.CreateEquipment(true);

        List<sObject> newItems = new List<sObject>();
        List<Id> qIds = new List<Id>();
        for(Qualification__c q : qItems)
        {
            qIds.add(q.Id);
            if(q.Category__c == 'Contact')
            {
                newItems.add(new Contact_Qualification__c(Contact__c = c.Id, Qualification__c = q.Id));
            }
            else
            {
                newItems.add(new Equipment_Qualification__c(Equipment__c = equip.Id, Qualification__c = q.Id));
            }
        }
        insert newItems;

        Test.startTest();

        String qIdStrs = String.join(qIds, ',');

        Datetime startDate = Datetime.now();
        Datetime endDate = startDate.addDays(10);
        SvcResult r1 = FXJSDHandler.getQualifiedItems(String.valueOf(startDate), String.valueOf(endDate), qIdStrs);

        Test.stopTest();
        System.assert(r1.IsSuccess, r1.Message);
        System.assert(!String.isBlank(r1.Result) && r1.Result.contains(c.Id), 'should have one contact');

        System.assert(!String.isBlank(r1.Result) && r1.Result.contains(equip.Id), 'should have one equipment');

    }

    static testmethod void CrewPlanningQualification_GreenTest()
    {
        List<Qualification__c> qItems = [SELECT Id, Category__c FROM Qualification__c WHERE Category__c='Contact'];
        Contact c = AlpineTestHelper.CreateContact(true);

        List<sObject> newItems = new List<sObject>();
        List<Id> qIds = new List<Id>();
        for(Qualification__c q : qItems)
        {
            qIds.add(q.Id);
            newItems.add(new Contact_Qualification__c(Contact__c = c.Id, Qualification__c = q.Id));
        }
        insert newItems;
        Test.startTest();
        Job__c j = [SELECT Id FROM Job__c LIMIT 1];
        Crew_Planning__c cp = new Crew_Planning__c(Job__c = j.Id, Crew_Member__c = c.Id);
        insert cp;
        Test.stopTest();
        Id contactId = c.Id;

        List<Crew_Planning__c> dbItems = [SELECT Id FROM Crew_Planning__c WHERE Crew_Member__c=:contactId];
        System.assert(dbItems.size()==1, 'should have 1 crewPlanning entry, instead of ' + dbItems.size());

    }

    static testmethod void CrewPlanningQualification_Fail()
    {
        List<Qualification__c> qItems = [SELECT Id, Category__c FROM Qualification__c WHERE Category__c='Contact'];
        Contact c = AlpineTestHelper.CreateContact(true);

        List<sObject> newItems = new List<sObject>();
        List<Id> qIds = new List<Id>();
        for(Qualification__c q : qItems)
        {
            qIds.add(q.Id);
            newItems.add(new Contact_Qualification__c(Contact__c = c.Id, Qualification__c = q.Id));
        }
        newItems.remove(0);
        insert newItems;
        Test.startTest();
        Job__c j = [SELECT Id FROM Job__c LIMIT 1];
        Crew_Planning__c cp = new Crew_Planning__c(Job__c = j.Id, Crew_Member__c = c.Id);

        System.DmlException ex = null;
        try {            
            insert cp;
        }
        catch (System.DmlException e) {
            ex = e;
        }              
       
        Test.stopTest();
        System.assert(ex!=null, 'should throw DmlException');

    }

    static testmethod void CrewPlanningQualification_SkipTrigger()
    {
        FX_Settings__c fxSettings = FX_Settings__c.getInstance(UserInfo.getUserId());
        fxSettings.SkipCrewPlanningTriggerOnQualification__c = true;
        upsert fxSettings;

        List<Qualification__c> qItems = [SELECT Id, Category__c FROM Qualification__c WHERE Category__c='Contact'];
        Contact c = AlpineTestHelper.CreateContact(true);

        List<sObject> newItems = new List<sObject>();
        List<Id> qIds = new List<Id>();
        for(Qualification__c q : qItems)
        {
            qIds.add(q.Id);
            newItems.add(new Contact_Qualification__c(Contact__c = c.Id, Qualification__c = q.Id));
        }
        newItems.remove(0);
        insert newItems;
        Test.startTest();
        Job__c j = [SELECT Id FROM Job__c LIMIT 1];
        Crew_Planning__c cp = new Crew_Planning__c(Job__c = j.Id, Crew_Member__c = c.Id);

        System.DmlException ex = null;
        try {            
            insert cp;
        }
        catch (System.DmlException e) {
            ex = e;
        }              
       
        Test.stopTest();
        System.assert(ex==null, 'should not throw DmlException');

        Id contactId = c.Id;

        List<Crew_Planning__c> dbItems = [SELECT Id FROM Crew_Planning__c WHERE Crew_Member__c=:contactId];
        System.assert(dbItems.size()==1, 'should have 1 crewPlanning entry, instead of ' + dbItems.size());
        

    }

    static testmethod void CrewPlanningQualification_Expired()
    {
        List<Qualification__c> qItems = [SELECT Id, Category__c FROM Qualification__c WHERE Category__c='Contact'];
        Contact c = AlpineTestHelper.CreateContact(true);

        List<sObject> newItems = new List<sObject>();
        List<Id> qIds = new List<Id>();
        for(Qualification__c q : qItems)
        {
            qIds.add(q.Id);
            newItems.add(new Contact_Qualification__c(Contact__c = c.Id, Qualification__c = q.Id));
        }
        Contact_Qualification__c cq = (Contact_Qualification__c)newItems.get(0);
        cq.Expiration_Date__c = Date.today().addYears(-1);
        insert newItems;
        Test.startTest();
        Job__c j = [SELECT Id FROM Job__c LIMIT 1];
        Crew_Planning__c cp = new Crew_Planning__c(Job__c = j.Id, Crew_Member__c = c.Id);

        System.DmlException ex = null;
        try {            
            insert cp;
        }
        catch (System.DmlException e) {
            ex = e;
        }              
       
        Test.stopTest();
        System.assert(ex!=null, 'should throw DmlException');

    }

    static testmethod void CrewPlanningQualification_NotYetEffective()
    {
        List<Qualification__c> qItems = [SELECT Id, Category__c FROM Qualification__c WHERE Category__c='Contact'];
        Contact c = AlpineTestHelper.CreateContact(true);

        List<sObject> newItems = new List<sObject>();
        List<Id> qIds = new List<Id>();
        for(Qualification__c q : qItems)
        {
            qIds.add(q.Id);
            newItems.add(new Contact_Qualification__c(Contact__c = c.Id, Qualification__c = q.Id));
        }
        Contact_Qualification__c cq = (Contact_Qualification__c)newItems.get(0);
        cq.Effective_Date__c = Date.today().addYears(1);
        insert newItems;
        Test.startTest();
        Job__c j = [SELECT Id FROM Job__c LIMIT 1];
        Crew_Planning__c cp = new Crew_Planning__c(Job__c = j.Id, Crew_Member__c = c.Id);

        System.DmlException ex = null;
        try {            
            insert cp;
        }
        catch (System.DmlException e) {
            ex = e;
        }              
       
        Test.stopTest();
        System.assert(ex!=null, 'should throw DmlException');

    }



    static testmethod void EquipmentPlanningQualification_GreenTest()
    {
        List<Qualification__c> qItems = [SELECT Id, Category__c FROM Qualification__c WHERE Category__c='Equipment'];
        Equipment__c equip = AlpineTestHelper.CreateEquipment(true);

        List<sObject> newItems = new List<sObject>();
        List<Id> qIds = new List<Id>();
        for(Qualification__c q : qItems)
        {
            qIds.add(q.Id);
            newItems.add(new Equipment_Qualification__c(Equipment__c = equip.Id, Qualification__c = q.Id));
        }
        insert newItems;
        Test.startTest();
        Job__c j = [SELECT Id FROM Job__c LIMIT 1];
        Equipment_Planning__c cp = new Equipment_Planning__c(Job__c = j.Id, Equipment2__c = equip.Id);
        insert cp;
        Test.stopTest();
        Id equipId = equip.Id;

        List<Equipment_Planning__c> dbItems = [SELECT Id FROM Equipment_Planning__c WHERE Equipment2__c=:equipId];
        System.assert(dbItems.size()==1, 'should have 1 EquipmentPlanning entry, instead of ' + dbItems.size());

    }


    static testmethod void GetQualifiedItems_PartialQualified()
    {
        List<Qualification__c> qItems = [SELECT Id, Category__c FROM Qualification__c ORDER BY Category__c];
        Contact c = AlpineTestHelper.CreateContact(true);
        Equipment__c equip = AlpineTestHelper.CreateEquipment(true);

        List<sObject> newItems = new List<sObject>();
        List<Id> qIds = new List<Id>();
        Boolean contactDone = false;
        Boolean equipDone = false;
        for(Qualification__c q : qItems)
        {
            qIds.add(q.Id);
            if(q.Category__c == 'Contact' && !contactDone)
            {
                newItems.add(new Contact_Qualification__c(Contact__c = c.Id, Qualification__c = q.Id));
                contactDone = true;
            }
            else if(!equipDone)
            {
                newItems.add(new Equipment_Qualification__c(Equipment__c = equip.Id, Qualification__c = q.Id));
                equipDone = true;
            }
        }
        insert newItems;
        String qIdStrs = String.join(qIds, ',');

        Test.startTest();
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(10);
        SvcResult r1 = FXJSDHandler.getQualifiedItems(String.valueOf(startDate), String.valueOf(endDate), qIdStrs);


        Test.stopTest();
        System.assert(r1.IsSuccess, r1.Message);
        System.debug('***************' + r1);
        System.assert(!String.isBlank(r1.Result) && !r1.Result.contains(c.Id), 'should have no contact');
        System.assert(!String.isBlank(r1.Result) && !r1.Result.contains(equip.Id), 'should have no equipment');

    }
    
    static testmethod void GetContacts_NoDateInfo()
    {
        List<Qualification__c> qualifications = [SELECT Id FROM Qualification__c WHERE Category__c='Contact'];
        Contact c = AlpineTestHelper.CreateContact(true);

        List<Contact_Qualification__c> cqs = new List<Contact_Qualification__c>();
        for(Qualification__c q : qualifications)
        {
            cqs.add(new Contact_Qualification__c(Contact__c = c.Id, Qualification__c= q.Id));
        }
        insert cqs;
        Job__c j = [SELECT Id, Projected_Start_Date__c, Projected_End_Date__c FROM Job__c LIMIT 1];      
        SvcResult r1 = FXJSDHandler.getQualifiedContacts(j.Id);
        System.debug(r1);
        System.assert(r1.IsSuccess, 'Should not fail');
        System.debug('GetContacts :' + r1);
        Set<Id> items = (Set<Id>)JSON.deserialize(r1.Result, Type.forName('Set<Id>'));
        System.assert(items.size()==1, 'Should have one entry instead of ' + items.size()); 

        FXJSDHandler.getJobQualifications(j.Id);
        SvcResult r2 = FXJSDHandler.getQualifiedContacts(j.Id);

        System.assert(r2.IsSuccess, 'Should not fail');
        items = (Set<Id>)JSON.deserialize(r2.Result, Type.forName('Set<Id>'));
        System.assert(items.size()==1, 'Should have one entry instead of ' + items.size()); 



    }

    static testmethod void GetContacts_FutureEffectiveDate()
    {
        List<Qualification__c> qualifications = [SELECT Id FROM Qualification__c WHERE Category__c='Contact'];
        Contact c = AlpineTestHelper.CreateContact(true);

        List<Contact_Qualification__c> cqs = new List<Contact_Qualification__c>();
        for(Qualification__c q : qualifications)
        {
            cqs.add(new Contact_Qualification__c(Contact__c = c.Id, Qualification__c= q.Id, Effective_Date__c = Date.today().addYears(1)));
        }
        insert cqs;
        Job__c j = [SELECT Id, Projected_Start_Date__c, Projected_End_Date__c FROM Job__c LIMIT 1];
        Datetime now = Datetime.now();
        j.Projected_Start_Date__c = now;
        j.Projected_End_Date__c = now.addDays(10);
        update j;  

        SvcResult r1 = FXJSDHandler.getQualifiedContacts(j.Id);
        System.assert(r1.IsSuccess, 'Should not fail');
        System.debug('GetContacts :' + r1);
        Set<Id> items = (Set<Id>)JSON.deserialize(r1.Result, Type.forName('Set<Id>'));
        System.assert(items.isEmpty(), 'Should have no result, instead of ' + items.size());
    }
    
    static testmethod void GetContacts_WithPartialQualifications()
    {
        List<Qualification__c> qualifications = [SELECT Id FROM Qualification__c WHERE Category__c='Contact'];
        Contact c = AlpineTestHelper.CreateContact(true);

        List<Contact_Qualification__c> cqs = new List<Contact_Qualification__c>();
        for(Integer i=1; i<qualifications.size(); i++)
        {
            cqs.add(new Contact_Qualification__c(Contact__c = c.Id, Qualification__c= qualifications.get(i).Id));
        }
        insert cqs;
        Job__c j = [SELECT Id, Projected_Start_Date__c, Projected_End_Date__c FROM Job__c LIMIT 1];      

        SvcResult r1 = FXJSDHandler.getQualifiedContacts(j.Id);

        System.assert(r1.IsSuccess, 'Should not fail');
        Set<Id> items = (Set<Id>)JSON.deserialize(r1.Result, Type.forName('Set<Id>'));
        System.assert(items.isEmpty(), 'Should have no result'); //Contact needs to have all 5 qualification 
    }

    
    static testmethod void GetEquipment()
    {
        Equipment__c equip = AlpineTestHelper.CreateEquipment(true);

        List<Qualification__c> qualifications = [SELECT Id FROM Qualification__c WHERE Category__c='Equipment'];

        List<Equipment_Qualification__c> eqs = new List<Equipment_Qualification__c>();
        for(Qualification__c q : qualifications)
        {
            eqs.add(new Equipment_Qualification__c(Equipment__c = equip.Id, Qualification__c= q.Id));
        }
        insert eqs;
        Job__c j = [SELECT Id, Projected_Start_Date__c, Projected_End_Date__c FROM Job__c LIMIT 1];     
        SvcResult r1 = FXJSDHandler.getQualifiedEquipment(j.Id);

        System.assert(r1.IsSuccess, 'Should not fail');

        System.debug('GetEquipment :' + r1);

        Set<Id> items = (Set<Id>)JSON.deserialize(r1.Result, Type.forName('Set<Id>'));
        System.assert(items.size()==1, 'Should have one entry instead of ' + items.size()); 
    }
    
    static testmethod void GetJobQualifications_Test()
    {
        Test.startTest();
        
        List<Job__c> jobs = [SELECT Id FROM Job__c];
        Job__c j1 = jobs.get(0);
        
        Job__c j2 = AlpineTestHelper.CreateJobs(1, true).get(0);

        String ns = StringUtility.FXNamespace().replace('__', '.');

        Map<String, String> params = new Map<String, String>();
        params.put('service', ns + 'JobQualificationService');
        params.put('method', 'getjobqualifications');
        params.put('jobId', j1.Id);

        String jsonParams = JSON.serialize(params);

        SvcResult r0 = FXWorkerLauncher.Run(jsonParams);
        SvcResult r1 = FXWorkerLauncher.DoWork(ns + 'JobQualificationService', jsonParams);
        SvcResult r2 = JobQualificationService.Run(jsonParams);        

        SvcResult r3 = FXWorkerLauncher.DoWork(ns + 'JobQualificationServiceBogus', jsonParams);

        params.put('jobId', StringUtility.newGuid());        
        SvcResult r4 = FXWorkerLauncher.DoWork(ns + 'JobQualificationService', JSON.serialize(params));
        
        Test.stopTest();

        System.assert(r1.IsSuccess, 'IsSuccess should be true');

        Type objType = Type.forName('Set<' + ns +  'JobQualificationHandler.ResultItem>');
        Set<JobQualificationHandler.ResultItem> items = (Set<JobQualificationHandler.ResultItem>)JSON.deserialize(r1.Result, objType);

        System.assert(items.size() == 10, 'Should have 10 items instead of ' + items.size());
        System.assert(r3.IsSuccess==false, 'Should fail for bogus service');
        System.assert(r4.IsSuccess==false && !String.isBlank(r3.Message), 'Should fail with exception for invalid params');
    }
}