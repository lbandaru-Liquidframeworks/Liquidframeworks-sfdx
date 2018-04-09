public with sharing class UtilityCustomSettings
{
    public UtilityCustomSettings(ApexPages.StandardController controller) { }

    public string getCustomSettings() { return JSON.serialize(UtilityCustomSettings.CurrentCustomSettings()); }

    public string getMixPanelSecurityToken() { return UtilityCustomSettings.CurrentCustomSettings().MixPanelSecurityToken; }
    public string getCdnTibResourceURL() { return UtilityCustomSettings.CurrentCustomSettings().CDN_TIB_Resource_URL; }
    public string getCdnPbbResourceURL() { return UtilityCustomSettings.CurrentCustomSettings().CDN_PBB_Resource_URL; }
    public string getCdnRvResourceURL() { return UtilityCustomSettings.CurrentCustomSettings().CDN_RV_Resource_URL; }
    public string getCdnJwbResourceURL() { return UtilityCustomSettings.CurrentCustomSettings().CDN_JWB_Resource_URL; }
    public string getCdnJsdResourceURL() { return UtilityCustomSettings.CurrentCustomSettings().CDN_JSD_Resource_URL; }
    public string getCdnQibResourceURL() { return UtilityCustomSettings.CurrentCustomSettings().CDN_QIB_Resource_URL; }
    public string getCdnIibResourceURL() { return UtilityCustomSettings.CurrentCustomSettings().CDN_IIB_Resource_URL; }
    public string getCdnCmbResourceURL() { return UtilityCustomSettings.CurrentCustomSettings().CDN_CMB_Resource_URL; }
    public string getCdnPacketViewerResourceURL() { return UtilityCustomSettings.CurrentCustomSettings().CDN_PacketViewer_Resource_URL; }
    public string getJwbRoleRecordTypes() { return UtilityCustomSettings.CurrentCustomSettings().Job_Whiteboard_Role_Record_Types; }


    private static CustomSettings customSettings = null;

    public static CustomSettings CurrentCustomSettings()
    {
        if (customSettings == null)
        {

            customSettings = new CustomSettings();
            FX_Settings__c fxSettings = FX_Settings__c.getInstance(UserInfo.getUserId());

            customSettings.MixPanelSecurityToken = fxSettings.MixPanelSecurityToken__c;
            customSettings.Job_Whiteboard_Role_Record_Types = fxSettings.Job_Whiteboard_Role_Record_Types__c;

            String val = fxSettings.CDN_TIB_Resource_URL__c;
            if (String.isBlank(val)) {
                val = 'prod/tib/LATEST';
            }
            customSettings.CDN_TIB_Resource_URL = val;

            val = fxSettings.CDN_PBB_Resource_URL__c;
            if (String.isBlank(val)) {
                val = 'prod/pbb/LATEST';
            }
            customSettings.CDN_PBB_Resource_URL = val;

            val = fxSettings.CDN_RV_Resource_URL__c;
            if (String.isBlank(val)) {
                val = 'prod/rv/LATEST';
            }
            customSettings.CDN_RV_Resource_URL = val;

            val = fxSettings.CDN_JWB_Resource_URL__c;
            if (String.isBlank(val)) {
                val = 'prod/jwb/LATEST';
            }
            customSettings.CDN_JWB_Resource_URL = val;

            val = fxSettings.CDN_JSD_Resource_URL__c;
            if (String.isBlank(val)) {
                val = 'prod/jsd/LATEST';
            }
            customSettings.CDN_JSD_Resource_URL = val;

            val = fxSettings.CDN_QIB_Resource_URL__c;
            if (String.isBlank(val)) {
                val = 'prod/qib/LATEST';
            }
            customSettings.CDN_QIB_Resource_URL = val;

            val = fxSettings.CDN_IIB_Resource_URL__c;
            if (String.isBlank(val)) {
                val = 'iib/LATEST';
            }
            customSettings.CDN_IIB_Resource_URL = val;

            val = fxSettings.CDN_CMB_Resource_URL__c;
            if (String.isBlank(val)) {
                val = 'cmb/LATEST';
            }
            customSettings.CDN_CMB_Resource_URL = val;

            val = fxSettings.CDN_PacketViewer_Resource_URL__c;
            if (String.isBlank(val)) {
                val = 'prod/pv/LATEST';
            }
            customSettings.CDN_PacketViewer_Resource_URL = val;

            // optional: no default value
            val = fxSettings.PacketViewer_Instance_URL_Override__c;
            customSettings.PacketViewer_Instance_URL_Override = val;

        }

        return customSettings;
    }

    public class CustomSettings {
        public string MixPanelSecurityToken { get; set; }
        public string CDN_TIB_Resource_URL { get; set; }
        public string CDN_PBB_Resource_URL { get; set; }
        public string CDN_RV_Resource_URL { get; set; }
        public string CDN_JWB_Resource_URL { get; set; }
        public string CDN_JSD_Resource_URL { get; set; }
        public string CDN_QIB_Resource_URL { get; set; }
        public string CDN_IIB_Resource_URL { get; set; }
        public string CDN_CMB_Resource_URL { get; set; }
        public string CDN_PacketViewer_Resource_URL { get; set; }
        public string Job_Whiteboard_Role_Record_Types { get; set; }
        public string PacketViewer_Instance_URL_Override {get;set;}
    }
}
