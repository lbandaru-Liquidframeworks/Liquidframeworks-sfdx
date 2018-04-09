global without sharing class PostInstall implements InstallHandler 
{
    global void onInstall(InstallContext context) 
    { 
        String ns = StringUtility.FXNamespace().replace('__', '');
       
        List<ApexClass> classes = String.isBlank(ns)? 
        [SELECT Name,NamespacePrefix FROM ApexClass WHERE Status ='Active' AND Name LIKE '%PostInstall']
        :[SELECT Name,NamespacePrefix FROM ApexClass WHERE Status ='Active' AND Name LIKE '%PostInstall' AND NamespacePrefix=:ns];

        Set<String> scheduled = new Set<String>();
        Set<String> failed = new Set<String>();
        Set<String> skipped = new Set<String>();

        for(ApexClass c : classes)       
        {
            if(c.Name == 'IFXPostInstall' || c.Name == 'PostInstall') continue;
            String className = String.isBlank(c.NamespacePrefix)? c.Name : c.NamespacePrefix + '.' + c.Name;
            Type t = Type.forName(className);
            try {
                Object obj = t.newInstance();
                if(obj instanceOf IFXPostInstall)
                {
                    IFXPostInstall p = (IFXPostInstall)obj;
                    p.Run(context);
                    scheduled.add(className);
                } 
                else
                {
                    skipped.add(className);
                }                
            }
            catch (Exception e) { 
                failed.add(className + ' : ' + e.getMessage() + ' * StackTrace: ' + e.getStackTraceString());
            }
            finally {                
            }
        }
        String subject = 'PostInstall info';

        Map<String, Set<String>> msgs = new Map<String, Set<String>>();
        if(!scheduled.isEmpty())
        {
            msgs.put('Launched successfully: ', scheduled);
        }

        if(!skipped.isEmpty())
        {
            msgs.put('Skipped (not IFXPostInstall): ', skipped);
        }

        if(!failed.isEmpty())
        {
            msgs.put('Failed: ', failed);
        }
        EmailHandler.SendEmail(JSON.serializePretty(msgs), subject, context.installerID());
    }    
}