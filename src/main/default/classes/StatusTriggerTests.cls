@isTest
private class StatusTriggerTests
{
   static testmethod void SetJobInitialStatus()
   {
   		String objType = UtilityGetNamespace.CurrentNamespace()  + 'Status__c';
        RecordType rtStatus = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SObjectType = :objType LIMIT 1];

  		objType = UtilityGetNamespace.CurrentNamespace()  + 'Job__c';
        RecordType rtJob = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SObjectType = :objType LIMIT 1];

		Job__c j = AlpineTestHelper.CreateJobs(1, false).get(0);

		Status__c s = new Status__c(Name='New Job', SObject__c='Job__c', SObject_Record_Type__c = rtJob.DeveloperName, RecordTypeId=rtStatus.Id, Initial_Status_Console__c=true);
		insert s;
        
        string jobName = 'Job' + StringUtility.newGuid();
       
        j.RecordTypeId = rtJob.Id;
        j.Name = jobName;
        j.Status__c = null;

        Insert j;
		
		Job__c dbJob = [SELECT Status__c FROM Job__c where Name =:jobName LIMIT 1];	
		System.assertEquals(s.Id, dbJob.Status__c);		
	}
	
	static testmethod void SetTicketInitialStatus(){
     	String objType = UtilityGetNamespace.CurrentNamespace()  + 'Status__c';
        RecordType rtStatus = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SObjectType = :objType LIMIT 1];

        objType = UtilityGetNamespace.CurrentNamespace()  + 'Ticket__c';
        RecordType rtTkt = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SObjectType = :objType LIMIT 1];

		
		Status__c s = new Status__c(Name='New Ticket', SObject__c='Ticket__c', SObject_Record_Type__c = rtTkt.DeveloperName, RecordTypeId=rtStatus.Id, Initial_Status_Console__c=true);
		insert s;

		Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);		  
		Ticket__c t= new Ticket__c(Job__c = job.Id, RecordTypeId= rtTkt.Id);
        insert t;
		
		Ticket__c tkt =  [SELECT Id, Status__c FROM Ticket__c WHERE Job__c= :job.Id LIMIT 1];  
		System.assertEquals(s.Id, tkt.Status__c);
	}
	
	static testmethod void StatusOnlyOneInitialStatusForConsole(){	
		TestOnlyOneInitialStatus(true);
	}
	
	static testmethod void StatusOnlyOneInitialStatusForMobile(){
	
		TestOnlyOneInitialStatus(false);
	}
	
	static void TestOnlyOneInitialStatus(Boolean trueForConsole_FalseForMobile){
		Boolean isInitial_Status_Console = false;
		Boolean isInitial_Status_Mobile = false; 	
		if(trueForConsole_FalseForMobile)
		{
			isInitial_Status_Console = true;
		}
		else
		{
			isInitial_Status_Mobile = true;
		}
		String objType = UtilityGetNamespace.CurrentNamespace()  + 'Status__c';
        RecordType rt = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SObjectType = :objType LIMIT 1];

        objType = UtilityGetNamespace.CurrentNamespace()  + 'Job__c';
        RecordType rtJob = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SObjectType = :objType LIMIT 1];

	
		String statusName = StringUtility.newGuid();
		Status__c s1 = new Status__c(Name=statusName, SObject__c='Job__c', SObject_Record_Type__c=rtJob.DeveloperName, RecordTypeId=rt.Id, Initial_Status_Console__c =isInitial_Status_Console, Initial_Status_Mobile__c=isInitial_Status_Mobile);
		insert s1;
		List<Status__c> statusItems = [select Id, Name from Status__c where Initial_Status_Console__c =:isInitial_Status_Console AND Initial_Status_Mobile__c=:isInitial_Status_Mobile AND SObject__c = 'Job__c'];
		System.assertEquals(statusItems.size(), 1);
		System.assertEquals(statusItems[0].Name, statusName);
		
		statusName = StringUtility.newGuid();
		Status__c s2 = new Status__c(Name=statusName, SObject__c='Job__c', SObject_Record_Type__c=rtJob.DeveloperName, RecordTypeId=rt.Id, Initial_Status_Console__c =isInitial_Status_Console, Initial_Status_Mobile__c=isInitial_Status_Mobile);
		insert s2;
		statusItems =[select Id, Name from Status__c where Initial_Status_Console__c =:isInitial_Status_Console AND Initial_Status_Mobile__c=:isInitial_Status_Mobile AND SObject__c = 'Job__c'];
		System.assertEquals(statusItems.size(), 1);
		System.assertEquals(statusItems[0].Name, statusName);
		
		statusName = StringUtility.newGuid();
		Status__c s3 = new Status__c(Name=statusName, SObject__c='Job__c', SObject_Record_Type__c=rtJob.DeveloperName, RecordTypeId=rt.Id, Initial_Status_Console__c =isInitial_Status_Console, Initial_Status_Mobile__c=isInitial_Status_Mobile);
		insert s3;
		statusItems = [select Id, Name from Status__c where Initial_Status_Console__c =:isInitial_Status_Console AND Initial_Status_Mobile__c=:isInitial_Status_Mobile AND SObject__c = 'Job__c'];
		System.assertEquals(statusItems.size(), 1);
		System.assertEquals(statusItems[0].Name, statusName);
		
		
		s2.Initial_Status_Console__c = isInitial_Status_Console;
		s2.Initial_Status_Mobile__c = isInitial_Status_Mobile;
		update s2;
		
		statusItems =[select Id, Name from Status__c where Initial_Status_Console__c =:isInitial_Status_Console AND Initial_Status_Mobile__c=:isInitial_Status_Mobile AND SObject__c = 'Job__c'];
		System.assertEquals(statusItems.size(), 1);
		System.assertEquals(statusItems[0].Name, s2.Name);
	}
}