public class RecordTypeIdMangler
{
    public static void PopulateRecordTypeId(List<SObject> items, String objectTypeField, String recordTypeDeveloperNameField, String recordTypeIDField)
    {        
        List<RecordType> recordTypes = [SELECT SObjectType, DeveloperName, Id from RecordType WHERE IsActive=true];
        if(recordTypes.isEmpty()) return;

        PopulateRecordTypeId(items, objectTypeField, recordTypeDeveloperNameField, recordTypeIDField, recordTypes);
    }

    public static void PopulateRecordTypeId(List<SObject> items, String objectTypeField, 
        String recordTypeDeveloperNameField, 
        String recordTypeIDField, 
        List<RecordType> recordTypes)
    {
        if(items.isEmpty() || String.IsBlank(objectTypeField)
            ||String.IsBlank(recordTypeDeveloperNameField)
            ||String.IsBlank(recordTypeIDField)
            ||recordTypes.isEmpty()) return;       
      

        Map<string, Id> recordTypesLookup = new Map<string, Id>();

        String namespace = UtilityGetNamespace.CurrentNamespace();

        objectTypeField = nameSpace + objectTypeField;
        recordTypeDeveloperNameField = nameSpace + recordTypeDeveloperNameField;
        recordTypeIDField = nameSpace + recordTypeIDField;


        for(RecordType rt : recordTypes)
        {
            recordTypesLookup.put( rt.SObjectType +  rt.DeveloperName, rt.Id);
        }
        for(SObject item: items)
        {
            Object sobj = item.get(objectTypeField);
            Object objRecordType = item.get(recordTypeDeveloperNameField);

            if(sobj==null || objRecordType==null || string.isBlank(String.valueOf(sobj)) || string.isBlank(String.valueOf(objRecordType)))
            {   
                 item.put(recordTypeIDField, null); 
            }
            else
            {

                String sobjType = String.valueOf(sobj);
                //this is for eFormConfig validation rule, eFormSobject - custom object with no namespace
                // and the unit test use Job__c as eForm
                if(sobjType == 'Job__c') 
                {
                    sobjType = namespace + 'Job__c';
                }

                String key = sobjType + String.valueOf(objRecordType);
                item.put(recordTypeIDField, recordTypesLookup.containsKey(key)? recordTypesLookup.get(key):null);       
            }   
                
        }
    }
}