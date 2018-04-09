@isTest
private class eFormHandler_Test
{
    static testmethod void Run()
    {
        Test.startTest();
        Set<String> forms = new Set<String>();
        String ns = StringUtility.FXNamespace();
        String form = ns + 'Ticket__c';
        forms.add(form);
        eFormHandler.InitForms(forms);    
        eFormHandler.CreateSyncIDField();   
        
        eForm_Config__c c = new eForm_Config__c(eForm_SObject__c = form, Key_SObject__c = 'FX5__Job__c');
        
        List<eForm_Config__c> configs = new List<eForm_Config__c>();
        configs.add(c);
        eFormHandler.Validate(configs, true);
        
        Test.stopTest();
    }
    
    static testmethod void eFormConfig_Test()
    {
        Test.startTest();
        String ns = StringUtility.FXNamespace();
        eForm_Config__c c = new eForm_Config__c(eForm_SObject__c = 'Ticket__c', Key_SObject__c = 'FX5__Job__c');
        
        insert c;
        
        Test.stopTest();
    }
}