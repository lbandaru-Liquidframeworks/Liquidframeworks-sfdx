trigger TriggerSyncConfig_PriceBookAssignment on Sync_Configuration__c (after delete, after insert, after update) {

    PriceBookAssignmentHandler.RefreshPriceBookAssignments(SyncAssignmentManager.GetContacts(trigger.isDelete ? trigger.old : trigger.new));

}