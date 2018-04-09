@isTest
private class CustomObjectInfo_Test
{
    static testmethod void CustomObjectInfoHandler_Test()
    {
        Test.startTest();
        CustomObjectInfoHandler c = new CustomObjectInfoHandler();
        SvcResult s = c.DoWork(null);
        System.debug(s);       
        Test.stopTest();
        List<sObject> results = [SELECT Id FROM CustomObjectInfo__c];
        System.assert(results.size()==2, 'should have two items instead of ' + results.size() + ', msg:' + s.Message);
    }
    
    static testmethod void RefreshCustomObjectInfo_NegativeTest()
    {
        Test.startTest();
        String str = '{"size" : 2,"totalSize" : 2,"done" : true,"queryLocator" : null,"entityTypeName" : "CustomObject",'+
  '"records" : [ {"Id" : "01I36000001VBPgEAO","DeveloperName" : "Audit_Log"}, {"Id" : "01I36000001VBPhEAO","DeveloperName" : "Audit_Log"}]}';
        String msg = CustomObjectInfoHandler.RefreshCustomObjectInfo(str);
        System.debug(msg);
        Test.stopTest();
        List<sObject> results = [SELECT Id FROM CustomObjectInfo__c];
        System.assert(results.size()==1, 'should have two items instead of ' + results.size() + ', msg:' + msg);
    }
    
    static testmethod void CustomFieldInfoHandler_Test()
    {
        CustomObjectInfoHandler c = new CustomObjectInfoHandler();
        SvcResult s = c.DoWork(null);
        
        Test.startTest();
        CustomFieldInfoHandler cf = new CustomFieldInfoHandler();
        SvcResult s2 = cf.DoWork(null);
        System.debug(s2);       
        Test.stopTest();
        List<sObject> results = [SELECT Id FROM CustomFieldInfo__c];
        System.assert(results.size()==4, 'should have 4 items instead of ' + results.size() + ', msg:' + s2.Message);
    }   
    
}