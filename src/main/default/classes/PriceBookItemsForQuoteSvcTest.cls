@isTest
private class PriceBookItemsForQuoteSvcTest{
   
    static testmethod void GetItems()
    {
        Test.startTest();
   
        Price_Book__c pb = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'USD');

        Quote__c quote = AlpineTestHelper.CreateQuotes(pb, 1, true).get(0);
        Id priceBookId = quote.Price_Book__c;

        AlpineTestHelper.CreatePriceBookItems(5, priceBookId , 'Equipment', true);
        List<Price_Book_Item__c> dbItems = [SELECT Id, Price_Book__c,  Parent_Price_Book_Item__c FROM Price_Book_Item__c WHERE Price_Book__c =:priceBookId];

        Price_Book_Item__c p= dbItems.get(0);
        dbItems.get(1).Parent_Price_Book_Item__c = p.Id;
        dbItems.get(2).Parent_Price_Book_Item__c = p.Id;        
        update dbItems;

        Quote_Item__c qi = new Quote_Item__c();
        qi.Quote__c = quote.Id;
        qi.Price_Book_Item__c = p.Id;
        insert qi;

        // set up the request object
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
            
        req.requestURI = '/getPricebookItemsForQuote';
        req.httpMethod = 'GET';

        req.addParameter('quoteId', quote.Id);
        req.addParameter('limit', '');
        req.addParameter('offset', '');
        req.addParameter('sortby', '');
        req.addParameter('sortdir', '');
        req.addParameter('fields', 'Id');
        
        RestContext.request = req;
        RestContext.response = res;
        
        PricebookItemsForQuoteSvc.Result result = PricebookItemsForQuoteSvc.getPricebookItemsForQuote();
        System.debug('RESULT'+ string.valueof(result.items.size()));
        System.assert(result.items.size() ==3);

        Test.stopTest();
    }
}