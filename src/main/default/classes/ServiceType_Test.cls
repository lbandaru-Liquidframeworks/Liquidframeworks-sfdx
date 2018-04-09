@isTest
private class ServiceType_Test
{
    static testmethod void runTest()
    {
        Test.startTest();
        Service_Type__c st = new Service_Type__c();
        insert st;
        
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);
        Price_Book_Item__c pi= AlpineTestHelper.CreatePriceBookItems(1, job.Price_Book__c, 'Equipment').get(0);
        
        Price_Book_Item_Service_Type__c pst = new Price_Book_Item_Service_Type__c();
        pst.Service_Type__c = st.Id;
        pst.Price_Book_Item__c = pi.Id;
        insert pst;
        Test.stopTest();
    }
}