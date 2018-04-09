trigger AccountTrigger on Account (before update) {

    Set<Id> archivedAccounts = new Set<Id>();
    for(Account acct:trigger.new)
    {
        if(acct.IsArchived__c && !trigger.oldMap.get(acct.Id).IsArchived__c)
        {
            archivedAccounts.add(acct.Id);
        }       
    }   
    if(!archivedAccounts.isEmpty())
    {
        List<Price_Book__c> pbs = [SELECT Id, Name, Global_Price_Book__c FROM Price_Book__c WHERE Global_Price_Book__c=true AND Account__c IN :archivedAccounts];
        if(!pbs.isEmpty())
        {
            for(Price_Book__c pb : pbs)
            {
                pb.Global_Price_Book__c = false;
            }
            update pbs;
        }                  
    }    
}