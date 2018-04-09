public virtual class FXTriggerHandler implements IFXTriggerHandler 
{    
    
    public static void Run(List<sObject> items, Map<Id, sObject> oldMap, Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete)
    {
        String objApiName = items.get(0).getSObjectType().getDescribe().getName();
        if(isBefore==true)
        {
           FXLicenseController.EnforceTKTLicense(objApiName);           
        }
        String triggerHandlerClassName = objApiName.endsWith('__c')? 
            objApiName.replace('__c', '').replace('__', '.').replace('_', '')+ 'TriggerHandler'
            : StringUtility.FXNamespace().replace('__', '.') + objApiName.replace('_', '')+ 'TriggerHandler';

        Type t = Type.forName(triggerHandlerClassName);
        if(t==null) 
        {
            String msg = String.format('There is not trigger handler {0} for {1}', new String[]{triggerHandlerClassName, objApiName});
            System.debug(msg);
            return;
            //throw new FXTriggerHandlerException('Unknown trigger handler: ' + triggerHandlerClassName + '. Please contact the administrator.');
        }
        
        IFXTriggerHandler triggerHandler = (IFXTriggerHandler)t.newInstance();
        if(triggerHandler!=null)
        {
          triggerHandler.Execute(items, oldMap, isBefore, isInsert, isUpdate, isDelete);
        }
    }
    
    public class FXTriggerHandlerException extends Exception
    {       
    }
    
    public virtual void Execute(List<sObject> items, Map<Id, sObject> oldMap, Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete)
    {       
        if(isBefore == true)
        {
            if(isInsert == true)
            {
                OnBeforeInsert(items);
            }
            else if(isUpdate == true)
            {
                OnBeforeUpdate(items, oldMap);
            }
            else
            {
                OnBeforeDelete(items);
            }
        }
        else
        {
            if(isInsert == true)
            {
                OnAfterInsert(items);
            }
            else if(isUpdate == true)
            {
                OnAfterUpdate(items, oldMap);
            }
            else
            {
                OnAfterDelete(items);
            }
        }
    }
    
    
    
    public virtual void OnBeforeInsert(List<sObject> items)
    {
        
    }
    
    public virtual void OnAfterInsert(List<sObject> items)
    {
       
    }
    
    public virtual void OnBeforeUpdate(List<sObject> items, Map<Id, sObject> oldMap)
    {
        
    }
    
    public virtual void OnAfterUpdate(List<sObject> items, Map<Id, sObject> oldMap)
    {
                   
    }
    
    public virtual void OnBeforeDelete(List<sObject> items)
    {
    }
    
    public virtual void OnAfterDelete(List<sObject> items)
    {
        
    }    
    
}