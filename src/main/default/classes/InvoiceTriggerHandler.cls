public class InvoiceTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> items)
    {
        super.OnBeforeInsert(items);
        sObjectHandler.InitTrackingNumber('I-', items);
        InvoiceHandler.InitInvoice((List<Invoice__c>)items);
    }

    public override void OnAfterInsert(List<sObject> items)
    {
        super.OnAfterInsert(items);
        MixPanelTracking.TrackEvent('InvoiceCreated', items.size());
    }
}
