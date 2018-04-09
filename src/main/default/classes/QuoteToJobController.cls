public with sharing class QuoteToJobController
{
    ApexPages.StandardController controller {get;set;}
    public QuoteToJobController(ApexPages.StandardController stdController)
    {       
        controller = stdController;
    }   
   
    public PageReference redirect(){       
        Job__c job = QuoteHandler.CreateJob(controller.getId(),false);
        return redirectInternal(job);        
    }  
    
    @TestVisible
    PageReference redirectInternal(Job__c job)
    {
        try {
            insert job;          
            String pageUrl = String.format('/{0}/e?retURL=%2F{0}', new String[]{job.Id});
            PageReference pageRef = new PageReference(pageUrl);

            return pageRef;
        }
        catch(System.DmlException e){ 
            String msg = '';
            String sep = '';
            for (Integer i = 0; i < e.getNumDml(); i++) {
                msg += sep + e.getDmlMessage(i);
                sep = '. ';
            }
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL,'Converting Quote to Job failed. ' + msg));
            return null;            
        }
    }   
}