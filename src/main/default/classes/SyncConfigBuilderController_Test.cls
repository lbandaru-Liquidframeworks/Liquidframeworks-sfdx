@isTest
private class SyncConfigBuilderController_Test
{
   static testMethod void runTestForCodeCoverage() 
   { 
       SyncConfigBuilderController ctrl = new SyncConfigBuilderController();

       List<Contact> contacts = CreateContacts(20);
       System.debug('contacts count = ' + contacts.size());
       ctrl.SyncConfigContacts = contacts.get(0).Id + ':' + contacts.get(0).Name;
       //ctrl.FilterSyncConfigs();
       ctrl.save();
       ctrl.resetSearcher();

       ctrl.contactObj.Office__c = contacts.get(0).Office__c;
       ctrl.keyword = 'Doe';
       ctrl.SearchContacts();

       ctrl.SaveGridEdit();
       ctrl.CancelGridEdit();

       ctrl.ResetSyncConfigFilter();

       Sync_Configuration__c sc = CreateSyncConfig();
       ctrl.SelectedSyncConfigIds = sc.Id;

       ctrl.DeleteSyncConfigs();
   }

   static testMethod void GetUniqueId_Test() 
   { 
   		Test.startTest();
   		Contact c = AlpineTestHelper.CreateContactWithTestUser('Doe', 'Joe', false);
   		c.Available_for_Field_Work__c = true;
   		insert c;

       	Sync_Configuration__c sc = new Sync_Configuration__c();

       	sc.Contact__c = c.Id;
       	sc.Sync_JobCrewOnly__c = true;

       	Account a = AlpineTestHelper.CreateAccount('UnitTest Account');
       	Account office = AlpineTestHelper.CreateOffice('Unit Test Office');

       	sc.Account__c = a.Id;
       	sc.Office__c = office.Id;

       	sc.Job_Type__c = 'UnitTestJobType';
       	sc.Segment__c = 'UnitTestSegment';

       	String uniqueId = SyncConfigBuilderController.GetUniqueId(sc);
       	insert sc;

       	Test.stopTest();

       	Sync_Configuration__c dbItem = [SELECT Id, UniqueId__c FROM Sync_Configuration__c WHERE Id=:sc.Id LIMIT 1];
       	System.assertEquals(dbItem.UniqueId__c, uniqueId);
   }

   static List<Contact> CreateContacts(Integer count)
   {
   		List<Contact> items = new List<Contact>();
   		for(Integer i=0; i<count; i++)
   		{
   			Contact c = AlpineTestHelper.CreateContactWithTestUser('Doe ' + i, 'Joe ' + i, false);
   			c.Available_for_Field_Work__c = true;
   			items.add(c);
   		}
   		insert items;
   		return [SELECT Id, Name, Office__c FROM Contact where User__c !=null AND  Available_for_Field_Work__c=true];
   }

   static Sync_Configuration__c CreateSyncConfig()
   {
      Contact c = AlpineTestHelper.CreateContactWithTestUser('Doe', 'Joe', false);
      c.Available_for_Field_Work__c = true;
      insert c;

        Sync_Configuration__c sc = new Sync_Configuration__c();

        sc.Contact__c = c.Id;
        sc.Sync_JobCrewOnly__c = true;

        Account a = AlpineTestHelper.CreateAccount('UnitTest Account');
        Account office = AlpineTestHelper.CreateOffice('Unit Test Office');

        sc.Account__c = a.Id;
        sc.Office__c = office.Id;

        sc.Job_Type__c = 'UnitTestJobType';
        sc.Segment__c = 'UnitTestSegment';

        String uniqueId = SyncConfigBuilderController.GetUniqueId(sc);
        insert sc;

        return sc;

   }
}