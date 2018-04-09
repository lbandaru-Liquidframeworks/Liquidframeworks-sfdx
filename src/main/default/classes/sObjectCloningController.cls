public with sharing class sObjectCloningController
{
	public sObjectCloningController()
	{
		String objIdStr = ApexPages.currentPage().getParameters().get('Id');
		if(String.isBlank(objIdStr))
		{
			objIdStr =ApexPages.currentPage().getParameters().get('retURL').replace('/', '');
		}

		if(!String.isBlank(objIdStr))
		{
			SourceEntityID = Id.valueOf(objIdStr);
		}
		Schema.DescribeSObjectResult r = SourceEntityID.getSobjectType().getDescribe();
		HasSufficientAccess = r.isCreateable();
		if(!String.isBlank(SourceEntityID))
		{
			Map<String, String> params = ApexPages.currentPage().getParameters();

			String cloneTypes  = params.get('cloningtypes');
			Boolean isDryRun = params.containsKey('dryrun');
			Boolean forceSync = params.containsKey('sync');

			SObjectCloner.ExecMode mode = SObjectCloner.ExecMode.Async;

			if(isDryRun)
			{
				mode = SObjectCloner.ExecMode.DryRun;
			}
			else if(forceSync)
			{
				mode = SObjectCloner.ExecMode.Sync;
			}
			
			objCloner = new SObjectCloner(SourceEntityID, cloneTypes, mode);
			SourceEntity = SObjectDescribeInfo.GetSObject(SourceEntityID);
			DescribeInfoItems = objCloner.objInfo;
			if(DescribeInfoItems!= null && !DescribeInfoItems.isEmpty())
			{
				DescribeInfo = DescribeInfoItems.get(0);
			}
			SourceObjUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + SourceEntityID;
		}
		InProgress = false;	
		HasChildTypesForCloning = HasSufficientAccess && DescribeInfoItems!=null && DescribeInfoItems.size()>1;	

		if(!HasSufficientAccess)
        { 
        	String msg = 'Insufficient Privileges - You do not have the level of access necessary to create ' + r.getLabel() + '. Please contact your administrator if access is necessary.';
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, msg));
        }
	}	

	public String PageMessage {get; private set;}

	public PageReference redirect()
	{
		if(String.isBlank(SourceEntityID) || HasSufficientAccess != true)
		{
			return null;
		}

		PageMessage = objCloner.DoWork();
		EntityCopy = objCloner.EntityCopy;

		if(EntityCopy != null)
		{
			CopyObjUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + EntityCopy.Id;			
			PageReference pageRef = new PageReference(CopyObjUrl);
            return pageRef;
		}        
        return null;        
	}
	
	public String SourceObjUrl {get; set;}
	public String CopyObjUrl {get; set;}
	public Boolean HasSufficientAccess {get;set;}
	
	public Id SourceEntityID {get; private set;}
	public sObject SourceEntity {get; private set;}
	public SObjectDescribeInfo DescribeInfo {get; private set;}
	public List<SObjectDescribeInfo> DescribeInfoItems {get; private set;}

	public Boolean InProgress {get; set;}
	public Boolean HasChildTypesForCloning {get;set;}

	SObjectCloner objCloner {get;set;}

	public sObject EntityCopy {get; private set;}
}