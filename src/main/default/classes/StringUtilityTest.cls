@isTest
private class StringUtilityTest{
    
    static testmethod void ValidIdTest()
    { 
      Account office = AlpineTestHelper.CreateOffice(StringUtility.newGuid());
      System.assert(StringUtility.IsValidId(office.Id));           
    }  

    static testmethod void InvalidIdTest()
    {     
      String s = StringUtility.newGuid();      
      System.assert(!StringUtility.IsValidId(s));      

      s = null;      
      System.assert(!StringUtility.IsValidId(s));

      s = '';      
      System.assert(!StringUtility.IsValidId(s));  

      s = 'InvalidString';      
      System.assert(!StringUtility.IsValidId(s)); 

      s = '2014 Price Book'; //15 characters     
      System.assert(!StringUtility.IsValidId(s));

      s = '2014 Price Book123'; //18 characters
      System.assert(!StringUtility.IsValidId(s));
    } 

    static testmethod void newGuidTest(){
     
       String guid = StringUtility.newGuid();
       System.debug('new Guid: ' + guid);  
       System.assert(StringUtility.isValidGuid(guid));      
    }  

     static testmethod void newJobTrackingNumberTest(){
            
        string trackingNumber = StringUtility.GetTrackingNumber('J-');  
        System.assert(StringUtility.isValidTrackingNumber(StringUtility.EntityObjectType.Job, trackingNumber)); 
    }
    
    static testmethod void newTicketTrackingNumberTest(){
            
        string trackingNumber = StringUtility.GetTrackingNumber('T-');        
        System.assert(StringUtility.isValidTrackingNumber(StringUtility.EntityObjectType.Ticket, trackingNumber));
    }
    
    static testmethod void uniqueTest(){
        Set<string> items = new Set<string>();
        for(Integer i=0; i<1000; i++){
            string tn =  StringUtility.GetTrackingNumber('T-');
            if(!items.isEmpty())
            {
                system.assertEquals(items.contains(tn), false);          
            }
            items.add(tn);
        }        
    }  

    static testmethod void SetSyncIdTest()
    {
      Test.startTest();
      Ticket__c tkt = AlpineTestHelper.CreateTickets(1, true).get(0);       
      Ticket_Log__c tktLog = new Ticket_Log__c(Ticket__c = tkt.Id, Start_Time__c = System.now());
      List<Ticket_Log__c> items = new List<Ticket_Log__c>();
      items.add(tktLog);
      StringUtility.setSyncId(items, StringUtility.FXNamespace() + 'SyncID__c');
      Test.stopTest();
      System.assert(StringUtility.isValidGuid(items.get(0).SyncID__c), 'Sync ID should have a valid guid value, instead of [' + items.get(0).SyncID__c + ']');
    }    
    
    static testmethod void validateTrackingNumberTest(){
          
          System.assertEquals(StringUtility.isValidTrackingNumber(StringUtility.EntityObjectType.Job, 'J-A80-E99-1234'), true); 
          System.assertEquals(StringUtility.isValidTrackingNumber(StringUtility.EntityObjectType.Job, 'J-A80-E99-12345'), true); 
          System.assertEquals(StringUtility.isValidTrackingNumber(StringUtility.EntityObjectType.Job, 'J-A80-E99-123456'), false);           
          System.assertEquals(StringUtility.isValidTrackingNumber(StringUtility.EntityObjectType.Job, 'T-A80-E99-1234'), false); 
          
          
          System.assertEquals(StringUtility.isValidTrackingNumber(StringUtility.EntityObjectType.Ticket, 'T-995-47C-1234'), true); 
          System.assertEquals(StringUtility.isValidTrackingNumber(StringUtility.EntityObjectType.Ticket, 'T-995-47C-12345'), true); 
          System.assertEquals(StringUtility.isValidTrackingNumber(StringUtility.EntityObjectType.Ticket, 'T-995-47C-123456'), false);           
          System.assertEquals(StringUtility.isValidTrackingNumber(StringUtility.EntityObjectType.Ticket, 'J-995-47C-1234'), false); 
          
    }      
}