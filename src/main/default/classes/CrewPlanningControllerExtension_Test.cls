@isTest
private class CrewPlanningControllerExtension_Test {

    static testMethod void newCrewPlaningTest() 
    {

        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);       
        PageReference page = new PageReference('Crew_Planning');
        page.getParameters().put('retURL', '/' + job.Id);
        Test.setCurrentPage(page);        
      
        CrewPlanningControllerExtension  ext = new CrewPlanningControllerExtension (new ApexPages.StandardController(new Crew_Planning__c()));   
     
        PageReference p2 = ext.doCancel();   
        Test.stopTest();
    }  

    static testMethod void editCrewPlaningTest() 
    {

        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);   
        List<Price_Book_Item__c> pliItems = CreatePriceBookItems(5, job.Price_Book__c, 'Labor');

        RecordType officeRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = 'Account' and DeveloperName != 'office' LIMIT 1];
        Account acct = new Account(name='Account123', RecordTypeId = officeRecordType.Id);
        insert acct;

        Contact p1 = new Contact(FirstName='Jane', LastName='Doe', Account = acct);
        insert p1;


        Crew_Planning__c cp = new Crew_Planning__c(Job__c = job.Id, Role_on_Job__c = pliItems.get(0).Id, Crew_Member__c = p1.Id);
        insert cp;

        PageReference page = new PageReference('Crew_Planning');
        page.getParameters().put('id', cp.Id);
        Test.setCurrentPage(page);        
      
        CrewPlanningControllerExtension  ext = new CrewPlanningControllerExtension (new ApexPages.StandardController(cp));   
     
        PageReference p2 = ext.save();   
        Test.stopTest();
    }  

    static testMethod void saveAndNewTest() 
    {

        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);   
        List<Price_Book_Item__c> pliItems = CreatePriceBookItems(5, job.Price_Book__c, 'Labor');

        RecordType officeRecordType = [SELECT Id, Name, DeveloperName FROM RecordType where IsActive=true AND  SobjectType = 'Account' and DeveloperName != 'office' LIMIT 1];
        Account acct = new Account(name='Account123', RecordTypeId = officeRecordType.Id);
        insert acct;

        Contact p1 = new Contact(FirstName='Jane', LastName='Doe', Account = acct);
        insert p1;


        Crew_Planning__c cp = new Crew_Planning__c(Job__c = job.Id, Role_on_Job__c = pliItems.get(0).Id, Crew_Member__c = p1.Id);
        insert cp;

        PageReference page = new PageReference('Crew_Planning');
        page.getParameters().put('id', cp.Id);
        Test.setCurrentPage(page);        
      
        CrewPlanningControllerExtension  ext = new CrewPlanningControllerExtension (new ApexPages.StandardController(cp));   
     
        PageReference p2 = ext.saveAndNew();   
        Test.stopTest();
    }  

   
    static List<Price_Book_Item__c> CreatePriceBookItems(Integer itemsCount, Id priceBookId, string itemType)
    {
        List<Catalog_Item__c> catalogItems = new List<Catalog_Item__c>();
        for(Integer i=0; i<itemsCount; i++)
        {
            catalogItems.add(new Catalog_Item__c(Name= 'CI' + i , Description__c = 'Test Catalog Item' + i, UOM__c='Gal', Sequence_Number__c=i,  Ticket_Item_Record_Type__c = itemType));
        }
        insert catalogItems;

        List<Price_Book_Item__c> pliItems = new List<Price_Book_Item__c>();
        for(Integer i=0; i<itemsCount; i++)
        {
            pliItems.add(new Price_Book_Item__c(Price_Book__c = priceBookId, Price__c=i+3, Sequence_Number__c =i, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItems.get(i).Id));
        }
        insert pliItems;
        return pliItems;
    }

}