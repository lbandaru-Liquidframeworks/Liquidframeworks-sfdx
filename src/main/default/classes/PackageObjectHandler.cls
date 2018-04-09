public class PackageObjectHandler
{
    public static void EnforceBuiltInFieldsReadOnly(List<sObject> items, Map<Id, sObject> oldMap)
    {
        List<String> readOnlyFields = GetReadOnlyFields(items.get(0), new Set<String>());

        for(sObject o : items)
        {
            sObject old = oldMap.get(o.Id);
            for(String f : readOnlyFields)
            {
                if(o.get(f) != old.get(f))
                {
                    o.addError('All Built-in fields are not updateable.');
                    break;
                }
            }
        }
    }

    public static void EnforceBuiltInFieldsReadOnly(List<sObject> items, Map<Id, sObject> oldMap, Set<String> allowedFieldsOverride)
    {
        List<String> readOnlyFields = GetReadOnlyFields(items.get(0), allowedFieldsOverride);

        for(sObject o : items)
        {
            sObject old = oldMap.get(o.Id);
            for(String f : readOnlyFields)
            {
                if(o.get(f) != old.get(f))
                {
                    o.addError('All Built-in fields are not updateable.');
                    break;
                }
            }
        }
    }

    public static void DisallowDelete(List<sObject> items)
    {
        for(sObject o : items)
        {
            o.addError('Delete is not allowed.');
        }
    }
    static List<String> GetReadOnlyFields(sObject obj, Set<String> allowedFieldsOverride)
    {
        Schema.DescribeSobjectResult result = obj.getSObjectType().getDescribe();
        String objType = result.getName();

        String stype = objType.replace('__c', '');
        Integer index = stype.indexOf('__');
        String ns = index <0 ? '' : stype.substring(0, index) + '__';

        Boolean isInDev = String.isBlank(ns);

        if(!objReadOnlyFields.containsKey(objType))
        {
            List<String> readOnlyFields = new List<String>();

            for(Schema.SObjectField ft: result.fields.getMap().values())
            {
                Schema.DescribeFieldResult fd = ft.getDescribe();

                String fieldName = fd.getName();
                if (!fd.isUpdateable() || allowedFieldsOverride.contains(fieldName)) continue;

                if(!fd.isCustom() || isInDev || fieldName.startsWith(ns))
                {
                    readOnlyFields.add(fieldName);
                }
            }
            objReadOnlyFields.put(objType, readOnlyFields);
        }
        return objReadOnlyFields.get(objType);

    }
    static Map<String, List<String>> objReadOnlyFields = new Map<String, List<String>>();
}