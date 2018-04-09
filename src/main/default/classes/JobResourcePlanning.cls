public class JobResourcePlanning
{
    public static void ApplyEquipmentPriceBookItem(List<Equipment_Planning__c> items)
    {
        ApplySubjectPriceBookItem(items, 'Equipment_Planning__c', 'Equipment__c', 'Equipment2__c', 'Price_Book_Item__c');
    }
    
    public static void ApplyContactPriceBookItem(List<Crew_Planning__c> items)
    {
        ApplySubjectPriceBookItem(items, 'Crew_Planning__c', 'Contact', 'Crew_Member__c', 'Role_on_Job__c');
    }
    
    static void ApplySubjectPriceBookItem(List<sObject> items, String sobjType, String subjectType, String subjectField, String pbiField)
    {
        String ns = StringUtility.FXNamespace();
        
        if(subjectType.endsWith('__c'))
        {
            subjectType = ns + subjectType;            
        }

        String settingField = ns + sobjType.replace('__c', '').replace('_', '') + 'SkipAssignPriceBookItem__c';      

        sobjType = ns + sobjType;
        subjectField = ns + subjectField;
        pbiField = ns + pbiField;
        
        Object skipTrigger = FX_Settings__c.getInstance(UserInfo.getUserId()).get(settingField);
        
        if(skipTrigger  == null || (Boolean)skipTrigger )
        {
            return;
        }
        
        Set<Id> subjectIds = new Set<Id>();
        List<sObject> itemsOfInterest = new List<sObject>();
        Set<Id> priceBookItemIds = new Set<Id>();
        Set<Id> jobIds = new Set<Id>();
        
        String jobField = ns + 'Job__c';
                
        for(sObject obj: items)
        {
            Id jobId = (Id)obj.get(jobField);
            Id subjectId = (Id)obj.get(subjectField);
            Id pbiId = (Id)obj.get(pbiField);
            
            if(String.isBlank(jobId) ||String.isBlank(subjectId))
            {
                continue;
            }  
            jobIds.add(jobId);
            itemsOfInterest.add(obj);
            subjectIds.add(subjectId);            
        }
        Map<Id, Id> subjectCatalogItemLookup = new Map<Id, Id>();
        Map<Id, Id> priceBookItemLookup = new Map<Id, Id>();
        
        Set<Id> catalogItemIds = new Set<Id>();
        
        String catalogItemField = ns + 'Catalog_Item__c';
        
        String subjectSoql = String.format('SELECT Id, {0}Catalog_Item__c FROM {1} WHERE IsDeleted=false AND Id IN :subjectIds AND {0}Catalog_Item__c!=null', 
            new String[]{ns, subjectType });

        
        for(sObject obj : Database.query(subjectSoql))
        {
            Id catalogItemId = (Id)obj.get(catalogItemField);            
            subjectCatalogItemLookup.put(obj.Id, catalogItemId);
            catalogItemIds.add(catalogItemId);
        }
        
        Set<Id> priceBookIds = new Set<Id>();
        Map<Id, String> jobPriceBookLookup = new Map<Id, String>();
        for(Job__c j :  [SELECT Id, Price_Book__c FROM Job__c WHERE IsDeleted=false AND Id IN :jobIds])
        {
        
            priceBookIds.add(j.Price_Book__c);
            jobPriceBookLookup.put(j.Id, String.valueOf(j.Price_Book__c));
        }
        
        Map<String, Id> pbiLookup = new Map<String,Id>();
        
        for(Price_Book__c p : [SELECT Id, (SELECT Id, Catalog_Item__c FROM Price_Book_Items__r WHERE IsDeleted=false AND Catalog_Item__c IN :catalogItemIds) FROM Price_Book__c WHERE IsDeleted=false AND Id IN :priceBookIds])
        {
            String pIdStr = String.valueOf(p.Id);
            for(Price_Book_Item__c pbi : p.Price_Book_Items__r)
            {
                pbiLookup.put(pIdStr + String.valueOf(pbi.Catalog_Item__c), pbi.Id);
            }
        }
      
        for(sObject o : itemsOfInterest)
        {  

            Id subjectId = (Id)o.get(subjectField);
            Id jobId =  (Id)o.get(jobField);
            String key = jobPriceBookLookup.get(jobId) + subjectCatalogItemLookup.get(subjectId);            
            if(!pbiLookup.containsKey(key)) 
            {
                continue;            
            }
            o.put(pbiField, pbiLookup.get(key));

        }     
    }
}