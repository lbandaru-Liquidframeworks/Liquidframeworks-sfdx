global class UtilityGetBaseManagedPackageVersion
{
    global UtilityGetBaseManagedPackageVersion(){
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=edge'); // fixes Microsoft hardcoding "salesforce.com" into there list of sites needing compatibility
    }
    global UtilityGetBaseManagedPackageVersion(ApexPages.StandardController controller) {
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=edge'); // fixes Microsoft hardcoding "salesforce.com" into there list of sites needing compatibility
    }

    global string getBaseManagedPackageVersion() { return BaseManagedPackageVersion(); }

    public static String BaseManagedPackageVersion() {
        try{
            UserInfo.isCurrentUserLicensed(UtilityGetNamespace.CurrentNamespaceWithoutUnderscores()); //throws a catchable exception if in unmanaged org.
            System.Version vers = System.requestVersion();
            return vers.major() + '.' + vers.minor();
        } catch(exception e) {
        }

        return '';
    }
}