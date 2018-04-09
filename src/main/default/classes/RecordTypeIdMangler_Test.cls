@isTest
private class RecordTypeIdMangler_Test
{
   static testMethod void ReportTemplate_Test() 
   { 
     
       String namespace = UtilityGetNamespace.CurrentNamespace();

       Account acct = AlpineTestHelper.CreateAccount(StringUtility.newGuid());
       Account office = AlpineTestHelper.CreateOffice(StringUtility.newGuid());
       RecordType jobRecordType = AlpineTestHelper.GetRecordType(namespace + 'Job__c');
       RecordType tktRecordType = AlpineTestHelper.GetRecordType(namespace + 'Ticket__c');

       Report_Template__c rt = new Report_Template__c(Account__c=acct.Id, 
         	Job_Type__c=jobRecordType.DeveloperName, 
         	Office__c = office.Id, 
         	SObject__c = namespace + 'Ticket__c',
         	SObject_Record_Type__c = tktRecordType.DeveloperName);

        List<Report_Template__c> items = new List<Report_Template__c>();
        items.add(rt);

       RecordTypeIdMangler.PopulateRecordTypeId(items,  'SObject__c', 'SObject_Record_Type__c', 'SObject_Record_Type_Id__c');

       System.assertEquals(rt.SObject_Record_Type_Id__c, tktRecordType.Id);  

       rt.SObject_Record_Type_Id__c = null;
       insert rt;

       Report_Template__c dbItem = [SELECT SObject_Record_Type_Id__c FROM Report_Template__c WHERE Office__c = : office.Id LIMIT 1];
        System.assertEquals(dbItem.SObject_Record_Type_Id__c, tktRecordType.Id);  
   }


   static testmethod void eFormConfig_Test()
    {
       
        Test.StartTest();
        
        eForm_Config__c newItem = new eForm_Config__c();

        newItem.Account__c = AlpineTestHelper.CreateAccount(StringUtility.newGuid()).Id;
        newItem.Office__c =  AlpineTestHelper.CreateOffice(StringUtility.newGuid()).Id;
       
        RecordType rtFormObject = AlpineTestHelper.GetRecordType(UtilityGetNamespace.CurrentNamespace()  + 'Job__c');
    
        RecordType rtKeyObject = AlpineTestHelper.GetRecordType(UtilityGetNamespace.CurrentNamespace()  + 'Ticket__c');

        newItem.eForm_SObject__c = 'Job__c';
        //newItem.eForm_SObject__c = UtilityGetNamespace.CurrentNamespace()  + 'Job__c';
        
        newItem.eForm_SObject_Record_Type__c = rtFormObject.DeveloperName;

        newItem.Key_SObject__c = UtilityGetNamespace.CurrentNamespace()  + 'Ticket__c';
        newItem.Key_SObject_Record_Type__c = rtKeyObject.DeveloperName;

        insert newItem;
      
      
        Test.StopTest();
 
        eForm_Config__c dbItem = [SELECT Id, eForm_SObject__c, eForm_SObject_Record_Type__c, eForm_SObject_Record_Type_Id__c, Key_SObject__c, Key_SObject_Record_Type__c,  Key_SObject_Record_Type_Id__c FROM eForm_Config__c WHERE Id =:newItem.Id];   

        System.assertEquals(rtFormObject.DeveloperName, dbItem.eForm_SObject_Record_Type__c);  
        System.assertEquals(rtFormObject.Id, dbItem.eForm_SObject_Record_Type_Id__c);  


        System.assertEquals(rtKeyObject.DeveloperName, dbItem.Key_SObject_Record_Type__c);  
        System.assertEquals(rtKeyObject.Id, dbItem.Key_SObject_Record_Type_Id__c);  
    }
}