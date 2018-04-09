@isTest
private class MixPanelTracking_Test
{
   static testMethod void JobCreated_Tracking() 
   { 
       Test.startTest();
       switchMixPanelTracking(true);
       List<Job__c> jobs = AlpineTestHelper.CreateJobs(100, true);
       MixPanelTracking.UnitTestCodeCoverage();
       Test.stopTest();
   } 
  
   static testMethod void TicketCreated_Tracking() 
   { 
       Test.startTest();
       switchMixPanelTracking(true);
       List<Ticket__c> tkts = AlpineTestHelper.CreateTickets(100, true);
       MixPanelTracking.UnitTestCodeCoverage();
       Test.stopTest();
   } 
   
   static testMethod void PriceBookItemCreated_Tracking() 
   { 
       Test.startTest();
       switchMixPanelTracking(true);
       Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');
       AlpineTestHelper.CreatePriceBookItems(109, pb.Id, 'UnitTestItemType');       
       Test.stopTest();
   } 
   
   static testMethod void InvoiceModule_Tracking() 
   { 
      Test.startTest();
      switchMixPanelTracking(true);

      Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);

      Payment__c p = new Payment__c();
      insert p;


      Account acc = AlpineTestHelper.CreateAccount(StringUtility.newGuid());

      RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');
      string newGuid = StringUtility.newGuid();

      String statusName = 'CMInitialStatus ' + newGuid;
      Status__c st = new Status__c(Name = statusName, SObject__c='Credit_Memo__c', Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);

      insert st;

      Credit_Memo__c cm = new Credit_Memo__c(CustomerAccount__c = acc.Id, Status__c = st.Id);
      insert cm;

      statusName = 'InvInitialStatus ' + newGuid;
      Status__c invStatus = new Status__c(Name = statusName, SObject__c='Invoice__c', Sync__c=true, Initial_Status_Console__c =true,  RecordTypeId=statusRecordType.Id);

      Invoice__c inv = new Invoice__c(CustomerAccount__c = j.CustomerAccount__c , 
        Price_Book__c = j.Price_Book__c, 
        Status__c = invStatus.Id );
      insert inv;

      insert new Invoice_Item__c(Invoice__c=inv.Id); 

      Credit_Memo_Applied__c cma = new Credit_Memo_Applied__c(Credit_Memo__c = cm.Id, Invoice__c = inv.Id);
      insert cma;

      Payment_Applied__c pa = new Payment_Applied__c(Payment__c = p.Id, Invoice__c = inv.Id);
      insert pa;
      Test.stopTest();
   } 
   
   static void switchMixPanelTracking(Boolean trueToStop)
   {
       FX_Settings__c fxSetting = FX_Settings__c.getInstance(UserInfo.getUserId());       
       if(fxSetting == null)
       {
           fxSetting = new FX_Settings__c();
           fxSetting.SetupOwnerId = UserInfo.getOrganizationId();
           
       }  
       if(String.isBlank(fxSetting.MixPanelSecurityToken__c))
       {
           fxSetting.MixPanelSecurityToken__c = '2dfda2ed5f89cad8424eebb79887e2a5';
           // prod use 'dfe456579c77b0bd5fec94f106e0e094';
       }
       fxSetting.MixPanelStopTracking__c= trueToStop;
       upsert fxSetting;  
   }
   
}
