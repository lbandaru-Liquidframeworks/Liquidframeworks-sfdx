trigger TicketTrigger_MixPanelTracking on Ticket__c (after insert, after update) {
    if(trigger.isInsert)
    {
        Integer count = 0;
        for(Ticket__c tkt : trigger.new)
        {
            if(!tkt.Created_In_Mobile__c) count +=1;
        }
        if(count>0)
        {
            MixPanelTracking.TrackEvent('TicketCreated', count);
        }
    }
    else
    {
         MixPanelTracking.TrackEvent('TicketEdited', trigger.new.size());
    }
}