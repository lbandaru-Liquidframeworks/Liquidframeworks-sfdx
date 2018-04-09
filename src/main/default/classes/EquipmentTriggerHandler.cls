public class EquipmentTriggerHandler extends FXTriggerHandler
{    
    public override void OnAfterUpdate(List<sObject> items, Map<Id, sObject> oldmap)
    {
        EquipmentHandler.ProcessOutOfServiceChanged((List<Equipment__c>)items, (Map<Id, Equipment__c>)oldmap);    
        if(FXSettingHelper.DisableEquipmentTriggerForPMS != true && PMSProcessed !=true 
            && (Test.isRunningTest() || FXLicenseController.isCurrentUserLicensed('FXEAM')))
        {
            //EquipmentHandler.ApplyPMS(oldmap.keyset());

            EquipmentHandler.ApplyPMS((List<Equipment__c>)items, (Map<Id, Equipment__c>)oldmap);  

            PMSProcessed =true;
        }        
    }
    static Boolean PMSProcessed {get;set;}
}