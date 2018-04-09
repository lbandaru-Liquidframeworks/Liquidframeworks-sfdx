trigger CatalogItemPriceBookTrigger on CatalogItemPriceBook__c (before insert, before update, before delete, after insert, after update, after delete) {
    FXTriggerHandler.Run(trigger.isDelete? trigger.old:trigger.new, trigger.oldMap, trigger.isBefore, trigger.isInsert, trigger.isUpdate, trigger.isDelete);
}