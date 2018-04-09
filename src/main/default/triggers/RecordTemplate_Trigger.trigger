trigger RecordTemplate_Trigger on Report_Template__c (before insert, before update) 
{
     RecordTypeIdMangler.PopulateRecordTypeId(trigger.new, 'SObject__c', 'SObject_Record_Type__c', 'SObject_Record_Type_Id__c');
}