@isTest
private class PriceBookAssignmentHandler_Test 
{    
    static testmethod void RefreshPriceBookAssignment_SyncAssignmentInserted()
    {
    	Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
    	Price_Book__c pb = [SELECT Id, Account__c, Office__c FROM Price_Book__c WHERE Id = : job.Price_Book__c LIMIT 1];
    	pb.Account__c = job.CustomerAccount__c;
    	pb.Office__c  = job.Office__c;
    	update pb;

    	Account acct = [SELECT Id FROM Account where Id =: job.CustomerAccount__c];
    	Contact c = AlpineTestHelper.CreateContactWithTestUser('Adam', 'Joe', false);
        c.Account= acct;
        c.Office__c = job.Office__c;
    	insert c;

    	Test.StartTest();

    	Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = c.Id, Account__c = job.CustomerAccount__c, Office__c = job.Office__c);
    	insert sc;
    	Test.StopTest();

    	List<Price_Book_Assignment__c> pba = [SELECT Id, Contact__c, Price_Book__c FROM Price_Book_Assignment__c WHERE Contact__c =: c.Id AND Auto_Added__c = true];
    	System.assert(pba.size()==1);

    	System.assert(pba.get(0).Price_Book__c == pb.Id);


    }

    static testmethod void SyncConfigureWithNullOfficeAccountSegment_NoPriceBookAssignment()
    {
        Test.StartTest();
        String newGuid = StringUtility.newGuid();
        Price_Book__c pb = new Price_Book__c(Name = 'Price Book' + newGuid);
        insert pb;
        Contact c = AlpineTestHelper.CreateContactWithTestUser('Adam', 'Joe', true);
        

        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = c.Id, Sync_JobCrewOnly__c = true);
        Database.insert(sc, false);
        Test.StopTest();

        List<Price_Book_Assignment__c> pba = [SELECT Id, Contact__c, Price_Book__c FROM Price_Book_Assignment__c WHERE Contact__c =: c.Id AND Auto_Added__c = true];
        System.assert(pba.size()==0);

    }


    static testmethod void RefreshPriceBookAssignment_PriceBookUpdated()
    {
    	Job__c job = AlpineTestHelper.CreateJobs(1, false).get(0);

    	Account acct = [SELECT Id FROM Account where Id =: job.CustomerAccount__c];

        Contact c = AlpineTestHelper.CreateContactWithTestUser('Adam', 'Joe', false);
        c.Account= acct;
        c.Office__c = job.Office__c;
    	insert c;

    	Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = c.Id, Account__c = job.CustomerAccount__c, Office__c = job.Office__c, Segment__c = job.Segment__c);
    	insert sc;

    	Test.StartTest();
    	List<Price_Book_Assignment__c> pba = [SELECT Id, Contact__c, Price_Book__c FROM Price_Book_Assignment__c WHERE Contact__c =: c.Id AND Auto_Added__c = true];
    	System.assert(pba.size()==0);

    	Price_Book__c pb = [SELECT Id, Account__c, Office__c FROM Price_Book__c WHERE Id = : job.Price_Book__c LIMIT 1];
    	pb.Account__c = job.CustomerAccount__c;
    	pb.Office__c  = job.Office__c;
    	pb.Segment__c = job.Segment__c;
    	update pb;

    	Test.StopTest();

    	pba = [SELECT Id, Contact__c, Price_Book__c FROM Price_Book_Assignment__c WHERE Contact__c =: c.Id AND Auto_Added__c = true];
    	System.assert(pba.size()==1);

    	System.assert(pba.get(0).Price_Book__c == pb.Id);


    }

    static testmethod void RefreshPriceBookAssignment_PriceBookDeleted()
    {
        Job__c job = AlpineTestHelper.CreateJobs(1, false).get(0);

        

        Price_Book__c pb = [SELECT Id, Account__c, Office__c FROM Price_Book__c WHERE Id = : job.Price_Book__c LIMIT 1];
        pb.Account__c = job.CustomerAccount__c;
        pb.Office__c  = job.Office__c;
        pb.Segment__c = job.Segment__c;
        update pb;

        Account acct = [SELECT Id FROM Account where Id =: job.CustomerAccount__c];

        Contact c = AlpineTestHelper.CreateContactWithTestUser('Adam', 'Joe1', false);
        c.Account= acct;
        c.Office__c = job.Office__c;
        insert c;

        Sync_Configuration__c sc = new Sync_Configuration__c(Contact__c = c.Id, Account__c = job.CustomerAccount__c, Office__c = job.Office__c, Segment__c = job.Segment__c);
        Database.insert(sc, false);

        Test.StartTest();

        List<Price_Book_Assignment__c> pba = [SELECT Id, Contact__c, Price_Book__c FROM Price_Book_Assignment__c WHERE Contact__c =: c.Id AND Auto_Added__c = true];
        System.assert(pba.size()==1);

        delete pb;

        Test.StopTest();


        List<Price_Book_Assignment__c> pbResults = [SELECT Id, Contact__c, Price_Book__c FROM Price_Book_Assignment__c WHERE Price_Book__c =: pb.Id];
        System.assert(pbResults.size()==0);


    }
}