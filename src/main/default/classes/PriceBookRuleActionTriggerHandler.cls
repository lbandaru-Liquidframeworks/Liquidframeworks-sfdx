public class PriceBookRuleActionTriggerHandler extends FXTriggerHandler
{
    public override void OnBeforeInsert(List<sObject> items)
    {
        FXLicenseController.EnforceCPQLicense();          
    }
    
    public override void OnBeforeUpdate(List<sObject> items, Map<Id, sObject> oldmap)
    {
        FXLicenseController.EnforceCPQLicense();        
    } 

    public override void OnBeforeDelete(List<sObject> items)
    {
        FXLicenseController.EnforceCPQLicense();        
    }        
}