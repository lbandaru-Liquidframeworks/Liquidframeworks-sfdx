public with sharing class LanguageController {

    public String userLanguage  { get; private set; }
    public String userLocale { get; private set; }
    public String userCurrency { get; private set; }
    public String languageFile { get; private set; }

    public LanguageController(ApexPages.StandardController acon) {
        userLanguage = UserInfo.getLanguage();
        userLocale = UserInfo.getLocale();
        userCurrency = UserInfo.getDefaultCurrency();
        
        languageFile = GetResourceURL(userLanguage);
        if (languageFile == '') languageFile = GetResourceURL('en_US');
    }
    
    //Pass the resource name  
    public static String GetResourceURL(String resourceName)  
    {  
        //Fetching the resource  
        List <StaticResource> resourceList = [SELECT Name, NamespacePrefix, SystemModStamp FROM StaticResource WHERE Name = :resourceName];  
                              
        //Checking if the result is returned or not  
        if(resourceList.size() == 1)  
        {  
           //Getting namespace  
           String namespace = resourceList[0].NamespacePrefix;  
           //Resource URL  
           return '/resource/' + resourceList[0].SystemModStamp.getTime() + '/' + (namespace != null && namespace != '' ? namespace + '__' : '') + resourceName;   
        }  
        else return '';  
    }      
}