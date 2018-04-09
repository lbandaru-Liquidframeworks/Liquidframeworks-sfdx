public with sharing virtual class FXBaseController {
    public String getNamespace() { return UtilityGetNamespace.CurrentNamespace(); }    
    public String getNamespaceWithoutUnderscores () { return UtilityGetNamespace.CurrentNamespaceWithoutUnderscores(); }

    public String getFxUserInfo() { return UtilityUserInfo.CurrentUserInfo(); }
    public String getFxUserInfoEscaped() { return UtilityUserInfo.CurrentUserInfoEscaped(); }

    public Boolean getIsSubjectNotEditable() {
        Map<String, String> params = ApexPages.currentPage().getParameters();

        String idStr = '';
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
            return !objId.getSObjectType().getDescribe().updateable;
        }

        return true;
    }

    public UtilityCustomSettings.CustomSettings getFxCustomSettings() { return UtilityCustomSettings.CurrentCustomSettings(); }

    public String getLanguageFile() {
        String languageFile = LanguageController.GetResourceURL(UserInfo.getLanguage());
        if (languageFile == '') languageFile = LanguageController.GetResourceURL('en_US');

        return languageFile;
    }

    public String getBaseManagedPackageVersion() {
        try{
            UserInfo.isCurrentUserLicensed(UtilityGetNamespace.CurrentNamespaceWithoutUnderscores()); //throws a catchable exception if in unmanaged org.
            System.Version vers = System.requestVersion();
            return vers.major() + '.' + vers.minor();
        } catch(exception e) {
        }

        return '';
    }

    public String getSalesforceBaseUrl() {
        try{
            return System.Url.getSalesforceBaseUrl().toExternalForm();
        } catch(exception e) { }
        return '';
    }

    public OutputHelper getOutputHelper() {
        OutputHelper outputHelper = new OutputHelper();
        outputHelper.example = new Price_Book_Item__c(Price__c = -12345.67);
        return outputHelper;
    }

    public Class OutputHelper {
        public Price_Book_Item__c example {get;set;}
    }

}
