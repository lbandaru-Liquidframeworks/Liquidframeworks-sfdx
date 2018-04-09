@isTest
private class TicketItemManglerTest{

    
    static testmethod void setupTicketItem(){
        
        Test.startTest();
      Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
       
       Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
       insert catalogItem;
              
       Price_Book_Item__c pli = new Price_Book_Item__c(Price_Book__c = job.Price_Book__c, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
       insert pli;
       
        
      Ticket__c t= new Ticket__c(Job__c = job.Id);
      insert t;
       
      Ticket_Item__c tktItem  = new Ticket_Item__c(Ticket__c = t.Id, Price_Book_Item__c = pli.Id);
       
       insert tktItem;    
       Test.stopTest();

       Price_Book_Item__c dbPli = [SELECT Id, Default_Quantity__c FROM Price_Book_Item__c WHERE Id=:pli.Id];
       System.debug('dbPli=' + dbPli);

       Ticket_Item__c dbItem  = [SELECT Id, Price_Book_Item__c, PBI_Default_Quantity__c, SyncID__c FROM Ticket_Item__c WHERE Ticket__c= :t.Id AND Price_Book_Item__c =:pli.Id LIMIT 1];  
       System.debug('tktItem=' + dbItem);
       
       System.debug('Tkt Item SyncID__c *************************************************  AFTER insert ' + dbItem.SyncID__c);
       system.assert(StringUtility.isValidGuid(dbitem.SyncID__c)); 
       system.assertEquals(1096, dbItem.PBI_Default_Quantity__c); 
      
    }

    static testmethod void AddChild_Test()
    {
        Test.StartTest();        
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c ticket = AlpineTestHelper.CreateTickets(job, 1, true).get(0);
        Id priceBookId = job.Price_Book__c;

        AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);
        List<Price_Book_Item__c> dbItems = [SELECT Id, Price_Book__c,  Parent_Price_Book_Item__c FROM Price_Book_Item__c WHERE Price_Book__c =:priceBookId];

        Price_Book_Item__c p= dbItems.get(0);
        dbItems.get(1).Parent_Price_Book_Item__c = p.Id;
        dbItems.get(2).Parent_Price_Book_Item__c = p.Id;        
        update dbItems;

        Ticket_Item__c ti = new Ticket_Item__c();
        ti.Ticket__c = ticket.Id;
        ti.Price_Book_Item__c = p.Id;
        insert ti;
        Test.stopTest();

        List<Ticket_Item__c> tktItems = [SELECT Id, Auto_Added__c FROM Ticket_Item__c WHERE Ticket__c=:ticket.Id AND Auto_Added__c=false];
        System.assert(tktItems.size()==3, 'Ticket should have 3 items - 1 parent with two child items');

    }


    static testmethod void DeletePbRequiredItem_NoGo_Test()
    {
      Test.startTest();
      Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
       
      Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
      insert catalogItem;
              
      Price_Book_Item__c pli = new Price_Book_Item__c(Price_Book__c = job.Price_Book__c, Price__c=125, Required_Item__c=true,
         Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
      insert pli;
       
        
      Ticket__c t= new Ticket__c(Job__c = job.Id);
      insert t;

      //Ticket_Item__c ti = new Ticket_Item__c(Ticket__c = t.Id, Price_Book_Item__c = pli.Id, Auto_Added__c =true);
      //insert ti;

      Test.stopTest();

      List<Ticket_Item__c> tktItems = [SELECT Id, PBI_Required_Item__c, Price_Book_Item__r.Required_Item__c FROM Ticket_Item__c WHERE Ticket__c=:t.Id AND Price_Book_Item__c = :pli.Id];
      System.assert(tktItems.size()==1);
      System.assert(tktItems.get(0).PBI_Required_Item__c);
      System.assert(tktItems.get(0).Price_Book_Item__r.Required_Item__c);

      String errorMsg = '';
      try
      {
          delete tktItems;
      }
      catch(System.DMLException e) 
      {
          for (Integer i = 0; i < e.getNumDml(); i++)
          {
             errorMsg += e.getDmlMessage(i);
          }    
      }
      System.assert(errorMsg.contains('Cannot delete a required ticket item'));   
       
    }

    static testmethod void DeletePbRequiredItem_Go_Test()
    {
      Test.startTest();
      Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
       
      Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
      insert catalogItem;
              
      Price_Book_Item__c pli = new Price_Book_Item__c(Price_Book__c = job.Price_Book__c, Price__c=125, Required_Item__c=true,
         Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
      insert pli;
       
        
      Ticket__c t= new Ticket__c(Job__c = job.Id);
      insert t;

      //Ticket_Item__c ti = new Ticket_Item__c(Ticket__c = t.Id, Price_Book_Item__c = pli.Id, Auto_Added__c =true);
      //insert ti;

      pli.Required_Item__c = false;
      update pli;
      Test.stopTest();

      List<Ticket_Item__c> tktItems = [SELECT Id, PBI_Required_Item__c, Price_Book_Item__r.Required_Item__c FROM Ticket_Item__c WHERE Ticket__c=:t.Id AND Price_Book_Item__c = :pli.Id];
      System.assertEquals(1, tktItems.size());
      System.assertEquals(true, tktItems.get(0).PBI_Required_Item__c);
      System.assertEquals(false, tktItems.get(0).Price_Book_Item__r.Required_Item__c);

      String errorMsg = '';
      try
      {
          delete tktItems;
      }
      catch(System.DMLException e) 
      {
          for (Integer i = 0; i < e.getNumDml(); i++)
          {
             errorMsg += e.getDmlMessage(i);
          }    
      }
      System.assertEquals('', errorMsg);  
       
    }
    
    static testmethod void TicketItemDiscountedPriceStandbyPrice(){
      
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
      
       Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210, Ticket_Item_Record_Type__c = 'Equipment');
       insert catalogItem;
       
       
       Price_Book_Item__c pli = new Price_Book_Item__c(Price_Book__c = job.Price_Book__c, Price__c=100, Sequence_Number__c =1, Discount_Percent__c=10, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
       insert pli;
       


        Ticket__c t= new Ticket__c(Job__c = job.Id);
        insert t;
      
       Ticket_Item__c tktItem1  = new Ticket_Item__c(Ticket__c = t.Id, Price_Book_Item__c = pli.Id);
       insert tktItem1;    
       //Ticket_Item__c dbItem1  = [SELECT Discounted_Price__c FROM Ticket_Item__c WHERE Id= :tktItem1.Id LIMIT 1];  

       //system.assertEquals(dbItem1.Discounted_Price__c , pli.Price__c * (1 - pli.Discount_Percent__c/100.0)); 

       Price_Book_Item__c pli2 = new Price_Book_Item__c(Price_Book__c = job.Price_Book__c, Price__c=200, Sequence_Number__c =1, Discount_Percent__c=10, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
       pli2.Standby_Price__c = 99;
       insert pli2;

       Ticket_Item__c tktItem2  = new Ticket_Item__c(Ticket__c = t.Id, Price_Book_Item__c = pli2.Id, On_Standby__c=true);
       insert tktItem2;    
       //Ticket_Item__c dbItem2  = [SELECT Standby_Price__c FROM Ticket_Item__c WHERE Id =:tktItem2.Id LIMIT 1];  

       //System.assertEquals(dbItem2.Standby_Price__c , pli2.Standby_Price__c); 
       
    }   
     static testmethod void TicketItemDiscountedPriceStraightPrice(){
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
       

       Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210, Ticket_Item_Record_Type__c = 'Equipment');
       insert catalogItem;
      

       Price_Book_Item__c pli = new Price_Book_Item__c(Price_Book__c = job.Price_Book__c, Sequence_Number__c =1, Price__c=100, Discount_Percent__c=10, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
       pli.Pricing_Method__c = 'Straight Price'; 
       insert pli;
        Price_Book_Item__c pbi = [SELECT Id, Pricing_Method__c, Price__c FROM Price_Book_Item__c WHERE Price_Book__c=:job.Price_Book__c LIMIT 1];       
        Ticket__c t= new Ticket__c(Job__c = job.Id);
        insert t;
        Ticket__c tkt =  [SELECT Id, Tracking_Number__c FROM Ticket__c WHERE Job__c= :job.Id LIMIT 1];  
        string rowID2 = StringUtility.newGuid();
        Ticket_Item__c tktItem2  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pbi.Id, Description__c = rowID2);
        tktItem2.Price__c=100;
        insert tktItem2;    
        Ticket_Item__c dbItem = [SELECT Id, PBI_Pricing_Method__c, Price__c, Discount_Percent__c FROM Ticket_Item__c WHERE Ticket__c= :tkt.Id  AND Description__c=:rowID2 LIMIT 1];

        // Test Update
        dbItem.Price__c = 200;
        update dbItem;
        Ticket_Item__c dbItem2 = [SELECT Id, PBI_Pricing_Method__c, Price__c, Discount_Percent__c FROM Ticket_Item__c WHERE Ticket__c= :tkt.Id  AND Description__c=:rowID2 LIMIT 1];
        //system.assertEquals(dbItem2.Discounted_Price__c , 180);
    }
    static testmethod void TicketItemDiscountedPriceCostPlusMarkupPercent(){
         Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
 
       Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', Cost__c=100, UOM__c='Gal', Sequence_Number__c=210, Ticket_Item_Record_Type__c = 'Equipment');
       insert catalogItem;
    

       Price_Book_Item__c pli = new Price_Book_Item__c(Price_Book__c = job.Price_Book__c, Sequence_Number__c =1, Price__c=100, Discount_Percent__c=10, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
       pli.Pricing_Method__c = 'Cost Plus Markup Percent'; 
       pli.Cost_Plus_Markup_Percent__c = 20;
       pli.Discount_Percent__c=10;
       insert pli;
        Price_Book_Item__c pbi = [SELECT Id, Pricing_Method__c, Price__c FROM Price_Book_Item__c WHERE Price_Book__c=:job.Price_Book__c LIMIT 1];       
        Ticket__c t= new Ticket__c(Job__c = job.Id);
        insert t;
        Ticket__c tkt =  [SELECT Id, Tracking_Number__c FROM Ticket__c WHERE Job__c= :job.Id LIMIT 1];  
        string rowID2 = StringUtility.newGuid();
        Ticket_Item__c tktItem2  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pbi.Id, Description__c = rowID2);
        tktItem2.Price__c=100;
        tktItem2.Cost__c = 100;
        tktItem2.Cost_Plus_Markup_Percent__c = 20;
        tktItem2.Discount_Percent__c = 10;
        insert tktItem2;    
        Ticket_Item__c dbItem= [SELECT Id, On_Standby__c, PBI_Pricing_Method__c, Cost_Plus_Markup_Percent__c , Price__c, Discount_Percent__c FROM Ticket_Item__c WHERE Ticket__c= :tkt.Id  AND Description__c=:rowID2 LIMIT 1];
        System.debug('Tkt Item On_Standby__c*************************************************  AFTER insert ' + dbItem.On_Standby__c);
        System.debug('Tkt Item PBI_Pricing_Method__c*************************************************  AFTER insert ' + dbItem.PBI_Pricing_Method__c);
        System.debug('Tkt Item Cost_Plus_Markup_Percent__c *************************************************  AFTER insert ' + dbItem.Cost_Plus_Markup_Percent__c );
        System.debug('Tkt Item Price__c*************************************************  AFTER insert ' + dbItem.Price__c);
        System.debug('Tkt Item Discount_Percent__c*************************************************  AFTER insert ' + dbItem.Discount_Percent__c);
    }
    static testmethod void TicketItemDiscountedPriceCostPlusMarkupAmount(){
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
 
       
       Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', Cost__c=100, UOM__c='Gal', Sequence_Number__c=210, Ticket_Item_Record_Type__c = 'Equipment');
       insert catalogItem;
        
       Price_Book_Item__c pli = new Price_Book_Item__c(Price_Book__c = job.Price_Book__c, Sequence_Number__c =1, Price__c=100, Discount_Percent__c=10, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
       pli.Pricing_Method__c = 'Cost Plus Markup Amount'; 
       pli.Cost_Plus_Markup_Amount__c = 100;
       pli.Discount_Percent__c=10;
       insert pli;
        Price_Book_Item__c pbi = [SELECT Id, Pricing_Method__c, Price__c FROM Price_Book_Item__c WHERE Price_Book__c=:job.Price_Book__c LIMIT 1];       
        Ticket__c t= new Ticket__c(Job__c = job.Id);
        insert t;
        Ticket__c tkt =  [SELECT Id, Tracking_Number__c FROM Ticket__c WHERE Job__c= :job.Id LIMIT 1];  
        string rowID2 = StringUtility.newGuid();
        Ticket_Item__c tktItem2  = new Ticket_Item__c(Ticket__c = tkt.Id, Price_Book_Item__c = pbi.Id, Description__c = rowID2);
        tktItem2.Price__c=100;
        tktItem2.Cost__c =100;
        tktItem2.Cost_Plus_Markup_Amount__c = 100;
        tktItem2.Discount_Percent__c = 10;
        insert tktItem2;    
        Ticket_Item__c dbItem= [SELECT Id, On_Standby__c, Cost__c, PBI_Pricing_Method__c, Cost_Plus_Markup_Amount__c, Price__c, Discount_Percent__c FROM Ticket_Item__c WHERE Ticket__c= :tkt.Id  AND Description__c=:rowID2 LIMIT 1];
    }        
    
}