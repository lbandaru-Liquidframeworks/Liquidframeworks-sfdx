@isTest
private class TicketItemHandler_Test
{

    @testSetup
    static void setup()
    {
        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        Ticket__c tkt = AlpineTestHelper.CreateTickets(j, 1, true).get(0);

        List<Price_Book_Item__c> pbiEquip = AlpineTestHelper.CreatePriceBookItems(5, j.Price_Book__c, 'Equipment', true);
        List<Price_Book_Item__c> pbiLabor = AlpineTestHelper.CreatePriceBookItems(5, j.Price_Book__c, 'Labor', true);

        List<Price_Book_Item__c> pbiEquipForQuoteItem = AlpineTestHelper.CreatePriceBookItems(5, j.Price_Book__c, 'Equipment', true);

        List<Equipment__c> equip = new List<Equipment__c>();
        List<Contact> contacts = new List<Contact>();
        for(Integer i=0; i<5; i++)
        {
            equip.add(AlpineTestHelper.CreateEquipment(false));
            contacts.add(AlpineTestHelper.CreateContactWithNoUser('LAST Name ' + i, 'First Name ' + i, false));
        }
        insert equip;
        insert contacts;

        List<Crew_Planning__c> cps = new List<Crew_Planning__c>();
        List<Equipment_Planning__c> eps = new List<Equipment_Planning__c>();

        for(Integer i=0; i<5; i++)
        {
            cps.add(new Crew_Planning__c(Job__c = j.Id, Role_on_Job__c = pbiLabor.get(i).Id, Crew_Member__c = contacts.get(i).Id));
            eps.add(new Equipment_Planning__c(Job__c = j.Id, Price_Book_Item__c = pbiEquip.get(i).Id, Equipment2__c=equip.get(i).Id));

        }
        insert cps;
        insert eps;


        Quote__c q = AlpineTestHelper.CreateQuotes(1, false).get(0);
        q.Price_Book__c = j.Price_Book__c;
        insert q;

        Job__c dbJob = [SELECT id FROM Job__c WHERE Id =:j.Id];
        dbJob.Quote2__c = q.Id;
        update dbJob;

        List<Quote_Item__c> quoteItems = new List<Quote_Item__c>();

        for(Price_Book_Item__c pbi : pbiEquipForQuoteItem)
        {
            Quote_Item__c qi = (Quote_Item__c)Quote_Item__c.sObjectType.newSobject(null, true);
            qi.Quote__c = q.Id;
            qi.Price_Book_Item__c = pbi.Id;
            quoteItems.add(qi);
        }
        insert quoteItems;
    }

    static testmethod void createTktItemsWithCrewPlanning_Test()
    {
        Test.startTest();
        List<Crew_Planning__c> cps = [SELECT Id FROM Crew_Planning__c];

        System.assert(cps!=null && cps.size() == 5, 'should have 5 Crew_Planning__c items');
        List<Id> sourceIds = new List<Id>(new Map<Id, Crew_Planning__c>(cps).keySet());

        Ticket__c tkt = [SELECT Id FROM Ticket__c LIMIT 1];

        List<Ticket_Item__c> tktItems = TicketItemHandler.CreateTicketItems(tkt.Id, sourceIds, (Decimal)null);
        Test.stopTest();

        System.assert(tktItems!=null && tktItems.size() == cps.size(), 'should have 5 items');
        for(Ticket_Item__c ti : tktItems)
        {
            System.assert(!String.isBlank(ti.Contact__c), 'Crew Planning related Ticket Item should have value for Contact__c');
        }
    }


    static testmethod void createTktItemsWithEquipmentPlanning_Test()
    {
        Test.startTest();
        List<Equipment_Planning__c> sources  = [SELECT Id FROM Equipment_Planning__c];

        System.assert(sources!=null && sources.size() == 5, 'should have 5 Equipment_Planning__c items');
        List<Id> sourceIds = new List<Id>(new Map<Id, Equipment_Planning__c>(sources).keySet());

        Ticket__c tkt = [SELECT Id FROM Ticket__c LIMIT 1];

        List<Ticket_Item__c> tktItems = TicketItemHandler.CreateTicketItems(tkt.Id, sourceIds, (Decimal)null);
        Test.stopTest();

        System.assert(tktItems!=null && tktItems.size() == sources.size(), 'should have 5 items');
        for(Ticket_Item__c ti : tktItems)
        {
            System.assert(!String.isBlank(ti.Equipment__c), 'Equipment Planning related Ticket Item should have value for Equipment__c');
        }
    }

    static testmethod void createTktItemsWithPriceBookItem_Test()
    {
        Test.startTest();
        List<Price_Book_Item__c> sources  = [SELECT Id FROM Price_Book_Item__c];

        System.assert(sources!=null && sources.size() == 15, 'should have 15 Price_Book_Item__c items');
        List<Id> sourceIds = new List<Id>(new Map<Id, Price_Book_Item__c>(sources).keySet());

        Ticket__c tkt = [SELECT Id FROM Ticket__c LIMIT 1];

        List<Ticket_Item__c> tktItems = TicketItemHandler.CreateTicketItems(tkt.Id, sourceIds, (Decimal)null);
        Test.stopTest();

        System.assert(tktItems!=null && tktItems.size() == sources.size(), 'should have 15 items');

    }

    static testmethod void createTktItemsWithQuoteItem_Test()
    {
        Test.startTest();
        List<Quote_Item__c> sources  = [SELECT Id FROM Quote_Item__c];

        System.assert(sources!=null && sources.size() == 5, 'should have 5 Price_Book_Item__c items');
        List<Id> sourceIds = new List<Id>(new Map<Id, Quote_Item__c>(sources).keySet());

        Ticket__c tkt = [SELECT Id FROM Ticket__c LIMIT 1];

        Decimal nextSeqNumber = 200;
        List<Ticket_Item__c> tktItems = TicketItemHandler.CreateTicketItems(tkt.Id, sourceIds, nextSeqNumber, null);
        Test.stopTest();

        Integer count = tktItems!=null? tktItems.size() : 0;

        System.assert(count == sources.size(), 'should have 5 items, instead having ' + count);

        //check sequence numbers
        Map<Id, Decimal> expectedResults = new Map<Id, Decimal>();
        for(Integer i=0; i<sourceIds.size(); i++)
        {
            expectedResults.put(sourceIds.get(i), nextSeqNumber + i);
        }
        for(Ticket_Item__c ti: tktItems)
        {
            System.assert(ti.Sequence_Number__c == expectedResults.get(ti.Quote_Item__c), 'Sequence_Number__c should be sequential starting with the provided nextSeqNumber');
        }
    }
}
