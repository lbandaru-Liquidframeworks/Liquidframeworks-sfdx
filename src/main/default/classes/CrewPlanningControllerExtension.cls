public with sharing class CrewPlanningControllerExtension extends AlpinePageControllerBase 
{	
	public CrewPlanningControllerExtension(ApexPages.StandardController stdController)
	{
		controller = stdController;
		String id = ApexPages.currentPage().getParameters().get('id');
		
		
        crewPlanning = String.isBlank(id) ? new Crew_Planning__c(): 
            [SELECT Id, Charge_Code__c, Name, Comparable_End_Date__c, Comparable_Start_Date__c, Crew_Member__c, Job__c, Job__r.Name, Job__r.Tracking_Number__c, Job__r.Price_Book__c,Last_Notified__c, Last_Viewed__c, Per_Diem__c, Planned_End_Date__c, Planned_Start_Date__c, Role_on_Job__c FROM Crew_Planning__c WHERE Id = :id];
		
		if(id==null)
		{
			string jobKeyPrefix = Job__c.sObjectType.getDescribe().keyPrefix;
			String jobId = ApexPages.currentPage().getParameters().get('retURL').replace('/', '');
			Integer index = jobId.indexOf('?');
			if(index>0)
			{
				jobId = jobId.substring(0, index);
			}
			
			Job__c job = [SELECT Id, Name, Tracking_Number__c, Price_Book__c FROM Job__c WHERE Id=:jobId];
			crewPlanning.Job__r = job;
			crewPlanning.Job__c = job.Id;
		}		

		priceBookItemKeyPrefix = Price_Book_Item__c.sObjectType.getDescribe().keyPrefix;
		contactKeyPrefix = Contact.sObjectType.getDescribe().keyPrefix;
		priceBookId = string.valueOf(crewPlanning.Job__r.Price_Book__c);
		entityObj = crewPlanning;
	}


    public override ApexPages.Message validateEntity()
    {       
        return null;
    }
    
    public override ApexPages.Message upsertEntity()
    {
        upsert(crewPlanning);   
        return null;  
    }

	public override PageReference redirectPage(Boolean isSaveAndNew)
    {
    	string pageUrl = '';
    	if(!isSaveAndNew)
    	{ 
	    	pageUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + crewPlanning.Job__c;	    	
        }
        else
        {
        	PageReference pr = ApexPages.currentPage();
			pr.getParameters().clear();
			pr.getParameters().put('retURL', '/' + crewPlanning.Job__c);
			pageUrl = pr.getUrl();
		}

		PageReference pageRef = new PageReference(pageUrl);
	    pageRef.setRedirect(true);
	    return pageRef;
    }   

	public Crew_Planning__c crewPlanning { get; private set; }

	public string priceBookItemKeyPrefix {get;set;}
	public string contactKeyPrefix {get;set;}
	public string priceBookId {get;set;}
	
}