public class PriceBookRuleTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> items)
    {
        FXLicenseController.EnforceCPQLicense();
        PriceBookRuleHandler.RefreshQueryFields((List<Price_Book_Rule__c>)items);
        if(items.size()<=50)
        {
            PriceBookRuleHandler.ValidatePriceBookRules((List<Price_Book_Rule__c>)items);
        }
        
    }
    
    public override void OnBeforeUpdate(List<sObject> items, Map<Id, sObject> oldmap)
    {
        FXLicenseController.EnforceCPQLicense(); 
        PriceBookRuleHandler.RefreshQueryFields((List<Price_Book_Rule__c>)items);
        if(items.size()<=50)
        {
            PriceBookRuleHandler.ValidatePriceBookRules((List<Price_Book_Rule__c>)items);
        }
    }

    public override void OnBeforeDelete(List<sObject> items)
    {
        FXLicenseController.EnforceCPQLicense();        
    }   
       
}