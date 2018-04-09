trigger SyncConfigurationTrigger on Sync_Configuration__c (before insert, before update) {
    for(Sync_Configuration__c sc : trigger.new)
    {
        String str = SyncConfigBuilderController.GetUniqueId(sc);
        sc.UniqueExternalId__c = str;
        sc.UniqueId__c = str;
    }

}