@isTest
private class PriceBookItemLookupController_Test {
   
    static testMethod void search_Test() 
    {

        Test.startTest();

        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Integer laborItemCount = 21;
        List<Price_Book_Item__c> pliItems = AlpineTestHelper.CreatePriceBookItems(laborItemCount, job.Price_Book__c, 'Labor') ;
        AlpineTestHelper.CreatePriceBookItems(50, job.Price_Book__c, 'Equipment') ;          
        Test.stopTest();        
      
        PriceBookItemLookupController controller = new PriceBookItemLookupController();           
        System.debug(' search_Test: pbID=' + job.Price_Book__c + ', ItemType=Labor');
        List<Price_Book_Item__c> results =controller.performSearch(job.Price_Book__c, 'Labor', '');

        System.assertEquals(laborItemCount, results.size());
        
    }  


    

    static testMethod void search_GetAll_Test() 
    {

        Test.startTest();

        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Integer laborItemCount = 21;
        Integer equipItemCount = 26;

        List<Price_Book_Item__c> pliItems = AlpineTestHelper.CreatePriceBookItems(laborItemCount, job.Price_Book__c, 'Labor') ;
        AlpineTestHelper.CreatePriceBookItems(equipItemCount, job.Price_Book__c, 'Equipment') ;   
        Test.stopTest();
     
  
        PriceBookItemLookupController controller = new PriceBookItemLookupController();           
        System.debug(' search_Test: pbID=' + job.Price_Book__c + ', ItemType=Labor');
        List<Price_Book_Item__c> results =controller.performSearch(job.Price_Book__c, 'Labor', '');      

        System.assertEquals(laborItemCount, results.size());
        
        results =controller.performSearch(job.Price_Book__c, 'Equipment', '');
        System.assertEquals(equipItemCount, results.size());
       
    }  

    static testMethod void searchKeywork_Test() 
    {

        Test.startTest();

        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Integer itemCount = 21;
        Integer equipItemCount = 26;

        List<Price_Book_Item__c> pliItems = AlpineTestHelper.CreatePriceBookItems(itemCount, job.Price_Book__c, 'Labor') ;
        Set<Id> catalogItemIDs = new Set<Id>();

        string keyword = 'Test12345 Item';

        for(Integer i=0; i<6; i++)
        {
            catalogItemIDs.add(pliItems.get(i).Catalog_Item__c);
        }
        List<Catalog_Item__c> cItems = [SELECT Name, Description__c FROM Catalog_Item__c WHERE Id IN :catalogItemIDs];
        Boolean alter= true;
        for(Catalog_Item__c ci: cItems)
        {
            if(alter)
            {
                ci.Name = keyword + StringUtility.newGuid();                
            }
            else
            {
                ci.Description__c = StringUtility.newGuid() + keyword + StringUtility.newGuid();     
            }
            alter = !alter;
        }
        update cItems;            
       
       
        Test.stopTest();


        PriceBookItemLookupController controller = new PriceBookItemLookupController();   
        
        List<Price_Book_Item__c> results =controller.performSearch(job.Price_Book__c, 'Labor', keyword);      
        System.assertEquals(cItems.size(), results.size());       

    }  

    static testMethod void uiElement_Test() 
    {

        Test.startTest();

        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Integer laborItemCount = 21;
        Integer equipItemCount = 26;

        List<Price_Book_Item__c> pliItems = AlpineTestHelper.CreatePriceBookItems(laborItemCount, job.Price_Book__c, 'Labor') ;
        AlpineTestHelper.CreatePriceBookItems(equipItemCount, job.Price_Book__c, 'Equipment') ;   
     

        PageReference page = new PageReference('PriceBookItemSearcher');
      
        Test.setCurrentPage(page);        
      
        PriceBookItemLookupController controller = new PriceBookItemLookupController();   
        controller.search();
        Test.stopTest();
        try
        {            
            controller.getFormTag();
            controller.getTextBox();
            System.assert(true);
        }
        catch(Exception ex)
        {
            System.assert(false);
        }       
    }  
}