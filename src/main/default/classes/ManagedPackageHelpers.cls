global with sharing class ManagedPackageHelpers
{
    public static string CleanTypeName(string typeName)
    {
	    Map<string, Schema.SObjectType> mapItems = Schema.getGlobalDescribe();
        Set<string> objectmap = mapItems.keySet();
        string ns = UtilityGetNamespace.CurrentNamespace();
		if(ns==null) ns='';		
		string key = (ns + typeName).toLowerCase();		
        if (objectmap.contains(key)) return mapItems.get(key).getDescribe().getName();      
        return null;
    }
    
    public static string CleanFieldName(string typeName, string fieldName)
    {
        typeName = CleanTypeName(typeName);
        if (typeName == null) return null;
		typeName = typeName.toLowerCase();
		Map<String, SObjectField> mapFields = Schema.getGlobalDescribe().get(typeName).getDescribe().fields.getMap();
        Set<string> keys = mapFields.keySet();
		string key = fieldName.toLowerCase();		
        if (!keys.contains(key)) return null;   		
        return mapFields.get(key).getDescribe().getName();
    }
    
    // comma separated field name. 
    public static string CleanFieldList(string typeName, string fieldName)
    {
        List<string> fieldNames = fieldName.Split(',');
        List<string> result = new List<string>();
        
        for (string field: fieldNames)
        {
            string f = CleanFieldName(typeName, field);
            if (f != null)
                result.add(f);
        }
        
        return string.Join(result, ',');
    }
    
    public static string CleanRelationship(string typeName, string relationshipName)
    {       
        typeName = CleanTypeName(typeName);
        if (typeName == null) return null;
		string ns = UtilityGetNamespace.CurrentNamespace();
		if(ns==null) ns='';		
        for (ChildRelationship r: Schema.getGlobalDescribe().get(typeName.toLowerCase()).getDescribe().getChildRelationships())
        {
            string rName = r.getRelationshipName();
			if(rName==null) continue;
            if (rName.toLowerCase() == relationshipName.toLowerCase()) return rName;
            if (rName.toLowerCase() == (ns + relationshipName).toLowerCase()) return rName;
        }
        return null;
    }   
}