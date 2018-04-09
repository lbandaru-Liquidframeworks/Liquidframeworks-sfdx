@RestResource(urlMapping='/TicketRestHandler/*')
global with sharing class TicketRestHandler
{       
    @HttpPost
    global static List<Ticket_Item__c> CreateTicketItems(Id newTicketId, List<Id> quoteItemIds, Boolean honorSequenceNumber, Decimal nextSequenceNumber)
    {
        List<Ticket_Item__c> ticketItems = new List<Ticket_Item__c>();
        for(Id quoteItemId: quoteItemIds)
        {
            ticketItems.add(CreateTicketItem(newTicketId, quoteItemId, honorSequenceNumber, nextSequenceNumber));
            nextSequenceNumber++;
        }       
        
        return ticketItems;
    }
    
    global static Ticket_Item__c CreateTicketItem(Id newTicketId, Id quoteItemId, Boolean honorSequenceNumber, Decimal nextSequenceNumber)
    {
        Id tktId = newTicketId;
        Id sourceTktItemId = quoteItemId;
        
        Schema.DescribeSObjectResult r = Ticket_Item__c.sObjectType.getDescribe();
        if(!r.isAccessible() || !r.isCreateable()) return null;
        String soql = 'SELECT ';
        String sep = '';
        for(SObjectField f: r.fields.getMap().values())
        {
            DescribeFieldResult df = f.getDescribe();
            if(!df.isCreateable() || df.isUnique()) continue;
            soql += sep + df.getName();
            sep = ',';
        }       
        soql += ' FROM ' + r.getName();
        soql += ' WHERE Id=:sourceTktItemId ';
        List<Ticket_Item__c> sourceItems = Database.query(soql);
        if(sourceItems.isEmpty()) return null;
        Ticket_Item__c source= sourceItems.get(0);
        Ticket_Item__c newItem = source.clone(false, false, false, false);
        
        newItem.Ticket__c = tktId;
        newItem.SyncID__c = StringUtility.newGuid();
        
        if (!honorSequenceNumber) {
            newItem.Sequence_Number__c = nextSequenceNumber;
        }
        
        Boolean createdInMobile = source.Created_in_Mobile__c;
        newItem.Created_in_Mobile__c = true;
        insert newItem;
        if(createdInMobile == false)
        {
            newItem.Created_in_Mobile__c = false;
            update newItem;
        }
        return newItem;        
    }    
}