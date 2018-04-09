public without sharing class FeedItemHandler
{
    public static List<FeedItem> getFeedItemsByParent(Id parentId, String feedItemType)
    {
        return String.isBlank(feedItemType)? [SELECT Id, Title, ParentId, LastModifiedDate, CreatedById, CreatedBy.Name, RelatedRecordId FROM FeedItem WHERE ParentId=:parentId AND IsDeleted=false LIMIT 1000]:
        [SELECT Id, Title, ParentId, LastModifiedDate, CreatedById, CreatedBy.Name, RelatedRecordId FROM FeedItem WHERE ParentId=:parentId AND Type=:feedItemType AND IsDeleted=false LIMIT 1000];
    }
}