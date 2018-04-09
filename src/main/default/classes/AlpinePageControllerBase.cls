public abstract with sharing class AlpinePageControllerBase 
{
	public SObject entityObj { get; protected set; }
        public ApexPages.StandardController controller {get; protected set;}   

	public abstract ApexPages.Message validateEntity();
	public abstract ApexPages.Message upsertEntity();

	public virtual PageReference save() 
	{
	    return save(false);
    }

    public virtual PageReference saveAndNew() 
	{
	    return save(true);
    }

    

    PageReference save(Boolean isSaveAndNew) 
	{
	    try
	    {
	    	ApexPages.Message msg = validateEntity();
	    	if(msg!=null)
	    	{
	    		ApexPages.addMessage(msg);
	    		return null;
	    	}	    		
            upsertEntity(); 
            return redirectPage(isSaveAndNew);           
        }
        catch(System.DMLException e) 
        {
            ApexPages.addMessages(e);
            return null;
        }
    }

    public virtual PageReference redirectPage(Boolean isSaveAndNew)
    {
    	string pageUrl = '';
    	if(!isSaveAndNew)
    	{ 
	    	pageUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + entityObj.getsObjectType().getDescribe().keyPrefix + '/o';	    	
        }
        else
        {
        	PageReference pr = ApexPages.currentPage();
			pr.getParameters().clear();
			pageUrl = pr.getUrl();
		}

		PageReference pageRef = new PageReference(pageUrl);
	    pageRef.setRedirect(true);
	    return pageRef;
    }

	public virtual PageReference doCancel()
  	{
    	return redirectPage(false);  
  	}	
}