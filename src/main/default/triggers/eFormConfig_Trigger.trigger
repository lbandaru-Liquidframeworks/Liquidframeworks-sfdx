trigger eFormConfig_Trigger on eForm_Config__c (before insert, before update) 
{
    List<RecordType> recordTypes = [SELECT SObjectType, DeveloperName, Id from RecordType WHERE IsActive=true];
    RecordTypeIdMangler.PopulateRecordTypeId(trigger.new, 'eForm_SObject__c', 'eForm_SObject_Record_Type__c', 'eForm_SObject_Record_Type_Id__c', recordTypes);
    RecordTypeIdMangler.PopulateRecordTypeId(trigger.new, 'Key_SObject__c', 'Key_SObject_Record_Type__c', 'Key_SObject_Record_Type_Id__c', recordTypes);
}