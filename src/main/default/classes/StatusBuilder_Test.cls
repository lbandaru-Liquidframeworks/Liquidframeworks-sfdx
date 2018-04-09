@isTest
private class StatusBuilder_Test 
{    
    static testmethod void OnlyOneInitialMobileStatus_BulkInsert()
    {
        Test.StartTest();   
        String newGuid = StringUtility.newGuid();   

        RecordType rt = AlpineTestHelper.GetRecordType('Status__c');

        RecordType rtJob = AlpineTestHelper.GetRecordType('Job__c');
                
        List<Status__c> items = new List<Status__c>();
        Integer count = 100;
        for(Integer i = 0; i<count; i++)
        {
              Status__c s = new Status__c(Name = 's' + string.valueOf(i), SObject__c= 'Job__c', SObject_Record_Type__c = rtJob.DeveloperName, Initial_Status_Mobile__c =true, RecordTypeId=rt.Id);
              items.add(s);        
        }
        insert items;       
      
        Test.StopTest();      

        List<Status__c> dbItems = [SELECT Id, Name FROM Status__c WHERE RecordTypeId=:rt.Id AND Initial_Status_Mobile__c =true];
        System.assertEquals(1, dbItems.size());
    }     

    static testmethod void OnlyOneInitialMobileStatus_Insert()
    {
        Test.StartTest();   
        String newGuid = StringUtility.newGuid();   
        
        RecordType rt = AlpineTestHelper.GetRecordType('Status__c');
        RecordType rtJob = AlpineTestHelper.GetRecordType('Job__c');
    
        List<Status__c> items = new List<Status__c>();
        Integer count = 100;
        for(Integer i = 0; i<count; i++)
        {
              Status__c s = new Status__c(Name = 's' + string.valueOf(i), SObject__c= 'Job__c', SObject_Record_Type__c = rtJob.DeveloperName, Initial_Status_Mobile__c =true, RecordTypeId=rt.Id);
              items.add(s);        
        }
        insert items;       
      
        Status__c s1 = new Status__c(Name = 'Final' + newGuid, SObject__c= 'Job__c', SObject_Record_Type__c = rtJob.DeveloperName, Initial_Status_Mobile__c =true, RecordTypeId=rt.Id);

        insert s1;

        Test.StopTest();      

        List<Status__c> dbItems = [SELECT Id, Name FROM Status__c WHERE SObject__c = 'Job__c' AND SObject_Record_Type__c = :rtJob.DeveloperName AND Initial_Status_Mobile__c =true];
        System.assertEquals(1, dbItems.size());
        System.assertEquals('Final' + newGuid, dbItems.get(0).Name);
    } 

    static testmethod void OnlyOneInitialMobileStatus_Update()
    {
        Test.StartTest();   
        String newGuid = StringUtility.newGuid();   
        
        RecordType rt = AlpineTestHelper.GetRecordType('Status__c');

        RecordType rtJob = AlpineTestHelper.GetRecordType('Job__c');

    
        List<Status__c> items = new List<Status__c>();
        Integer count = 100;
        for(Integer i = 0; i<count; i++)
        {
              Status__c s = new Status__c(Name = 's' + string.valueOf(i), SObject__c= 'Job__c', SObject_Record_Type__c = rtJob.DeveloperName,  Initial_Status_Mobile__c =true, RecordTypeId=rt.Id);
              items.add(s);        
        }
        insert items;       
      
        Status__c s1 = new Status__c(Name = 'Final' + newGuid, SObject__c= 'Job__c', SObject_Record_Type__c = rtJob.DeveloperName, Initial_Status_Mobile__c =true, RecordTypeId=rt.Id);

        
        List<Status__c> itemsToUpdate = [SELECT Initial_Status_Mobile__c, Name, Id FROM Status__c WHERE RecordTypeId=:rt.Id AND (Name='s0' OR Name='s1')];
        for(Status__c s : itemsToUpdate)
        {
            s.Initial_Status_Mobile__c = true;
        }
        update itemsToUpdate;
      

        Test.StopTest();      

        List<Status__c> dbItems = [SELECT Id, Name FROM Status__c WHERE RecordTypeId=:rt.Id AND Initial_Status_Mobile__c =true];
        System.assertEquals(1, dbItems.size());
        System.assert(dbItems.get(0).Name == 's0' || dbItems.get(0).Name == 's1');


    } 


    static testmethod void OnlyOneInitialConsoleStatus_Insert()
    {
        Test.StartTest();   
        String newGuid = StringUtility.newGuid();   
        
        RecordType rt = AlpineTestHelper.GetRecordType('Status__c');
        RecordType rtJob = AlpineTestHelper.GetRecordType('Job__c');


    
        List<Status__c> items = new List<Status__c>();
        Integer count = 100;
        for(Integer i = 0; i<count; i++)
        {
              Status__c s = new Status__c(Name = 's' + string.valueOf(i), SObject__c= 'Job__c', SObject_Record_Type__c = rtJob.DeveloperName, Initial_Status_Console__c =true, RecordTypeId=rt.Id);
              items.add(s);        
        }
        insert items;       
      
        Status__c s1 = new Status__c(Name = 'Final' + newGuid, SObject__c= 'Job__c', SObject_Record_Type__c = rtJob.DeveloperName,  Initial_Status_Console__c =true, RecordTypeId=rt.Id);

        insert s1;

        Test.StopTest();      

        List<Status__c> dbItems = [SELECT Id, Name FROM Status__c WHERE SObject__c= 'Job__c' AND SObject_Record_Type__c = :rtJob.DeveloperName AND Initial_Status_Console__c =true];
        System.assertEquals(1, dbItems.size());
        System.assertEquals('Final' + newGuid, dbItems.get(0).Name);
    } 


    static testmethod void OnlyOneInitialConsoleStatus_Update()
    {
        Test.StartTest();   
        String newGuid = StringUtility.newGuid();   
       
         RecordType rt = AlpineTestHelper.GetRecordType('Status__c');
        RecordType rtJob = AlpineTestHelper.GetRecordType('Job__c');

    
        List<Status__c> items = new List<Status__c>();
        Integer count = 100;
        for(Integer i = 0; i<count; i++)
        {
              Status__c s = new Status__c(Name = 's' + string.valueOf(i), SObject__c= 'Job__c', SObject_Record_Type__c = rtJob.DeveloperName,Initial_Status_Console__c =true, RecordTypeId=rt.Id);
              items.add(s);        
        }
        insert items;       
      
        Status__c s1 = new Status__c(Name = 'Final' + newGuid, SObject__c= 'Job__c', SObject_Record_Type__c = rtJob.DeveloperName, Initial_Status_Console__c =true, RecordTypeId=rt.Id);

        
        List<Status__c> itemsToUpdate = [SELECT Initial_Status_Console__c, Name, Id FROM Status__c WHERE RecordTypeId=:rt.Id AND (Name='s0' OR Name='s1')];
        for(Status__c s : itemsToUpdate)
        {
            s.Initial_Status_Console__c = true;
        }
        update itemsToUpdate;
      

        Test.StopTest();      

        List<Status__c> dbItems = [SELECT Id, Name FROM Status__c WHERE SObject__c= 'Job__c' AND SObject_Record_Type__c = :rtJob.DeveloperName AND Initial_Status_Console__c =true];
        System.assertEquals(1, dbItems.size());
        System.assert(dbItems.get(0).Name == 's0' || dbItems.get(0).Name == 's1');
    } 


    static testmethod void OnlyOneInitialStatus_Insert()
    {
        Test.StartTest();   
        String newGuid = StringUtility.newGuid();   
        
        RecordType rt = AlpineTestHelper.GetRecordType('Status__c');
        RecordType rtJob = AlpineTestHelper.GetRecordType('Ticket__c');

        List<Status__c> items = new List<Status__c>();
        Integer count = 100;
        for(Integer i = 0; i<count; i++)
        {
              Status__c s = new Status__c(Name = 's' + string.valueOf(i), SObject__c= 'Ticket__c', SObject_Record_Type__c = rtJob.DeveloperName, Initial_Status_Console__c =true, Initial_Status_Mobile__c=true, RecordTypeId=rt.Id);
              items.add(s);        
        }
        insert items;       
      
        Status__c s1 = new Status__c(Name = 'Final' + newGuid, SObject__c= 'Ticket__c', SObject_Record_Type__c = rtJob.DeveloperName, Initial_Status_Console__c =true, 
        Initial_Status_Mobile__c=true, RecordTypeId=rt.Id);

        insert s1;

        Test.StopTest();      

        List<Status__c> dbItems = [SELECT Id, Name FROM Status__c WHERE SObject__c= 'Ticket__c' AND SObject_Record_Type__c = :rtJob.DeveloperName AND Initial_Status_Console__c =true AND Initial_Status_Mobile__c=true];
        System.assertEquals(1, dbItems.size());
        System.assertEquals('Final' + newGuid, dbItems.get(0).Name);
    }

    static testmethod void OnlyOneInitialStatus_Update()
    {
        Test.StartTest();   
        String newGuid = StringUtility.newGuid();   
        
        RecordType rt = AlpineTestHelper.GetRecordType('Status__c');
        RecordType rtJob = AlpineTestHelper.GetRecordType('Ticket__c');

    
        List<Status__c> items = new List<Status__c>();
        Integer count = 100;
        for(Integer i = 0; i<count; i++)
        {
              Status__c s = new Status__c(Name = 's' + string.valueOf(i), SObject__c= 'Ticket__c', SObject_Record_Type__c = rtJob.DeveloperName,Initial_Status_Console__c =true, Initial_Status_Mobile__c =true, RecordTypeId=rt.Id);
              items.add(s);        
        }
        insert items;               
        
        List<Status__c> itemsToUpdate = [SELECT Initial_Status_Console__c, Initial_Status_Mobile__c, Name, Id FROM Status__c WHERE SObject__c= 'Ticket__c' AND SObject_Record_Type__c = :rtJob.DeveloperName AND (Name='s0' OR Name='s1')];
        for(Status__c s : itemsToUpdate)
        {
            s.Initial_Status_Console__c = true;
            s.Initial_Status_Mobile__c = true;
        }
        update itemsToUpdate;
      

        Test.StopTest();      

        List<Status__c> dbItems = [SELECT Id, Name FROM Status__c WHERE SObject__c= 'Ticket__c' AND SObject_Record_Type__c = :rtJob.DeveloperName AND Initial_Status_Console__c =true AND Initial_Status_Mobile__c=true];
        System.assertEquals(1, dbItems.size());
        System.assert(dbItems.get(0).Name == 's0' || dbItems.get(0).Name == 's1');
    } 
}