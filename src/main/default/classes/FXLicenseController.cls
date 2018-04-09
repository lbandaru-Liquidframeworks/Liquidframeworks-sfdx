public class FXLicenseController
{
    public static Boolean isCurrentUserLicensed(String nsPackage)
    {
        try
        {
            if(!String.isBlank(nsPackage) && !UserInfo.isCurrentUserLicensed(nsPackage)) return false;
        }
        catch(System.TypeException e)
        {
            System.debug('Exception on ' + nsPackage + ' : ' + e.getMessage());
            return false;
        }        
        return true;
        
    }  
    public static void EnforceLicense(String nsPackage)
    {
        // if(!Test.isRunningTest() && !isCurrentUserLicensed(nsPackage))
        if (false)
        {
            throw new FXException('The user needs license for ' + nsPackage + '. Please contact the administrator.');
        }
    }

    public static void EnforceTKTLicense(String objType)
    {
        if(UserInfo.getUserType() == 'Standard')
        {
            String ns = StringUtility.FXNamespace();
            String objTypeStr = objType.replace(ns, '');
            if(ObjectsToEnforceTKTLicense.contains(objTypeStr))
            {               
                EnforceLicense('FXTKT');
            }
        }
    }   
    static Set<String> ObjectsToEnforceTKTLicense = new Set<String>{'Job__c', 'Ticket__c', 'Quote__c', 'Price_Book__c', 'Price_Book_Item__c'};
        
    public static void EnforceCPQLicense()
    {
        EnforceLicense('FXCPQ');
    }
    
    public static void EnforceEAMLicense()
    {
        EnforceLicense('FXEAM');
    }
    
    public static void EnforceJSDLicense()
    {
        EnforceLicense('FXJSD');
    }
}