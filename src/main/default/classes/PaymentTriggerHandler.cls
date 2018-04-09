public class PaymentTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> items)
    {
        super.OnBeforeInsert(items);
        sObjectHandler.InitTrackingNumber('P-', items);
    }

    public override void OnAfterInsert(List<sObject> items)
    {
        super.OnAfterInsert(items);
        MixPanelTracking.TrackEvent('PaymentCreated', items.size());
    }
}
