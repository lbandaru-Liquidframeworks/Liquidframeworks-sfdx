trigger PaymentAppliedTrigger_MixPanelTracking on Payment_Applied__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Payment_Applied__c', trigger.isInsert, trigger.new.size());
}