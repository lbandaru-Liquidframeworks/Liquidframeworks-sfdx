@isTest
private class JobResourcePlanning_Test
{
    static void SetupCrewPlanning(Boolean skipTrigger)
    {
        FX_Settings__c s = FX_Settings__c.getInstance(UserInfo.getUserId());
        s.CrewPlanningSkipAssignPriceBookItem__c = skipTrigger;
        s.AutoAddJobCreatorToCrew__c = false;
        upsert s;

        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        
        List<Price_Book_Item__c> pbiItems =  AlpineTestHelper.CreatePriceBookItems(5, j.Price_Book__c, 'Labor', true);        
        Price_Book_Item__c pbi = pbiItems.get(0); 

        Contact c = AlpineTestHelper.CreateContactWithStandardUser(false);
        c.Available_for_Field_Work__c = true;
        c.Catalog_Item__c = pbi.Catalog_Item__c;
        insert c;

        Contact c2 = AlpineTestHelper.CreateContactWithStandardUser(false);
        c2.Available_for_Field_Work__c = true;
        c2.Catalog_Item__c = pbiItems.get(1).Catalog_Item__c;
        insert c2;


    }

    static void SetupEquipmentPlanning(Boolean skipTrigger)
    {
        FX_Settings__c s = FX_Settings__c.getInstance(UserInfo.getUserId());
        s.EquipmentPlanningSkipAssignPriceBookItem__c = skipTrigger;
        s.AutoAddJobCreatorToCrew__c = false;
        upsert s;

        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        List<Price_Book_Item__c> pbiItems = AlpineTestHelper.CreatePriceBookItems(5, j.Price_Book__c, 'Equipment', true);
        Price_Book_Item__c pbi = pbiItems.get(0);

        Equipment__c e = AlpineTestHelper.CreateEquipment(false);
        e.Catalog_Item__c = pbi.Catalog_Item__c;
        insert e;

        Equipment__c e2 = AlpineTestHelper.CreateEquipment(false);
        e2.Catalog_Item__c = pbiItems.get(1).Catalog_Item__c;
        insert e2;

    }
    static testmethod void CrewPlanningSkipTriggerTest()
    {
        Test.startTest();
        SetupCrewPlanning(true);

        Job__c j = [SELECT Id FROM Job__c LIMIT 1];
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Crew_Planning__c cp = new Crew_Planning__c(Job__c = j.Id, Crew_Member__c = c.Id);
        insert cp;

        Test.stopTest();

        Crew_Planning__c dbItem =  [SELECT Id, Role_on_Job__c FROM Crew_Planning__c WHERE Id =:cp.Id];
        System.assert(String.isBlank(dbItem.Role_on_Job__c), 'Role_on_Job__c should be null instead of ' + dbItem.Role_on_Job__c);

    }

    static testmethod void CrewPlanningSwitchContact_Test()
    {
       
        SetupCrewPlanning(false);

        Job__c j = [SELECT Id FROM Job__c LIMIT 1];
        List<Contact> contacts =  [SELECT Id, Catalog_Item__c FROM Contact];        
        Crew_Planning__c cp = new Crew_Planning__c(Job__c = j.Id, Crew_Member__c = contacts.get(0).Id);
        insert cp;

        Test.startTest();
        Crew_Planning__c dbItem = [SELECT Id, Role_on_Job__c, Crew_Member__c FROM Crew_Planning__c WHERE Id=:cp.Id];
        System.assert(!String.isBlank(dbItem.Role_on_Job__c), 'Role_on_Job__c should not be null');
        dbItem.Crew_Member__c = contacts.get(1).Id;
        update dbItem;
        Test.stopTest();

        Crew_Planning__c dbItem2 = [SELECT Id, Role_on_Job__c, Crew_Member__c FROM Crew_Planning__c WHERE Id=:cp.Id];

        System.debug('before :' + dbItem.Role_on_Job__c);
        System.debug('after :' + dbItem2.Role_on_Job__c);

        System.assert(!String.isBlank(dbItem2.Role_on_Job__c) && dbItem.Role_on_Job__c!=dbItem2.Role_on_Job__c,
            'Role_on_Job__c should have been updated using the new Crew Member\'s Catalog Item ');

    }

    static testmethod void EquipmentPlanningSwitchEquipment_Test()
    {
       
        SetupEquipmentPlanning(false);

        Job__c j = [SELECT Id FROM Job__c LIMIT 1];
        List<Equipment__c> equipItems = [SELECT Id FROM Equipment__c];
        Equipment__c e = equipItems.get(0);
        Equipment_Planning__c ep = new Equipment_Planning__c(Job__c = j.Id, Equipment2__c = e.Id);
        insert ep;

        Test.startTest();

        Equipment_Planning__c dbItem =  [SELECT Id, Equipment2__c, Price_Book_Item__c FROM Equipment_Planning__c WHERE Id =:ep.Id];
        
        System.assert(!String.isBlank(dbItem.Equipment2__c), 'Equipment2__c should not be null');
        dbItem.Equipment2__c = equipItems.get(1).Id;
        update dbItem;
        Test.stopTest();

        Equipment_Planning__c dbItem2 = [SELECT Id, Equipment2__c, Price_Book_Item__c FROM Equipment_Planning__c WHERE Id =:ep.Id];
       
        System.assert(!String.isBlank(dbItem2.Equipment2__c) && dbItem.Price_Book_Item__c!=dbItem2.Price_Book_Item__c,
            'Price_Book_Item__c should have been updated using the new Equipment\'s Catalog Item ');

    }


    static testmethod void CrewPlanningAssignRole_on_JobTest()
    {
        Test.startTest();
        SetupCrewPlanning(false);

        Job__c j = [SELECT Id FROM Job__c LIMIT 1];
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Crew_Planning__c cp = new Crew_Planning__c(Job__c = j.Id, Crew_Member__c = c.Id);
        insert cp;

        Test.stopTest();

        Crew_Planning__c dbItem =  [SELECT Id, Role_on_Job__c FROM Crew_Planning__c WHERE Id =:cp.Id];
        System.assert(!String.isBlank(dbItem.Role_on_Job__c), 'Role_on_Job__c should have value instead of null ');

    }

    static testmethod void EquipmentPlanningSkipTriggerTest()
    {
        Test.startTest();
        SetupEquipmentPlanning(true);

        Job__c j = [SELECT Id FROM Job__c LIMIT 1];
        Equipment__c e = [SELECT Id FROM Equipment__c LIMIT 1];
        Equipment_Planning__c ep = new Equipment_Planning__c(Job__c = j.Id, Equipment2__c = e.Id);
        insert ep;

        Test.stopTest();

        Equipment_Planning__c dbItem =  [SELECT Id, Price_Book_Item__c FROM Equipment_Planning__c WHERE Id =:ep.Id];
        System.assert(String.isBlank(dbItem.Price_Book_Item__c), 'Price_Book_Item__c should be null instead of ' + dbItem.Price_Book_Item__c);

    }

    static testmethod void EquipmentPlanningAssignRole_on_JobTest()
    {
        Test.startTest();
        SetupEquipmentPlanning(false);

        Job__c j = [SELECT Id FROM Job__c LIMIT 1];
        Equipment__c e = [SELECT Id FROM Equipment__c LIMIT 1];
        Equipment_Planning__c ep = new Equipment_Planning__c(Job__c = j.Id, Equipment2__c = e.Id);
        insert ep;

        Test.stopTest();

        Equipment_Planning__c dbItem =  [SELECT Id, Price_Book_Item__c FROM Equipment_Planning__c WHERE Id =:ep.Id];
        System.assert(!String.isBlank(dbItem.Price_Book_Item__c), 'Price_Book_Item__c should have value instead of null ');

    }

   
}