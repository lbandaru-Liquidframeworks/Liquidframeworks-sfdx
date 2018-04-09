global class UtilityGetNamespace
{
	global UtilityGetNamespace(){
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=edge'); // fixes Microsoft hardcoding "salesforce.com" into there list of sites needing compatibility
	}
    global UtilityGetNamespace(ApexPages.StandardController controller) { 
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=edge'); // fixes Microsoft hardcoding "salesforce.com" into there list of sites needing compatibility
	}
    
    global string getNamespace() { return UtilityGetNamespace.CurrentNamespace(); }
    global string getNamespaceWithoutUnderscores() { return UtilityGetNamespace.CurrentNamespaceWithoutUnderscores(); }
    
    private static string namespace = null;
    
    global static string CurrentNamespace() 
    { 
        if (namespace == null) 
        {
            string stype = SObjectType.Job__c.Name;
            stype = stype.replace('__c', '');
            namespace = '';
            if (stype.indexOf('__') > -1)
                namespace = stype.substring(0, stype.indexOf('__')) + '__'; 
        }
        
        return namespace;
    } 
    
    global static string CurrentNamespaceWithoutUnderscores()
    {
        string ns = CurrentNamespace();        
        if (ns != '')
            ns = ns.replace('__', '');            
        return ns;
    }
}