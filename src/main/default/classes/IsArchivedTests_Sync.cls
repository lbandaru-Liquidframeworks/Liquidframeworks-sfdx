@isTest
private class IsArchivedTests_Sync
{
   static testMethod void Account_Archived() 
   { 
       string newGuid = StringUtility.newGuid();
       string acctName = 'Account ' + newGuid;
       Account acct = new Account(Name = acctName); 
       insert acct;
       
       string priceListName = 'Price Book ' + newGuid ;
       Price_Book__c priceBook = new Price_Book__c(Name = priceListName, Account__c = acct.Id, Global_Price_Book__c = true);
       
       insert priceBook;  
       
       RecordType officeRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = 'Account' and DeveloperName = 'office'];
       Account office = new Account(name= 'Office ' + StringUtility.newGuid(), RecordTypeId = officeRecordType.Id);
       insert office;
       
       RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  
       string statusName = 'JobStatus ' + newGuid;
       Status__c jobStatus = new Status__c(Name = statusName, SObject__c='Job__c', Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);
       insert jobStatus;
           
       RecordType jobRecordType = AlpineTestHelper.GetRecordType('Job__c');  
       Job__c job = new Job__c(Name='Job ' + newGuid , Status__c = jobStatus.Id, CustomerAccount__c = acct.Id, Office__c = office.Id, Price_Book__c = priceBook.Id, RecordTypeId= jobRecordType.Id);
       insert job;
       
       Test.StartTest();
       
       Job__c j1 = [SELECT Sync__c FROM Job__c where Id = : job.Id LIMIT 1];
       System.assert(j1.Sync__c);
       
       Price_Book__c pb = [SELECT Is_Active__c, Global_Price_Book__c FROM Price_Book__c where Id = : priceBook.Id LIMIT 1];
       System.assert(pb.Global_Price_Book__c );
       System.assert(pb.Is_Active__c);
       
       Account a= [SELECT Id, IsArchived__c FROM Account where Id = : acct.Id LIMIT 1];
       System.assert(!a.IsArchived__c );
       
       a.IsArchived__c  = true;
       update a;     
       
       Test.StopTest();
       
       a= [SELECT Id, IsArchived__c FROM Account where Id = : acct.Id LIMIT 1];
       System.assert(a.IsArchived__c );      
       
       pb = [SELECT Is_Active__c, Global_Price_Book__c FROM Price_Book__c where Id = : priceBook.Id LIMIT 1];
       System.assert(!pb.Global_Price_Book__c );
       System.assert(!pb.Is_Active__c);      
       
   }
   static testMethod void Account_Unarchived() 
   { 
       string newGuid = StringUtility.newGuid();
       string acctName = 'Account ' + newGuid;
       Account acct = new Account(Name = acctName); 
       insert acct;
       
       string priceListName = 'Price Book ' + newGuid ;
       Price_Book__c priceBook = new Price_Book__c(Name = priceListName, Account__c = acct.Id, Global_Price_Book__c = true);
       
       insert priceBook;  
       
       RecordType officeRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = 'Account' and DeveloperName = 'office'];
       Account office = new Account(name= 'Office ' + StringUtility.newGuid(), RecordTypeId = officeRecordType.Id);
       insert office;
       
       RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  
       string statusName = 'JobStatus ' + newGuid;
       Status__c jobStatus = new Status__c(Name = statusName, SObject__c='Job__c', Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);
       insert jobStatus;
           
       RecordType jobRecordType = AlpineTestHelper.GetRecordType('Job__c');  
       Job__c job = new Job__c(Name='Job ' + newGuid , Status__c = jobStatus.Id, CustomerAccount__c = acct.Id, Office__c = office.Id, Price_Book__c = priceBook.Id, RecordTypeId= jobRecordType.Id);
       insert job;
       
       Account a= [SELECT Id, IsArchived__c FROM Account where Id = : acct.Id LIMIT 1];
       a.IsArchived__c  = true;
       update a; 
       
       Test.StartTest();    
     
       
       Price_Book__c pb = [SELECT Is_Active__c, Global_Price_Book__c FROM Price_Book__c where Id = : priceBook.Id LIMIT 1];
       System.assert(!pb.Global_Price_Book__c );
       System.assert(!pb.Is_Active__c);
       
       Account  a2 = [SELECT Id, IsArchived__c FROM Account where Id = : acct.Id LIMIT 1];
       System.assert(a2.IsArchived__c );
       
       a2.IsArchived__c  = false;
       update a2;
       
       Test.StopTest();
       
       a = [SELECT Id, IsArchived__c FROM Account where Id = : acct.Id LIMIT 1];
       System.assert(!a.IsArchived__c);      
   
       
       pb = [SELECT Is_Active__c, Global_Price_Book__c FROM Price_Book__c where Id = : priceBook.Id LIMIT 1];
       System.assert(pb.Is_Active__c); 
   }
   
   static testMethod void PriceBook_Archived() 
   { 
       string newGuid = StringUtility.newGuid();
       string acctName = 'Account ' + newGuid;
       Account acct = new Account(Name = acctName); 
       insert acct;
       
       string priceListName = 'Price Book ' + newGuid ;
       Price_Book__c priceBook = new Price_Book__c(Name = priceListName, Account__c = acct.Id, Global_Price_Book__c = true);
       
       insert priceBook;  
       
       RecordType officeRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = 'Account' and DeveloperName = 'office'];
       Account office = new Account(name= 'Office ' + newGuid , RecordTypeId = officeRecordType.Id);
       insert office;
       
       RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  
       string statusName = 'JobStatus ' + newGuid;
       Status__c jobStatus = new Status__c(Name = statusName, SObject__c='Job__c', Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);
       insert jobStatus;
           
       RecordType jobRecordType = AlpineTestHelper.GetRecordType('Job__c');  
       Job__c job = new Job__c(Name='Job ' + newGuid , Status__c = jobStatus.Id, CustomerAccount__c = acct.Id, Office__c = office.Id, Price_Book__c = priceBook.Id, RecordTypeId= jobRecordType.Id);
       insert job;
       
     
       
       Test.StartTest();       
       
       Job__c j1 = [SELECT Sync__c FROM Job__c where Id = : job.Id LIMIT 1];
       System.assert(j1.Sync__c);
       
       Price_Book__c pb = [SELECT Is_Active__c, Global_Price_Book__c FROM Price_Book__c where Id = : priceBook.Id LIMIT 1];
       System.assert(pb.Global_Price_Book__c );
       System.assert(pb.Is_Active__c);
       
       pb.IsArchived__c = true;
       update pb;
       
       Test.StopTest();
       
       pb = [SELECT Is_Active__c, Global_Price_Book__c, IsArchived__c  FROM Price_Book__c where Id = : priceBook.Id LIMIT 1];
       System.assert(pb.IsArchived__c );
       System.assert(!pb.Global_Price_Book__c );
       System.assert(!pb.Is_Active__c);
       
            
   }
   static testMethod void PriceBook_Unarchived() 
   { 
       string newGuid = StringUtility.newGuid();
       string acctName = 'Account ' + newGuid;
       Account acct = new Account(Name = acctName); 
       insert acct;
       
       string priceListName = 'Price Book ' + newGuid ;
       Price_Book__c priceBook = new Price_Book__c(Name = priceListName, Account__c = acct.Id, Global_Price_Book__c = true);
       
       insert priceBook;  
       
       RecordType officeRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = 'Account' and DeveloperName = 'office'];
       Account office = new Account(name= 'Office ' + newGuid , RecordTypeId = officeRecordType.Id);
       insert office;
       
       RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  
       string statusName = 'JobStatus ' + newGuid;
       Status__c jobStatus = new Status__c(Name = statusName, SObject__c='Job__c', Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);
       insert jobStatus;
           
       RecordType jobRecordType = AlpineTestHelper.GetRecordType('Job__c');  
       Job__c job = new Job__c(Name='Job ' + newGuid , Status__c = jobStatus.Id, CustomerAccount__c = acct.Id, Office__c = office.Id, Price_Book__c = priceBook.Id, RecordTypeId= jobRecordType.Id);
       insert job;
       
       Price_Book__c pb = [SELECT Is_Active__c, Global_Price_Book__c, IsArchived__c  FROM Price_Book__c where Id = : priceBook.Id LIMIT 1];
       pb.IsArchived__c = true;
       update pb;
       
       Test.StartTest();       
       
       //Job__c j1 = [SELECT Sync__c FROM Job__c where Id = : job.Id LIMIT 1];
       //System.assert(!j1.Sync__c);
       
       pb = [SELECT Is_Active__c, Global_Price_Book__c, IsArchived__c  FROM Price_Book__c where Id = : priceBook.Id LIMIT 1];
       System.assert(!pb.Global_Price_Book__c );
       System.assert(!pb.Is_Active__c);
       System.assert(pb.IsArchived__c  );
       
       pb.IsArchived__c = false;
       update pb;
       
       Test.StopTest();
       
       pb = [SELECT Is_Active__c, Global_Price_Book__c, IsArchived__c FROM Price_Book__c where Id = : priceBook.Id LIMIT 1];
       System.assert(!pb.IsArchived__c);
       System.assert(pb.Is_Active__c);
           
   }
}