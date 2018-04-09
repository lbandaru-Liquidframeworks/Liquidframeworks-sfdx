public class FXObjectStatusHandler
{
    public static void SetInitialStatus(List<sObject> items)
    {
        if(items==null || items.isEmpty()) return;
        String ns = StringUtility.FXNamespace();
        Schema.DescribeSObjectResult dsr = items.get(0).getSObjectType().getDescribe();
        String fxStatusField = (ns + 'status__c').toLowercase();       
        String fxCreateInMobileField = (ns + 'Created_in_Mobile__c').toLowercase(); 
        
        Set<String> fields = dsr.fields.getMap().keySet();
        if(!fields.contains(fxStatusField)) return;

        Boolean hasRecordTypeId = fields.contains('recordtypeid');
        Boolean hasCreatedInMobileField = fields.contains(fxCreateInMobileField);
        
        
        String sobjType = dsr.getName();
        String sobjTypeWithoutNamespace = sobjType.replace(ns, '');
        
        
        List<Status__c> statuses = [SELECT Id, SObject_Record_Type__c, Sync__c, Initial_Status_Console__c, Initial_Status_Mobile__c 
                                  FROM Status__c 
                                  WHERE SObject__c=:sobjTypeWithoutNamespace 
                                  AND (Initial_Status_Console__c=true OR Initial_Status_Mobile__c=true)];
        
        if(statuses.isEmpty()) return;
        Map<string, Id> defaultStatus = new Map<string, Id>();
        for (Status__c status: statuses)
        {
            if(status.Initial_Status_Console__c == true)
            {
              defaultStatus.put(string.valueOf(status.SObject_Record_Type__c)  + 'console', status.Id);  
            }
            if(status.Initial_Status_Mobile__c == true)
            {
              defaultStatus.put(string.valueOf(status.SObject_Record_Type__c)  + 'mobile', status.Id);  
            }
        }      
        
       
        Map<Id, RecordType> recordTypes = new Map<Id, RecordType>([SELECT Id, Developername FROM RecordType where IsActive=true AND SobjectType =:sobjType]);
        

        for(sObject t: items)
        {
            if(t.get(fxStatusField) != null) continue;
            
            String recordTypeStr = '';
            if(hasRecordTypeId && !recordTypes.isEmpty())
            {
               Object recordTypeId =  t.get('recordtypeid');
               if(recordTypeId !=null && recordTypes.containsKey((Id)recordTypeId))
               {
                   recordTypeStr = recordTypes.get((Id)recordTypeId ).DeveloperName;
               }
            }
            
            Object createInMobileValue = hasCreatedInMobileField? t.get(fxCreateInMobileField) : null;
            
            String app = (createInMobileValue!=null && Boolean.valueOf(String.valueOf(createInMobileValue))== true)? 'mobile' : 'console';           
           
            String key = recordTypeStr + app;
            String appKeyOnly = 'null' + app;
            
            if(defaultStatus.containsKey(key))
            {
                t.put(fxStatusField, defaultStatus.get(key));                           
            }
            else if(defaultStatus.containsKey(appKeyOnly))
            {
                t.put(fxStatusField, defaultStatus.get(appKeyOnly));                           
            }
            
        } 
    }
}