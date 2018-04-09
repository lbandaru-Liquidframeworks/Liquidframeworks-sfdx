trigger ReportTemplateTrigger_MixPanelTracking on Report_Template__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Report_Template__c', trigger.isInsert, trigger.new.size());
}