trigger TriggerPriceBook_RefreshAssignment on Price_Book__c (after insert, after update)
{
    if(trigger.isInsert)
    {
        PriceBookAssignmentHandler.RefreshPriceBookAssignments(trigger.new);
    }
    else
    {
         List<Price_Book__c> assignmentPbs = new List<Price_Book__c>();
         for(Price_Book__c pb:trigger.new)
         {
                Price_Book__c old = trigger.oldMap.get(pb.Id);                
                if(pb.Account__c != old.Account__c || pb.Office__c != old.Office__c || pb.Segment__c != old.Segment__c)        
                {
                    assignmentPbs.add(pb);
                }  
         }
         if(!assignmentPbs.isEmpty())
         {
             PriceBookAssignmentHandler.RefreshPriceBookAssignments(assignmentPbs);
         }
    }
}