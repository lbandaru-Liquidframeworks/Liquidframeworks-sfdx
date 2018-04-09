public with sharing class EquipmentWorkOrderTemplatesController
{
    Equipment__c EquipEntity {get;set;}
    public List<Work_Order__c> woTemplates {get;set;}
    public String TemplateWorkOrderId {get;set;}
    
    public EquipmentWorkOrderTemplatesController(ApexPages.StandardController ctrl)
    {
        Map<String, String> params = ApexPages.CurrentPage().getParameters();
        String idStr = params.get('Id');
        EquipEntity = [SELECT Id, Name FROM Equipment__c WHERE Id=:idStr];
        woTemplates = [SELECT Id, Name FROM Work_Order__c WHERE IsDeleted=false AND IsTemplate__c = true];
        
        if(params.containsKey('templateid'))
        {
            TemplateWorkOrderId = params.get('templateid');           
        }
    }    
   
    
    public PageReference CreateWorkOrder()
    {
        if(String.isBlank(TemplateWorkOrderId)) return null;        
        
        Schema.DescribeSObjectResult dsrServiceHistory = Service_History__c.sObjectType.getDescribe();
        if(!Equipment__c.sObjectType.getDescribe().isUpdateable() 
            || !Work_Order__c.sObjectType.getDescribe().isCreateable()
            || !dsrServiceHistory.isQueryable()
            || !dsrServiceHistory.isUpdateable())
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, 'User does NOT have permission(s) to update Equipment, create Work Order or update Service History. Please contact Administrator.'));
            return null;
        }
        Datetime dtNow = Datetime.now();
        
        EquipEntity.Out_of_Service__c = true;
        update EquipEntity;  
        
        String soql = MetadataHelper.GetSelectQuery(Work_Order__c.sObjectType.getDescribe());
        soql += ' WHERE Id=:TemplateWorkOrderId';
        
        Work_Order__c w = (Work_Order__c) Database.query(soql);
        Work_Order__c newWorkOrder = w.clone(false, false,false, false);
        newWorkOrder.Tracking_Number__c = null;
        newWorkOrder.SyncID__c = null;
        newWorkOrder.IsTemplate__c = false;
        newWorkOrder.Equipment__c = EquipEntity.Id;
        insert newWorkOrder;
        
        List<Service_History__c> shs = [SELECT Id FROM Service_History__c WHERE Equipment__c = :EquipEntity.Id AND Work_Order__c=null AND CreatedDate>= :dtNow ORDER BY CreatedDate desc];
        if(!shs.isEmpty())
        {
            Service_History__c sh = shs.get(0);
            sh.Work_Order__c = newWorkOrder.Id;
            update sh;
        }
        
        
        String pageUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + EquipEntity.Id;
        PageReference p = new PageReference(pageUrl);
        p.setRedirect(true);
        return p;
    }
    
}