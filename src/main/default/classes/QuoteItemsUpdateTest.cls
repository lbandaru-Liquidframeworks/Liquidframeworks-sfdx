@isTest
private class QuoteItemsUpdateTest{


    static testmethod void testUpdate(){
        Test.startTest();
        List<Quote__c> qlist= AlpineTestHelper.CreateQuotes(1, true);
        Quote__c q = qlist[0];

        Catalog_Item__c catalogItem = new Catalog_Item__c(Name= '12000', Description__c = 'Test Catalog Item', UOM__c='Gal', Sequence_Number__c=210,  Ticket_Item_Record_Type__c = 'Equipment');
        insert catalogItem;

        Price_Book_Item__c pli = new Price_Book_Item__c(Price_Book__c = q.Price_Book__c, Price__c=125, Sequence_Number__c =1, Discount_Percent__c=0.123,
                Default_Quantity__c=6, Included_Quantity__c=0, Catalog_Item__c=catalogItem.Id,
                Maximum_Quantity__c=10);
        insert pli;

        Quote_Item__c qtItem  = new Quote_Item__c(Quote__c = q.Id, Price_Book_Item__c = pli.Id);
        insert qtItem;

        String ns = StringUtility.FXNamespace();

        string objStr = '{"' + ns + 'Qty__c":"2.00","id":"'+qtItem.Id+'"}';
        string typeStr = ns + 'Quote_Item__c';
        string qtFields = 'Name';
        string qtItemFields = String.format('{0}Discount_Percent__c,{0}Qty__c', new String[]{ns});

        QuoteItemsUpdate.UpdateQtItemResult res = QuoteItemsUpdate.QuoteItemUpdate(objStr, typeStr, qtFields, qtItemFields);

        system.assert(res.success, 'ALL GOOD');

        objStr = '{"' + ns + 'Qty__c":"100","id":"'+qtItem.Id+'"}';

        res = QuoteItemsUpdate.QuoteItemUpdate(objStr, typeStr, qtFields, qtItemFields);
    }


}
