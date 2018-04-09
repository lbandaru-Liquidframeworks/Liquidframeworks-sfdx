@isTest
private class FXSettingsHelper_Test
{
    static testmethod void GetterTest()
    {
       
        Boolean v = FXSettingHelper.DisableEquipmentTriggerForPMS;
        v = FXSettingHelper.AutoAddJobCreatorToCrew;
        v = FXSettingHelper.AutoFollowJobTicket;
        v = FXSettingHelper.EnableInventoryTracking;
        v = FXSettingHelper.MixPanelStopTracking;
        v = FXSettingHelper.SkipDefaultingPriceBookItemFields;
        v = FXSettingHelper.SuspendRuleEngine;
	String msg = JSON.serializePretty(FXSettingHelper.FXSettings);
    }
}