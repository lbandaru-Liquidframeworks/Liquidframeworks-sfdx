public with sharing class FXJSDHandler
{
     public FXJSDHandler()
     {       
     }
     
     public FXJSDHandler(FXBaseController controller)
     {  
      
     }   
     
     public FXJSDHandler(ApexPages.StandardController controller)
     {   
        
     } 
     
     public Boolean jsdLicense 
     {
         get{ return FXLicenseController.isCurrentUserLicensed('FXJSD');}
     }    
   
    public Boolean fxmapLicense 
    {
         get{ return FXLicenseController.isCurrentUserLicensed('FXMAP');}
    } 
     
     @RemoteAction
     public static Boolean hasJsdLicense() {
          return FXLicenseController.isCurrentUserLicensed('FXJSD');
     }
     
     @RemoteAction
     public static List<sObject> queryObject(String soql) {
        FXLicenseController.EnforceJSDLicense();
        return Database.query(soql);
     }
   
    @RemoteAction
    public static SvcResult doWork(String params) {
        return FXWorkerLauncher.Run(params);
    }

    @RemoteAction
    public static SvcResult getJobQualifications(String jobId) {
        Map<String, String> params = new Map<String,String>();
        params.put('method', 'getjobqualifications');
        params.put('jobId', jobId);
        return JobQualificationService.Run(params);
    }

    @RemoteAction
    public static SvcResult getQualifiedContacts(String jobId) {
        Map<String, String> params = new Map<String,String>();
        params.put('method', 'getqualifiedcontacts');
        params.put('jobId', jobId);
        return JobQualificationService.Run(params);
    }

    @RemoteAction
    public static SvcResult getQualifiedItems(String startDate, String endDate, String qualificationIds) {
        Map<String, String> params = new Map<String,String>();
        params.put('method', 'getqualifieditems');
        params.put('startDate', startDate);
        params.put('endDate', endDate);
        params.put('qualificationIds', qualificationIds);         
        
        return JobQualificationService.Run(params);
    } 

    @RemoteAction
    public static SvcResult getQualifiedEquipment(String jobId) {
        Map<String, String> params = new Map<String,String>();
        params.put('method', 'getqualifiedequipment');
        params.put('jobId', jobId);
        return JobQualificationService.Run(params);
    }

     @RemoteAction
     public static Database.SaveResult insertObject(sObject obj) {
        FXLicenseController.EnforceJSDLicense();
        return Database.insert(obj);
     }

    @RemoteAction
    public static Database.SaveResult updateObject(sObject obj, List<String> fieldsToNull) {
        FXLicenseController.EnforceJSDLicense();

        if (fieldsToNull != null && !fieldsToNull.isEmpty()) {
            for (String fieldApiName : fieldsToNull) {
                obj.put(fieldApiName, null);
            }
        }
        return Database.update(obj);
    }  
     
     @RemoteAction
     public static Database.UpsertResult upsertObject(sObject obj) {
        FXLicenseController.EnforceJSDLicense();
        return Database.upsert(obj);
     }
     
     @RemoteAction
     public static Database.DeleteResult deleteObject(sObject obj) {
        FXLicenseController.EnforceJSDLicense();
        return Database.delete(obj);
     }
     

     @RemoteAction
     public static Database.SaveResult[] insertObjects(sObject[] objs, Boolean allOrNothing) {
        FXLicenseController.EnforceJSDLicense();
        return Database.insert(objs, allOrNothing);
     }
    
     @RemoteAction
     public static Database.SaveResult[] updateObjects(sObject[] objs, Boolean allOrNothing) {
        FXLicenseController.EnforceJSDLicense();
        return Database.update(objs, allOrNothing);
     }
     
     @RemoteAction
     public static Database.DeleteResult[] deleteObjects(sObject[] objs, Boolean allOrNothing) {
        FXLicenseController.EnforceJSDLicense();
        return Database.delete(objs, allOrNothing);
     }
}