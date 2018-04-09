public class FXSettingHelper
{
    
    public static Boolean TurnOffJobPropagator
    {
        get { return FXSettings.TurnOffJobPropagator__c; }
    }
    

    public static Boolean DisableEquipmentTriggerForPMS
    {
        get { return FXSettings.DisableEquipmentTriggerForPMS__c; }
    }
    
    public static Boolean AutoAddJobCreatorToCrew
    {
        get { return FXSettings.AutoAddJobCreatorToCrew__c; }
    }
    
    public static Boolean AutoFollowJobTicket
    {
        get { return FXSettings.AutoFollowJobTicket__c; }
    }
    
    public static Boolean EnableInventoryTracking
    {
        get { return FXSettings.EnableInventoryTracking__c; }
    }
    
    
    public static Boolean MixPanelStopTracking
    {
        get { return FXSettings.MixPanelStopTracking__c; }
    }
    
    
    public static Boolean SkipDefaultingPriceBookItemFields
    {
        get { return FXSettings.SkipDefaultingPriceBookItemFields__c; }
    }
    
    
    public static Boolean SuspendRuleEngine
    {
        get { return FXSettings.SuspendRuleEngine__c; }
    }    
    public static Decimal OverrideBatchSize
    {
        get 
        { 
            return FXSettings.OverrideBatchSize__c!=null? FXSettings.OverrideBatchSize__c : 50; 
        }
    }
    @testVisible
    static FX_Settings__c FXSettings
    {
        get
        {
            if(vFXSettings == null)
            {
                vFXSettings = FX_Settings__c.getInstance(UserInfo.getUserId());
            }
            return vFXSettings;
        }
    }
    static FX_Settings__c vFXSettings = null;

}