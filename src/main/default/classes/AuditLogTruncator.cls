public class AuditLogTruncator extends FXBatchableBase
{
    Set<String> auditLogTypes {get;set;}
    Datetime cutOffDate {get;set;}
    
    public AuditLogTruncator()
    {
        FX_Settings__c setting = FX_Settings__c.getInstance(UserInfo.getUserId());     
        auditLogTypes = new Set<String>();
        if(String.isBlank(setting.AuditLogTypeForTruncation__c))
        {
            auditLogTypes.add('SyncComplete');
            auditLogTypes.add('SyncDownloadComplete');
        }
        else
        {
            String[] types = setting.AuditLogTypeForTruncation__c.split(',');
            for(String t: types)
            {
                String item = t.trim();
                if(!String.isBlank(item))
                {
                    auditLogTypes.add(item);
                }
            }
        }
        
        Integer retainingDays = (setting.AuditLogRetainingDays__c == null)? 30 : (Integer)setting.AuditLogRetainingDays__c;
        cutOffDate = Datetime.now().addDays(-1 * retainingDays);  
        this.soqlQuery = String.format('SELECT Id FROM {0}Audit_Log__c WHERE IsDeleted = false AND {0}Type__c IN :auditLogTypes AND CreatedDate<:cutOffDate', new String[]{StringUtility.FXNamespace()});
    }
    
    public override String DryRun()
    {
        String msg = String.format('auditLogTypes: {0}; cutOffDate: {1}; soql: {2}', new String[]{String.join(new List<String>(auditLogTypes), ','), String.valueOf(cutOffDate), soqlQuery});
        return msg;
    }
    
    public override Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(soqlQuery);
    }
    
    public override void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        delete scope;
    }
    
}