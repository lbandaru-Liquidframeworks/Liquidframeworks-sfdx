@RestResource(urlMapping = '/getFieldSets/*')
global with sharing class FieldSetSvc{

    //
    @HttpGet
    global static List<FieldSetData> getFieldSets() {

        String sObjectName = RestContext.request.params.get('sObjectType');
        
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe(); 
        
        Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(sObjectName);
        Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
        
        Map<String, Schema.FieldSet> fsMap = describeSObjectResultObj.fieldSets.getMap();
        
        List<FieldSetData> fieldsets = new List<FieldSetData>();

        for(string s:fsMap.keyset()){
        
            FieldSetData fieldSetData = new FieldSetData();
            fieldSetData.fields = new List<Field>();

            Schema.FieldSet fieldSet = FsMap.get(s);
            fieldSetData.name = fieldSet.getName();
            fieldSetData.label = fieldSet.getLabel();
            fieldSetData.description = fieldSet.getDescription();

            for(Schema.FieldSetMember fieldSetMemberObj:fieldSet.getFields()){
                 Field field = new Field();
                 field.name = fieldSetMemberObj.getFieldPath();
                 field.required = fieldSetMemberObj.getRequired() || fieldSetMemberObj.getDbRequired();
                 fieldSetData.fields.add(field);
            }
            fieldsets.add(fieldSetData);
        }    
        
        return fieldsets;            
    }

    global class FieldSetData {
        public List<Field> fields;
        public string name;
        public string label;
        public string description;
    }
    
    public class Field {
        public string name;
        public boolean required;
    }
}

