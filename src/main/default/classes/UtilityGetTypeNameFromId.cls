public class UtilityGetTypeNameFromId
{
    public static string CurrentTypeName(Id controllerId) 
    { 
        String myIdPrefix = String.valueOf(controllerId).substring(0,3); //get just the prefix
        
        string stype = null;
        
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        
        for(Schema.SObjectType schematype : schemaMap.values())
        {
            Schema.DescribeSObjectResult r = schematype.getDescribe();
            String prefix = r.getKeyPrefix();
            if(prefix!=null && prefix.equals(myIdPrefix))
            {
                stype = r.getName();
                break;
            }
        }
            
        return stype;
    } 
}