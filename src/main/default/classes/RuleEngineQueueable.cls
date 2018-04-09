public class RuleEngineQueueable implements Queueable
{
    Set<Id> itemIds {get;set;}
    Boolean skipRecommendedItems {get;set;}
    Boolean isOnTicket {get;set;}
       
    public RuleEngineQueueable(Set<Id> paramItemIds, Boolean skipRecommendedItems0)
    {
        itemIds = paramItemIds;
        skipRecommendedItems = skipRecommendedItems0;
       

    }

    public void execute(QueueableContext context) 
    {
        if(itemIds == null || itemIds.isEmpty()) return;
        String idStr = String.valueOf(new List<Id>(itemIds).get(0));
        if(idStr.startsWith(Ticket__c.sObjectType.getDescribe().getKeyPrefix()))
        {
          RuleEngineCore.Execute(itemIds, skipRecommendedItems);
        }
        else if(idStr.startsWith(Ticket_Item__c.sObjectType.getDescribe().getKeyPrefix()))
        {
           RuleEngineCore.ExecuteOnTicketItems(itemIds, skipRecommendedItems);
        }
        else if(idStr.startsWith(Quote__c.sObjectType.getDescribe().getKeyPrefix()))
        {
          RuleEngineForQuote.Execute(itemIds, skipRecommendedItems);
        }
        else if(idStr.startsWith(Quote_Item__c.sObjectType.getDescribe().getKeyPrefix()))
        {
           RuleEngineForQuote.ExecuteOnQuoteItems(itemIds, skipRecommendedItems);
        }

    }
}