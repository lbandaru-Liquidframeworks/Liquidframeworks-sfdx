public without sharing class JobPropagatorPostInstall implements IFXPostInstall
{
    public virtual void Run(InstallContext context)
    {
        if(!context.isUpgrade()) return;
             
        Double v =PostInstallHelper.GetPreviousVersion(context);        
        String ns = StringUtility.FXNamespace();
        
        if(ns != 'FX5__' || v<=1.215)
        {                
            JobPropagatorBatchable.RunPostInstall();
                    
            String msg = 'JobPropagatorBatchable has been launched for FX5__Ticket_Item__c, FX5__Ticket_Log__c and FX5__Ticket_Checklist_Step__c. ';
            msg += 'Please see Apex Jobs (Setup -> Monitor -> Jobs -> Apex Jobs) for the status. ';
            msg += 'You may run these queries to check if any item failed: ';
            msg += ' SELECT count() FROM FX5__Ticket_Item__c WHERE Fx5__Job__c = null, ';
            msg += ' SELECT count() FROM FX5__Ticket_Log__c WHERE Fx5__Job__c = null, ';
            msg += ' SELECT count() FROM FX5__Ticket_Checklist_Step__c WHERE Fx5__Job__c = null ';
           
            String subject = 'JobPropagatorPostInstall launched';
                    
            EmailHandler.SendEmail(msg, subject, context.installerID());
        
        }
    }    
}