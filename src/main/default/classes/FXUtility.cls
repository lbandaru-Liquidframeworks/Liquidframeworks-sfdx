public class FXUtility
{
    public static Set<Id> GetAvailableRecordTypeIdsForSObject(Schema.SObjectType objType)
    {
        Set<Id> results = new Set<Id>();
        List<RecordTypeInfo> infos = objType.getDescribe().getRecordTypeInfos();
        
        for (RecordTypeInfo i : infos) 
        {
               // Ignore the Master Record Type, whose Id always ends with 'AAA'.
               // We check the Id because Name can change depending on the user's language.
               
           if (i.isAvailable() && !i.isMaster())
           {
               results .add(i.getRecordTypeId());
           }
        }         
       
        return results;
    }
    
    public static List<RecordTypeInfo> GetAvailableRecordTypeInfosForSObject(Schema.SObjectType objType)
    {
        List<RecordTypeInfo> results = new List<RecordTypeInfo>();
        List<RecordTypeInfo> infos = objType.getDescribe().getRecordTypeInfos();
        
        for (RecordTypeInfo i : infos) 
        {
               // Ignore the Master Record Type, whose Id always ends with 'AAA'.
               // We check the Id because Name can change depending on the user's language.
               
           if (i.isAvailable() && !i.isMaster())
           {
               results .add(i);
           }
        }         
       
        return results;
    }
}