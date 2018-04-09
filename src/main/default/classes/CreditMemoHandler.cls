public class CreditMemoHandler
{
    public static void InitCreditMemo(List<Credit_Memo__c> items)
    {
        for(Credit_Memo__c cm: items)
        {
            if(cm.Date__c==null){
                cm.Date__c = Date.today();
            }
        }
        FXObjectStatusHandler.SetInitialStatus(items);
    }
}
