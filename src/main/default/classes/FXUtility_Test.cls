@isTest
private class FXUtility_Test
{
    static testmethod void GetAvailableRecordTypes_Test()
    {
        Set<Id> recordTypeIds = FXUtility.GetAvailableRecordTypeIdsForSObject(Job__c.sObjectType);
        List<RecordTypeInfo> recordTypes = FXUtility.GetAvailableRecordTypeInfosForSObject(Job__c.sObjectType);
        
    }
}