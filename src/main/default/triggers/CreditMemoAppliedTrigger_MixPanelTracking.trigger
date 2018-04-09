trigger CreditMemoAppliedTrigger_MixPanelTracking on Credit_Memo_Applied__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Credit_Memo_Applied__c', trigger.isInsert, trigger.new.size());
}