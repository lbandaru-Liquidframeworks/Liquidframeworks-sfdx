@isTest
private class RuleCriteriaStackBuilder_Test
{
	static Price_Book_Rule__c CreateRule(Id pbId, String criteria, String criteriaStack, Boolean saveNow)
    {
        Price_Book_Rule__c rule = new Price_Book_Rule__c(Price_Book__c = pbId, 
        	IsActive__c=true, 
        	Applies_To__c='Ticket__c',
            Criteria__c=criteria,
            CriteriaStack__c = criteriaStack);
        if(saveNow) insert rule;
        return rule;
    }

    static void SetupRules()
    {
    	Job__c j = AlpineTestHelper.CreateJobs(1, true).get(0);
        Id pbId = j.Price_Book__c;
        String ns = StringUtility.FXNamespace();

        String criteria = ns + 'Status__c!=null';
        String criteriaStack = '["{\\"type\\":\\"BinaryExpression\\",\\"operator\\":\\"!=\\",\\"left\\":{\\"type\\":\\"Identifier\\",\\"value\\":\\"[fieldName]\\"},\\"right\\":{\\"type\\":\\"Constant\\",\\"value\\":\\"null\\"}}"]';
        criteriaStack = criteriaStack.replace('[fieldName]', ns + 'Status__c');
        Price_Book_Rule__c rule = CreateRule(pbId, criteria, criteriaStack, true); 

        List<Price_Book_Rule__c> dbRules = [SELECT Id FROM Price_Book_Rule__c];
        for(Price_Book_Rule__c r: dbRules)
        {
        	r.IsCriteriaDirty__c = false;
        }
        update dbRules;
    }

    static testmethod void VF_Test()
    {   
        Test.startTest();    
        SetupRules();

        PageReference page = new PageReference('RuleCriteriaStackBuilder');
        Test.setCurrentPage(page);              
        RuleCriteriaStackBuilderController  ctrl = new RuleCriteriaStackBuilderController();

        ctrl.TaintAllRules();
        ctrl.Save();
        Test.stopTest();
    }  
}