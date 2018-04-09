public class RuleCriteriaStackBuilderController
{
    public RuleCriteriaStackBuilderController()
    {        
       QueryDirtyRules();
       if(Rules.isEmpty())
       {               
           ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, allProcessedMsg));
       }
      
    }   
    public List<Price_Book_Rule__c> Rules {get;set;}

    String allProcessedMsg = 'All Rules have been preprocessed, i.e. no entry has IsCriteriaDirty = true.';   
    
    public String getNamespaceWithoutUnderscores () { return UtilityGetNamespace.CurrentNamespaceWithoutUnderscores(); }

    
    public PageReference Save()
    {
        for(Price_Book_Rule__c r:Rules)
        {
            r.IsCriteriaDirty__c = false;
        }
        Integer successCount = 0;
        Integer failCount = 0;
        String msg = '';
        Integer index = 0;
        String sep = '<br />';
        for(Database.SaveResult r : Database.update(Rules, false))
        {
            if(r.isSuccess())
            {
                successCount++;
            }
            else
            {
                failCount++;
                Price_Book_Rule__c rule =  Rules.get(index);
                msg += sep + 'Failed: ' + rule.Name + ' ( ' + rule.Id + ')';
                for(Database.Error err : r.getErrors()) {
                    msg += ', ' + err.getMessage();              
                }

            }
            index++;
        }
        msg = successCount + ' items updated, ' + failCount + ' failed. ' + msg;       

        QueryDirtyRules();
        if(Rules.isEmpty())
        {
           msg += allProcessedMsg;  
        }

        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, msg));
        return null;
    }

    void QueryDirtyRules()
    {
        Rules = [SELECT Name, Applies_To__c, Price_Book__r.Name, Criteria__c, CriteriaStack__c, IsCriteriaDirty__c FROM Price_Book_Rule__c WHERE IsDeleted=false AND IsCriteriaDirty__c=true LIMIT 1000];
    }


    public PageReference TaintAllRules()
    {
        Integer batchCount = 5000;
        TaintingResult r = TaintRules(batchCount);
        String msg = r.successCount + ' items flagged for processing. ';
        if(r.failCount>0)
        {
            msg += '<br />' + r.failCount + ' failed, ' + r.msg;
        }
        if(r.hasMore == true)
        {
            msg += '<br />A batch job is enqueued to flag more Rules. ';           
        }
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, msg));
        QueryDirtyRules();
        return null;
    }

    TaintingResult TaintRules(Integer itemCount)
    {
        TaintingResult result = new TaintingResult();

        List<Price_Book_Rule__c> rulesToUpdate = new List<Price_Book_Rule__c>();
        for(Price_Book_Rule__c r:[SELECT Id FROM Price_Book_Rule__c WHERE IsDeleted=false AND IsCriteriaDirty__c=false LIMIT :itemCount])
        {
            r.IsCriteriaDirty__c = true;
            rulesToUpdate.add(r);
        }
        Integer successCount = 0;
        Integer failCount = 0;
        String msg = '';
        Integer index = 0;

        for(Database.SaveResult r : Database.update(rulesToUpdate, false))
        {
            if(r.isSuccess())
            {
                successCount++;
            }
            else
            {
                failCount++;
                Price_Book_Rule__c rule = rules.get(index);
                msg += '<br />Failed: ' + rule.Name + ' (' + rule.Id + ')';
                for(Database.Error err : r.getErrors()) {
                    msg += ', ' + err.getMessage();              
                }
            }
            index++;
        }
        if(successCount == itemCount)
        {
            result.hasMore = true;
            System.enqueueJob(new PriceBookRuleTaintingCriteriaBatchable());
        }
        result.successCount = successCount;
        result.failCount = failCount;
        result.msg = msg;
        return result;
    }
    
    class TaintingResult 
    {
        public Integer successCount {get;set;}
        public Integer failCount {get;set;}
        public String msg {get;set;}
        public Boolean hasMore {get;set;}
    }
}