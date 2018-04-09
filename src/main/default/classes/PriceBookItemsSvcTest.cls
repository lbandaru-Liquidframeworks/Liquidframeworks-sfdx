@isTest
private class PriceBookItemsSvcTest{
   
    static testmethod void GetItems()
    {
        Test.startTest();
    
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
       
      // Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
      // insert catalogItem;
              
      // Price_Book_Item__c pli = new Price_Book_Item__c(Price_Book__c = job.Price_Book__c, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123, Default_Quantity__c=1096, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id);
      // insert pli;
   
        Ticket__c tkt = AlpineTestHelper.CreateTickets(job,1,true).get(0);   

        
        RecordType statusRecordType = AlpineTestHelper.GetRecordType('Status__c');  

        String statusName = 'Status12123';
        Status__c st = new Status__c(Name = statusName, SObject__c='Ticket__c', Sync__c=false, Initial_Status_Console__c =false,  RecordTypeId=statusRecordType.Id);
        insert st;
        
        tkt.Status__c = st.Id;
        update tkt;
        
        Id priceBookId = job.Price_Book__c;
        List<Price_Book_Item__c> pbItems = AlpineTestHelper.CreatePriceBookItems(10, priceBookId , 'Equipment', true);   
       
        
        
        String ns = UtilityGetNamespace.CurrentNamespace();
        
        String criteria = ns + 'Status__r.Name =\'' + statusName  + '\'';
        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"[op]\\",\\"left\\":{\\"type\\":\\"[expType]\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"[value]\\"}}"]';

        criteriaStack = criteriaStack.replace('[expType]', 'MemberExpression').replace('[op]', '==')
            .replace('[fieldName]', ns + 'Status__r.Name').replace('[value]', statusName);

        
        Price_Book_Rule__c rule = new Price_Book_Rule__c(Price_Book__c = priceBookId, IsActive__c=true, 
            Criteria__c=criteria, CriteriaStack__c=criteriaStack);
        insert rule;
        
        Price_Book_Rule_Action__c action1 = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = pbItems.get(0).Id, IsActive__c = true, Type__c='Disallowed');
        insert action1;
        Price_Book_Rule_Action__c action2 = new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = pbItems.get(1).Id, IsActive__c = true, Type__c='Disallowed');
        insert action2;
        Price_Book_Rule_Action__c action3= new Price_Book_Rule_Action__c(Price_Book_Rule__c = rule.Id, Price_Book_Item__c = pbItems.get(2).Id, IsActive__c = true, Type__c='Disallowed');
        insert action3;        


        Ticket__c t = [SELECT Id, Status__c, Status__r.Name FROM Ticket__c WHERE Id=:tkt.Id];
        System.debug('***************** ' + t.Status__c + ', Status Name: ' + t.Status__r.Name);

        // set up the request object
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
            
        req.requestURI = '/getPricebookItems';
        req.httpMethod = 'GET';

        req.addParameter('jobId', job.Id);
        req.addParameter('ticketId', tkt.Id);
        req.addParameter('limit', '');
        req.addParameter('offset', '');
        req.addParameter('sortby', '');
        req.addParameter('sortdir', '');
        req.addParameter('fields', 'Id');
        
        RestContext.request = req;
        RestContext.response = res;
        
        PricebookItemsSvc.Result result = PricebookItemsSvc.getPricebookItems();
        
        System.assert(result.items.size() ==7, 'should have 7 items, instead of ' + result.items.size());

    }
}