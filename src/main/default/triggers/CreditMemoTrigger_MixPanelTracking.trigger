trigger CreditMemoTrigger_MixPanelTracking on Credit_Memo__c (after insert, after update) 
{
    MixPanelTracking.TrackEvent('Credit_Memo__c', trigger.isInsert, trigger.new.size());
}