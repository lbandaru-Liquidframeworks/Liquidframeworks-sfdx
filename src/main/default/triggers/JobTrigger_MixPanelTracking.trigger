trigger JobTrigger_MixPanelTracking on Job__c (after insert, after update) {
     
    if(trigger.isInsert)
    {    
        Integer count = 0;
        for(Job__c j : trigger.new)
        {
            if(!j.Created_In_Mobile__c) count +=1;
        }
        if(count>0)
        {
            MixPanelTracking.TrackEvent('JobCreated', count);
        }
    }
    else
    {
        MixPanelTracking.TrackEvent('JobEdited', trigger.new.size());
    }
}