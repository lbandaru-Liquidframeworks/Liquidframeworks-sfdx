@isTest
private class FeedItemHandler_Test
{
    static testmethod void GetFeedItems_Test()
    {
        Test.startTest();
        Account acct = AlpineTestHelper.CreateOffice('Test Office ' + StringUtility.newGuid());
        
        FeedItem f = new FeedItem(ParentId=acct.Id, Body='Chatter Feed Test Item', ContentFileName='Test.txt',
        ContentData=Blob.valueOf('Test Data'));
        insert f;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='alpineTester987@liquidframeworks.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='alpineTester987@liquidframeworks.com');
        
        List<FeedItem> feedItems = null;
        List<FeedItem> feedItems2 = null;
        System.runAs(u){
             feedItems = FeedItemHandler.getFeedItemsByParent(acct.Id, 'ContentPost');
             feedItems2 = FeedItemHandler.getFeedItemsByParent(acct.Id, null);
        }  
        Test.stopTest();
        
        System.assert(feedItems!=null && feedItems.size()==1, 'should return one item');
        System.assert(feedItems2!=null && feedItems2.size()==1, 'should return one item');
    }
}