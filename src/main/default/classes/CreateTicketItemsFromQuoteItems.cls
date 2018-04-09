@RestResource(urlMapping='/CreateTicketItemsFromQuoteItems/*')
global with sharing class CreateTicketItemsFromQuoteItems
{       
    @HttpPost
    global static List<Ticket_Item__c> CreateTicketItems(Id tktId, List<Id> quoteItemIds, 
        Boolean honorSequenceNumber, Decimal nextSequenceNumber)
    {        
        return TicketItemHandler.CreateTicketItems(tktId, quoteItemIds, honorSequenceNumber? null : nextSequenceNumber);         
    }

    public static List<Ticket_Item__c> refreshTktItemsList(List<Ticket_Item__c> tktItems, String fieldsStr) {
        String ns = UtilityGetNamespace.CurrentNamespace();
        Set<Id> tktItemIds = new Map<Id, Ticket_Item__c>(tktItems).keySet();
        String tiSoql = String.format('SELECT {0} FROM {1} WHERE Id IN :tktItemIds', new String[]{fieldsStr, ns+'Ticket_Item__c'});
        return (List<Ticket_Item__c>)Database.query(tiSoql);
    }

    public static List<Ticket_Item__c> CreateTicketItemsUsingPriceBookItems(Id newTicketId, List<Id> quoteItemIds, Map<Id, Quote_Item__c> qiLookup, String parentSyncId) {
        List<Ticket_Item__c> tktItems = new List<Ticket_Item__c>();

        for(Id quoteItemId: quoteItemIds) {
            Quote_Item__c qi = qiLookup.get(quoteItemId);
            String recName = Schema.SObjectType.Quote_Item__c.getRecordTypeInfosById().get(qi.RecordTypeId).getName();

            RecordTypeInfo recordInfo = Schema.SObjectType.Ticket_Item__c.getRecordTypeInfosByName().get(recName);
            if (recordInfo != null) {
                ID recId = recordInfo.getRecordTypeId();
                Ticket_Item__c tktItem  = (Ticket_Item__c)Ticket_Item__c.sObjectType.newSObject(recId, true);
                tktItem.Ticket__c = newTicketId;
                tktItem.Price_Book_Item__c = qi.Price_Book_Item__c;
                tktItem.SyncID__c = StringUtility.newGuid();

                if (!String.isBlank(parentSyncId)) {
                    tktItem.Parent_Ticket_Item__r = new Ticket_Item__c(SyncID__c = parentSyncId);
                }

                tktItems.add(tktItem);
            }
        }

        return tktItems;
    }

    global static Ticket_Item__c CreateTicketItem(Id newTicketId, Id quoteItemId, Boolean honorSequenceNumber, Decimal nextSequenceNumber, 
        List<SObjectField> tktItemFields, List<SObjectField> quoteItemFields)
    {
        return null;
    }    
}