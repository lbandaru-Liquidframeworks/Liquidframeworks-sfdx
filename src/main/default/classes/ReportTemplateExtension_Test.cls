@isTest
private class ReportTemplateExtension_Test
{
   
   static testMethod void TicketReport_Test() 
   { 
      User user = [SELECT Id FROM User WHERE Id =:UserInfo.getUserId()];
      System.runAs(user)
      {
      Test.StartTest();

      string objectType = 'Ticket__c';
      string namespace = UtilityGetNamespace.CurrentNamespace();
      string objType =  objectType.startsWith(namespace)? objectType: UtilityGetNamespace.CurrentNamespace()  + objectType;

      RecordType tktRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND SobjectType =: objType LIMIT 1];
      string tktRecordTypeId = tktRecordType.Id;

      Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);

      Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
      insert catalogItem;

      Price_Book_Item__c pli = new Price_Book_Item__c(Price_Book__c = job.Price_Book__c, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
      insert pli;

      Ticket__c t= new Ticket__c(Job__c = job.Id, RecordTypeId = tktRecordType.Id);

      insert t;

      Report_Template__c rt = new Report_Template__c(Name = 'rtTest', SObject__c=objType, SObject_Record_Type_Id__c=tktRecordTypeId );
      insert rt;


      ReportTemplateExtension extension = new ReportTemplateExtension(t);
      extension.getForm();
       Test.StopTest();
    }
   }


   static testMethod void JobReport_Test() 
   { 
      User user = [SELECT Id FROM User WHERE Id =:UserInfo.getUserId()];
      System.runAs(user)
      {

         System.debug('START - JobReport_Test');
         Test.StartTest();



         Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
         System.debug('Job=' + job);

         Job__c dbJob = [SELECT CustomerAccount__c, Office__c, Segment__c, RecordTypeId, RecordType.DeveloperName FROM Job__c WHERE Id=:job.Id LIMIT 1];

         String objType =  UtilityGetNamespace.CurrentNamespace()  + 'Job__c';

           System.debug('dbJob='  + dbJob);

            System.debug('dbJob RecordType.DeveloperName='  + dbJob.RecordType.DeveloperName);


         Report_Template__c rt = new Report_Template__c(Name = 'rtTest', SObject__c=objType, SObject_Record_Type_Id__c=dbJob.RecordTypeId, Account__c=dbJob.CustomerAccount__c );
         insert rt;

         Report_Template__c dbRT = [SELECT Name,SObject__c,SObject_Record_Type_Id__c,Account__c, Office__c, Segment__c FROM Report_Template__c WHERE Id =:rt.Id LIMIT 1];
         
         System.debug('rt=' + dbRT);

         Test.StopTest();

         ReportTemplateExtension extension = new ReportTemplateExtension(dbJob);

         extension.getForm();

         List<Report_Template__c> items = ReportTemplateExtension.GetReportTemplates(job);
      
         System.assertEquals(1, items.size());
         

          System.debug('END - JobReport_Test');
      }
   }

}