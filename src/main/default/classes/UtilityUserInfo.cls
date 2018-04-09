public with sharing class UtilityUserInfo
{
    public Boolean IsSubjectNotEditable {get;set;}
   public UtilityUserInfo(ApexPages.StandardController controller)
   {
        Map<String, String> params = ApexPages.currentPage().getParameters();

        String idStr = '';
        IsSubjectNotEditable = false;
        if(params.containsKey('objectId'))
        {
            idStr = params.get('objectId');
        }
        else if(params.containsKey('Id'))
        {
            idStr = params.get('Id');
        }
        if(!String.isBlank(idStr))
        {
            Id objId = (Id)idStr;
            IsSubjectNotEditable = !objId.getSObjectType().getDescribe().updateable;
        }
   }

    public string getUserInfo() { return UtilityUserInfo.CurrentUserInfo(); }
    public string getUserInfoEscaped() { return UtilityUserInfo.CurrentUserInfoEscaped(); }

    private static string fxUserInfo = null;
    private static string fxUserInfoEscaped = null;

    private static string urlEncode(string s) {
        if (String.isBlank(s)) return s;

        return EncodingUtil.urlEncode(s, 'UTF-8');
    }

    public static string CurrentUserInfo()
    {
        if (fxUserInfo == null)
        {
            FxUserInfo fxUserInfoObj = createCurrentUserInfo();
            fxUserInfo = JSON.serialize(fxUserInfoObj);
        }

        return fxUserInfo;
    }

    public static string CurrentUserInfoEscaped() {
        if (fxUserInfoEscaped == null)
        {
            FxUserInfo fxUserInfoObj = createCurrentUserInfo();

            fxUserInfoObj.userName = urlEncode(fxUserInfoObj.userName);
            fxUserInfoObj.name = urlEncode(fxUserInfoObj.name);
            fxUserInfoObj.firstName = urlEncode(fxUserInfoObj.firstName);
            fxUserInfoObj.lastName = urlEncode(fxUserInfoObj.lastName);
            fxUserInfoObj.organizationName = urlEncode(fxUserInfoObj.organizationName);
            fxUserInfoObj.officeName = urlEncode(fxUserInfoObj.officeName);

            fxUserInfoEscaped = JSON.serialize(fxUserInfoObj);
        }

        return fxUserInfoEscaped;
    }

    private static FxUserInfo createCurrentUserInfo()
    {
        FxUserInfo fxUserInfoObj = new FxUserInfo();

        fxUserInfoObj.userType = UserInfo.getUserType();
        fxUserInfoObj.userName = UserInfo.getUserName();
        fxUserInfoObj.id = UserInfo.getUserId();
        fxUserInfoObj.name = UserInfo.getName();
        fxUserInfoObj.firstName = UserInfo.getFirstName();
        fxUserInfoObj.lastName = UserInfo.getLastName();
        fxUserInfoObj.organizationId = UserInfo.getOrganizationId();
        fxUserInfoObj.organizationName = UserInfo.getOrganizationName();
        fxUserInfoObj.language = UserInfo.getLanguage();
        fxUserInfoObj.locale = UserInfo.getLocale();
        fxUserInfoObj.usercurrency = UserInfo.getDefaultCurrency();
        fxUserInfoObj.officeId = null;
        fxUserInfoObj.officeName = null;
        fxUserInfoObj.profileId = UserInfo.getProfileId();
        fxUserInfoObj.isMultiCurrencyOrganization = UserInfo.isMultiCurrencyOrganization();
        fxUserInfoObj.email = UserInfo.getUserEmail();
        fxUserInfoObj.uiThemeDisplayed = UserInfo.getUiThemeDisplayed();
        fxUserInfoObj.isLightningThemeEnabled = (fxUserInfoObj.uiThemeDisplayed == 'Theme4d');

        TimeZone tz = UserInfo.getTimeZone();
        Datetime dt = Datetime.now();

        fxUserInfoObj.timeZone = tz.getDisplayName();
        fxUserInfoObj.timeZoneId = tz.getID();
        fxUserInfoObj.timeZoneOffset = (tz.getOffset(dt) / 1000 / 60);

        Id userId = UserInfo.getUserId();
        for (Contact c : [SELECT Office__c, Office__r.Name, User__r.Phone FROM Contact where User__c = :userId LIMIT 1]) {
            fxUserInfoObj.officeId = c.Office__c;
            fxUserInfoObj.phone = c.User__r.Phone;
            if (c.Office__r != null) {
                fxUserInfoObj.officeName = c.Office__r.Name;
            }
        }

        return fxUserInfoObj;
    }

    private class FxUserInfo {

        private string userType { get; set; }
        private string userName { get; set; }
        private string id { get; set; }
        private string name { get; set; }
        private string firstName { get; set; }
        private string lastName { get; set; }
        private string organizationId { get; set; }
        private string organizationName { get; set; }
        private string language { get; set; }
        private string locale { get; set; }
        private string usercurrency { get; set; }
        private string officeId { get; set; }
        private string officeName { get; set; }
        private string timeZone { get; set; }
        private string timeZoneId { get; set; }
        private Integer timeZoneOffset { get; set; }
        private string profileId { get; set; }
        private Boolean isMultiCurrencyOrganization { get; set; }
        private string email { get; set; }
        private string phone { get; set; }
        private string uiThemeDisplayed { get; set; }
        private Boolean isLightningThemeEnabled { get; set; }
    }
}
