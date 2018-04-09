@isTest
private class ParentPricebookUtilities_Test{

    static testmethod void GetParentPricebooks() {
        Test.startTest();

        Price_Book__c pb1 = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'EUR');
        Price_Book__c pb2 = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'EUR');

        pb2.Parent_Price_Book__c = pb1.Id;
        update pb2;

        List<Price_Book__c> parents = ParentPricebookUtilities.GetParentPricebooks(pb2.Id);

        System.assertEquals(1, parents.Size());

        Test.stopTest();
    }


    static testmethod void GetParentPricebooks_ArchivedParent() {
        Test.startTest();

        Price_Book__c pb1 = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'EUR');
        Price_Book__c pb2 = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'EUR');

        List<Price_Book__c> pbs = [SELECT Id, Parent_Price_Book__c, IsArchived__c FROM Price_Book__c];
        Map<Id, Price_Book__c> pbMap = new Map<Id, Price_Book__c>(pbs);

        pbMap.get(pb1.Id).IsArchived__c = true;
        pbMap.get(pb2.Id).Parent_Price_Book__c = pb1.Id;
       
        update pbs;

        List<Price_Book__c> parents = ParentPricebookUtilities.GetParentPricebooks(pb2.Id);

        System.assertEquals(0, parents.Size());

        Test.stopTest();
    }

    static testmethod void GetPricebookItems() {
        Test.startTest();

        Price_Book__c pb1 = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'EUR');
        Price_Book__c pb2 = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'EUR');

        pb2.Parent_Price_Book__c = pb1.Id;
        update pb2;

        AlpineTestHelper.CreatePriceBookItems(3, pb1.Id, 'Supplies', true);
        AlpineTestHelper.CreatePriceBookItems(3, pb2.Id, 'Supplies', true);

        List<Ticket__c> tkts = AlpineTestHelper.CreateTickets(1, true);

        String ticketId = tkts[0].Id;
        ParentPricebookUtilities.Result res = ParentPricebookUtilities.GetPriceBookItems(pb1.Id, ticketId, 'false', 'not found', '', 'supplies2', '2000', '0', 'Name', 'ASC', 'Name');

        System.assertNotEquals(null, res.items);

        Test.stopTest();
    }

    static testmethod void GetPricebookItemsFromParentPricebook() {
        Test.startTest();

        Price_Book__c pb1 = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'EUR');
        Price_Book__c pb2 = AlpineTestHelper.CreatePriceBook(true, Date.today(), 'EUR');

        pb2.Parent_Price_Book__c = pb1.Id;
        update pb2;

        AlpineTestHelper.CreatePriceBookItems(3, pb1.Id, 'Supplies', true);
        AlpineTestHelper.CreatePriceBookItems(3, pb2.Id, 'Supplies', true);

        List<Ticket__c> tkts = AlpineTestHelper.CreateTickets(1, true);

        String ticketId = tkts[0].Id;
        ParentPricebookUtilities.Result res = ParentPricebookUtilities.GetPricebookItemsFromParentPricebook(pb2.Id, ticketId, 'false', 'not found', '', 'supplies4', '2000', '0', 'Name', 'ASC', 'Name');

        System.assertNotEquals(null, res.items);

        Test.stopTest();
    }

}
