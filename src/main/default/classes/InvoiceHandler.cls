public class InvoiceHandler
{
    public static void InitInvoice(List<Invoice__c> items)
    {
        for(Invoice__c inv: items)
        {
            if(inv.Invoice_Date__c==null){
                inv.Invoice_Date__c = Date.today();
            }
        }
        FXObjectStatusHandler.SetInitialStatus(items);
    }
}
