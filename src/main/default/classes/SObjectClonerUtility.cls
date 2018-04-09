public class SObjectClonerUtility
{   
    public static Boolean CloningInProgress {get; set;}

    public static CloningTypeInfo ParseCloningTypes(String str)
    {
    	return new CloningTypeInfo(str);
    }

    public static void CopySelfReferencingItems(SObjectDescribeInfo sInfo, 
        List<sObject> items,
        Map<Id, Id> idMapping,
        Boolean alterName)
    {
        List<sObject> itemsToProcess = new List<sObject>(items);  
        Boolean hasMore = (items!=null && !items.isEmpty());

        String refField = sInfo.SelfReferenceFieldPath;       

        while(hasMore)
        {
            List<sObject> itemsForNext = new List<sObject>();
            List<Id> sourceIds = new List<Id>();
            List<sObject> newObjs = new List<sObject>();
            for(sObject o : itemsToProcess)
            {
                Id refId = (Id)o.get(refField);

                //Items with no parent or its parent item has been processed
                if(String.isBlank(refId) || idMapping.containsKey(refId))
                {
                    sourceIds.add(o.Id);
                    newObjs.add(sInfo.CreateSObject(o, idMapping, alterName));
                    if(alterName)
                    {
                        alterName=false;
                    }
                }
                else
                {
                    itemsForNext.add(o);
                }                
            }
            insert newObjs;  
            for(Integer i=0; i<newObjs.size(); i++)
            {
                idMapping.put(sourceIds.get(i), newObjs.get(i).Id);
            }
            itemsToProcess = itemsForNext;
            hasMore = !newObjs.isEmpty() && !itemsForNext.isEmpty();  
        }       
    }

    public class CloningTypeInfo
    {
    	private CloningTypeInfo(String p)
    	{
    		Types = new List<String>();
    		OptionalFilters = new Map<String, String>();

    		if(String.isBlank(p)) return;

	        for(String str : p.split(','))
	        {
	            if(String.isBlank(str) || String.isBlank(str.trim())) continue;
	            String typeInfo = str.trim(); 

	            Integer index = typeInfo.indexOf('{');
	            String type = index>0 ? typeInfo.subString(0, index) : typeInfo;

	            //user has no permission to create the object type, skip it
	            if(!Schema.getGlobalDescribe().get(type).getDescribe().isCreateable()) continue;

	            String filter = index>0? typeInfo.subString(index + 1, typeInfo.length() -1) : '';
	            Types.add(type);
	            if(!String.isBlank(filter))
	            {
	                OptionalFilters.put(type.toLowercase(), filter);
	            }
	        }	        
    	}
    	public List<String> Types {get; private set;}
    	public Map<String, String> OptionalFilters {get; private set;}
    }
}