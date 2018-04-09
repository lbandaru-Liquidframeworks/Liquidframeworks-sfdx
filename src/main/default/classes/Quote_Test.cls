@isTest
private class Quote_Test
{
    static testmethod void QuoteTrigger_Test()
    {
        Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        
        List<Quote__c> quotes = new List<Quote__c>();
        for(Integer i=0; i<200; i++)
        {
            Quote__c q = (Quote__c)Quote__c.sObjectType.newSObject();
            q.Price_Book__c = j.Price_Book__c;
            quotes.add(q);
        }
        insert quotes;
    }
}