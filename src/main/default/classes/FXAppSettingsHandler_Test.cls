@isTest
private class FXAppSettingsHandler_Test
{
    static testmethod void runTest()
    {
        FXAppSettingsHandler.SetAppSettingValue('UnitTestIsRunning', 'true');
        String v = FXAppSettingsHandler.GetAppSettingValue('UnitTestIsRunning');
        System.assert(v=='true');
        
        FXAppSettingsHandler.SetAppSettingValue('UnitTestIsRunning', 'false');
        String v2 = FXAppSettingsHandler.GetAppSettingValue('UnitTestIsRunning');
        System.assert(v2=='false');
        
        FXAppSettingsHandler.GetSystemAdminProfileId();
    }
}