@isTest
private class AttachmentExt_Test
{
    static testmethod void runThrough()
    {
        Test.startTest();
        Job__c job = AlpineTestHelper.CreateJobs(1, true).get(0);       
        PageReference page = new PageReference('JobAttachmentExt');
        page.getParameters().put('retURL', '/' + job.Id);
        page.getParameters().put('id', job.Id);
        Test.setCurrentPage(page);      
        
        Attachment a = new Attachment(ParentId=job.Id, Name = 'TestEntry.txt', Body=Blob.valueOf('Test Data'));
        insert a;
        
        Note n = new Note(ParentId=job.Id, Title = 'Note test entry');
        insert n;
          
        Attachment_Ext__c ext = new Attachment_Ext__c(AttachmentId__c = n.Id, ParentId__c = job.Id);
        insert ext;
         
          
      
        FeedItem f = new FeedItem(ParentId=job.Id, Body='Chatter Feed Test Item', ContentFileName='Test.txt',
         ContentData=Blob.valueOf('Test Data'));
         insert f;
        AttachmentExtController  ctrl = new AttachmentExtController();  
         
     
        ctrl.NewFeedItem.ContentData = Blob.valueOf('Test Data');
        ctrl.NewFeedItem.ContentFileName = 'Test.txt';
        ctrl.SaveAndNewChatterFeed();
        
        ctrl.NewFeedItem.ContentData = Blob.valueOf('Test Data');
        ctrl.NewFeedItem.ContentFileName = 'Test.txt';
         ctrl.SaveChatterFeed();
        
         ctrl.SaveAttachmentExt();
        
        page.getParameters().put('coreid', ext.AttachmentId__c);
        page.getParameters().put('extid', ext.Id);
        
        ctrl.DeleteAttachment();
        
       
        
        
          
        Test.stopTest();
    }
}