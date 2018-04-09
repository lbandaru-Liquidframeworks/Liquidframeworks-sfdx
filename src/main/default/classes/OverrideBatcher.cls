public class OverrideBatcher extends FXBatchableBase 
{
    static Boolean ExcutedOnce = false;

    @testVisible
    static String TicketItemCountSoql_Tickets
    {
        get
        {
            return String.format('SELECT COUNT() FROM {0}Ticket_Item__c WHERE {0}Ticket__c IN :objIds AND {0}Ticket__r.{0}IsReadOnlyOnConsole__c=false AND {0}AllowOverride__c=true',
                    new String[]{StringUtility.FXNamespace()});
        }
    }

    @testVisible
    static String TicketItemCountSoql_Jobs
    {
        get
        {
            return String.format('SELECT COUNT() FROM {0}Ticket_Item__c WHERE {0}Ticket__r.{0}Job__c IN :objIds AND {0}Ticket__r.{0}IsReadOnlyOnConsole__c=false AND {0}AllowOverride__c=true',
                    new String[]{StringUtility.FXNamespace()});
        }
    }

    public static void RunOnJobs(Set<Id> objIds)
    {
    	if(ExcutedOnce == true) return;        
        Run(TicketItemCountSoql_Jobs, objIds);               
    }

    public static void RunOnTickets(Set<Id> objIds)
    {    	  
        if(ExcutedOnce == true) return;
        Run(TicketItemCountSoql_Tickets, objIds);  
         
    }

    static void Run(String countSoql, Set<Id> objIds)
    {
    	Integer count = Database.countQuery(countSoql);
        String soql = countSoql.replace('COUNT()', 'Id');
        Integer batchSize = (Integer)FXSettingHelper.OverrideBatchSize;
        Integer availableSoqls = Limits.getLimitQueries() - Limits.getQueries() - 5;

        if(availableSoqls>0 && availableSoqls<batchSize)
        {
            batchSize = availableSoqls;
        }
        if(count<=batchSize)
        {
        	ExcutedOnce = true;
        	Database.update(Database.query(soql));
        }
        else if(!System.isBatch() && !System.isFuture()) 
        {
        	RunBatch(soql, objIds, batchSize );
        }
    }
    
    @testVisible
    static void RunBatch(String soql, Set<Id> ids, Integer batchSize)
    {
    	OverrideBatcher b = new OverrideBatcher(soql, ids);
    	Database.executeBatch(b, batchSize);
    }
    
    Set<Id> objIds {get;set;}

    private OverrideBatcher(String soql, Set<Id> ids)
    {   
    	objIds = ids;
        soqlQuery = soql.replace('COUNT()', 'Id');
    }

    public override Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(soqlQuery);
    }

    public override void execute(Database.BatchableContext BC, List<sObject> scope)
    {   
    	ExcutedOnce = true;
        Database.update(scope, false);
    }     
}