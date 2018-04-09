public class PostInstallHelper
{
    public static Double GetPreviousVersion(InstallContext context)
    {
        Version prevVer = context.previousVersion();        
        String v = '' + prevVer.major() + '.' + prevVer.minor();
        return Double.valueOf(v);
    }    
}