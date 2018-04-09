@isTest
private class UserTriggerHandler_Test
{
    static testmethod void runTest()
    {
        User u = AlpineTestHelper.CreateStandardUser();
        u.IsActive = true;
        insert u;
        
        Test.startTest();
        User u2 = [SELECT Id, IsActive FROM User WHERE Id =:u.Id];
        u2.IsActive=false;
        update u2;
        Test.stopTest();
       
    }
}