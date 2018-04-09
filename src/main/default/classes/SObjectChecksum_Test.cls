@isTest
private class SObjectChecksum_Test
{   
    @testSetup 
    static void Init()
    {
        List<Job__c> jobs = AlpineTestHelper.CreateJobs(10, true);   
        Datetime createdDate = Datetime.now().addDays(-1);
        for(Job__c j : jobs)
        {
            Test.setCreatedDate(j.Id, createdDate);
        }
    }

    static testmethod void SimpleAddAndDelete_Scenario1()
    {
        Test.startTest();
        Datetime lastSync = Datetime.now().addMinutes(-1);

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
            
        req.requestURI = '/SObjectChecksum';
        req.httpMethod = 'GET';

        req.addParameter('sobjectName', StringUtility.FXNamespace() + 'Job__c');
        req.addParameter('lastSync', String.valueOf(lastSync));
                
        RestContext.request = req;
        RestContext.response = res;

        String checksum1 = SObjectChecksum.getCheckSum();

        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);

        String checksum2 = SObjectChecksum.getCheckSum();

        System.assert(checksum1 == checksum2, 'checksum should be the same, before/after adding new item');

        delete j;

        String checksum3 = SObjectChecksum.getCheckSum();
        System.assert(checksum1 == checksum3, 'checksum should be the same, before/after deleting newly added item');

        Job__c dbJob = [SELECT Id FROM Job__c WHERE IsDeleted=false LIMIT 1];
        delete dbJob;

        String checksum4 = SObjectChecksum.getCheckSum();
        System.assert(checksum1 == checksum4, 'checksum should be the same, before/after deleting item that was created before the original time');

        Test.stopTest();   
    }


    static testmethod void JobSyncV4_Test()
    {
        Test.startTest();
        FX_Settings__c settings = FX_Settings__c.getInstance(UserInfo.getUserId());
        settings.SyncV4Config__c = true;
        upsert settings;


        Datetime lastSync = Datetime.now().addMinutes(-1);

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
            
        req.requestURI = '/SObjectChecksum';
        req.httpMethod = 'GET';

        req.addParameter('sobjectName', StringUtility.FXNamespace() + 'Job__c');
        req.addParameter('lastSync', String.valueOf(lastSync));
                
        RestContext.request = req;
        RestContext.response = res;

        String checksum1 = SObjectChecksum.getCheckSum();

        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);

        String checksum2 = SObjectChecksum.getCheckSum();

        System.assert(checksum1 == checksum2, 'checksum should be the same, before/after adding new item');

        delete j;

        String checksum3 = SObjectChecksum.getCheckSum();
        System.assert(checksum1 == checksum3, 'checksum should be the same, before/after deleting newly added item');

        Job__c dbJob = [SELECT Id FROM Job__c WHERE IsDeleted=false LIMIT 1];
        delete dbJob;

        String checksum4 = SObjectChecksum.getCheckSum();
        System.assert(checksum1 == checksum4, 'checksum should be the same, before/after deleting item that was created before the original time');

        Test.stopTest();   
    }

    static testmethod void TicketSyncV4_Test()
    {
        Test.startTest();
        FX_Settings__c settings = FX_Settings__c.getInstance(UserInfo.getUserId());
        settings.SyncV4Config__c = true;
        upsert settings;


        Datetime lastSync = Datetime.now().addMinutes(-1);

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
            
        req.requestURI = '/SObjectChecksum';
        req.httpMethod = 'GET';

        req.addParameter('sobjectName', StringUtility.FXNamespace() + 'Ticket__c');
        req.addParameter('lastSync', String.valueOf(lastSync));
                
        RestContext.request = req;
        RestContext.response = res;

        String checksum1 = SObjectChecksum.getCheckSum();

        Ticket__c tkt = AlpineTestHelper.CreateTickets(10, true).get(0);

        String checksum2 = SObjectChecksum.getCheckSum();

        System.assert(checksum1 == checksum2, 'checksum should be the same, before/after adding new item');

        delete tkt;

        String checksum3 = SObjectChecksum.getCheckSum();
        System.assert(checksum1 == checksum3, 'checksum should be the same, before/after deleting newly added item');

        Ticket__c dbTkt = [SELECT Id FROM Ticket__c WHERE IsDeleted=false LIMIT 1];
        delete dbTkt;

        String checksum4 = SObjectChecksum.getCheckSum();
        System.assert(checksum1 == checksum4, 'checksum should be the same, before/after deleting item that was created before the original time');

        Test.stopTest();   
    }


    /*
    static testmethod void ChangesDueToSharing_Scenario2_More()
    {
        Test.startTest();
        Datetime lastSync = Datetime.now().addMinutes(-1);

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
            
        req.requestURI = '/SObjectChecksum';
        req.httpMethod = 'GET';

        req.addParameter('sobjectName', StringUtility.FXNamespace() + 'Job__c');
        req.addParameter('lastSync', String.valueOf(lastSync));
                
        RestContext.request = req;
        RestContext.response = res;


        String checksum1, checksum2, checksum3;

        User u = AlpineTestHelper.CreateStandardUser();
        insert u;
        System.runAs(u)
        {
            checksum1 = SObjectChecksum.getCheckSum();
        }
        
        Job__c j = [SELECT Id, OwnerId FROM Job__c WHERE IsDeleted =false LIMIT 1];
        
        Job__Share js = new Job__Share(ParentId=j.Id, UserOrGroupId = u.Id, AccessLevel='edit', RowCause= Schema.Job__Share.RowCause.SyncAssignment__c);
        insert js;        

        System.runAs(u)
        {
            checksum2 = SObjectChecksum.getCheckSum();
        }      
        System.assert(checksum1 != checksum2, 'checksum should be the different, before/after granting permission on more item. (old/new values: ' + checksum1 + '/' + checksum2 + ')');       

        Test.stopTest();   
    }

    static testmethod void ChangesDueToSharing_Scenario2_Less()
    {
        Test.startTest();
        Datetime lastSync = Datetime.now().addMinutes(-1);

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
            
        req.requestURI = '/SObjectChecksum';
        req.httpMethod = 'GET';

        req.addParameter('sobjectName', StringUtility.FXNamespace() + 'Job__c');
        req.addParameter('lastSync', String.valueOf(lastSync));
                
        RestContext.request = req;
        RestContext.response = res;

        String checksum1, checksum2, checksum3;

        User u = AlpineTestHelper.CreateStandardUser();
        insert u;
        Job__c j = [SELECT Id, OwnerId FROM Job__c WHERE IsDeleted =false LIMIT 1];        
        Job__Share js = new Job__Share(ParentId=j.Id, UserOrGroupId = u.Id, AccessLevel='edit', RowCause= Schema.Job__Share.RowCause.SyncAssignment__c);
        insert js;       

        System.runAs(u)
        {
            checksum1 = SObjectChecksum.getCheckSum();
        }
        delete js;  
        System.runAs(u)
        {
            checksum2 = SObjectChecksum.getCheckSum();
        }      
        System.assert(checksum1 != checksum2, 'checksum should be the different, before/after removing permission on item. (old/new values: ' + checksum1 + '/' + checksum2 + ')');
 
        Test.stopTest();   
    }
    */
}