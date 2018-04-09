public class FXAppSettingsHandler
{
    public static String GetAppSettingValue(String name)
    {
         FXAppSettings__c f = FXAppSettings__c.getInstance(name); 
         return f==null? null: f.Value__c;
    }
    
    public static void SetAppSettingValue(String name, String value)
    {
        FXAppSettings__c f = FXAppSettings__c.getInstance(name);
        if(f==null)
        {
            f = new FXAppSettings__c();
            f.Name = name;
            f.Value__c = value;
            insert f;
        }
        else
        {
            f.Value__c = value;
            update f;            
        }
    }    
    
    public static String GetSystemAdminProfileId()
    {
        FXAppSettings__c f = FXAppSettings__c.getInstance('SystemAdminProfileId');
        if(f!=null) return f.Value__c;
        
        Organization o = [SELECT Name, CreatedDate FROM Organization LIMIT 1];
        Datetime dt = o.CreatedDate;
            
        List<Profile> ps = [SELECT Id FROM Profile WHERE Name='System Administrator' AND CreatedDate <= :dt];
        if(ps.isEmpty()) return null;
        
        f= new FXAppSettings__c();
        f.Name='SystemAdminProfileId';
        f.Value__c = ps.get(0).Id;
        insert f;        
        return ps.get(0).Id;    
    }        
}