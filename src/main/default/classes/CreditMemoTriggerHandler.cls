public class CreditMemoTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> items)
    {
        super.OnBeforeInsert(items);
        sObjectHandler.InitTrackingNumber('C-', items);
        CreditMemoHandler.InitCreditMemo((List<Credit_Memo__c>)items);
    }

    public override void OnAfterInsert(List<sObject> items)
    {
        super.OnAfterInsert(items);
        MixPanelTracking.TrackEvent('CreditMemoCreated', items.size());
    }
}
