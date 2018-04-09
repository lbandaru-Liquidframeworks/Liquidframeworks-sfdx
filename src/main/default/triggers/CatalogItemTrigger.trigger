trigger CatalogItemTrigger on Catalog_Item__c (before insert, before update, after update) 
{
    if(trigger.isBefore && trigger.isInsert)
    {
    	CatalogItemBuilder.OnBeforeInsert(trigger.new);
    }
    else if(trigger.isBefore && trigger.isUpdate)
    {
    	CatalogItemBuilder.OnBeforeUpdate(trigger.new, trigger.oldMap);
    }
    else if(trigger.isAfter && trigger.isUpdate)
    {
    	CatalogItemBuilder.OnAfterUpdate(trigger.new, trigger.oldMap);
    }
}