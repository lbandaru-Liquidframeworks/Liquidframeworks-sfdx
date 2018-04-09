trigger QualificationRequirementTrigger_MixPanelTracking on Qualification_Requirement__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Qualification_Requirement__c', trigger.isInsert, trigger.new.size());
}