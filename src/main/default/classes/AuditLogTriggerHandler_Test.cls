@isTest
private class AuditLogTriggerHandler_Test
{
    static testmethod void update_Test()
    {      
       Audit_Log__c a = new Audit_Log__c(Type__c = 'UnitTest', Event_Date__c = Datetime.now());
       insert a;
       
       Audit_Log__c dbItem = [SELECT Id, Type__c, Event_Date__c FROM Audit_Log__c WHERE Id=:a.Id];
       dbItem.Event_Date__c = Datetime.now().addHours(-5);       
       Database.SaveResult r = Database.update(dbItem, false);
       System.assert(!r.isSuccess(), 'update on AuditLog should fail');
       
      
    }
    
    static testmethod void allowAdminUserToDelete_Test()
    {
        String guid = StringUtility.newGuid();
        String email = guid + '@test.com';
        String firstName = 'F' + guid;
        String lastName = 'L' + guid;
        
        Id userId = UserInfo.getUserId();
        User dummyUser = [select id, TimeZoneSidKey, LocaleSidKey, Email, UserName,
                EmailEncodingKey, ProfileId, LanguageLocaleKey
                from User WHERE Id = :userId];
                
                
        User newUser = new User(FirstName = firstName, LastName = lastName, Email = email,Username = email, ProfileId = FXAppSettingsHandler.getSystemAdminProfileId(), Alias =guid.substring(0,5),
            CommunityNickname = guid.substring(0,5),
        TimeZoneSidKey=dummyUser.TimeZoneSidKey,
        LocaleSidKey=dummyUser.LocaleSidKey,
        EmailEncodingKey=dummyUser.EmailEncodingKey,
        LanguageLocaleKey=dummyUser.LanguageLocaleKey);
       
       Audit_Log__c a = new Audit_Log__c(Type__c = 'UnitTest', Event_Date__c = Datetime.now());
       insert a;
       
       System.runAs(newUser)
       {
          
           Database.deleteResult r = Database.delete(new Audit_Log__c(Id=a.Id), false);  
           System.assert(r.isSuccess(), 'delete should succeed for admin user');
           
           
       }
    }
    
    static testmethod void disallowNonAdminUserToDelete_Test()
    {    
       
       Audit_Log__c a = new Audit_Log__c(Type__c = 'UnitTest', Event_Date__c = Datetime.now());
       insert a;
      
       System.runAs(AlpineTestHelper.CreateStandardUser())
       {
           Boolean r = AuditLogTriggerHandler.IsDeleteAllowedForCurrentUser();
           
            System.debug('IsDeleteAllowedForCurrentUser=' + r);
           System.assert(!r, 'delete should fail');
           
           //Database.deleteResult r = Database.delete(new Audit_Log__c(Id=a.Id), false);  
           //System.assert(r.isSuccess()==false, 'delete should fail');
           //System.debug(r.getErrors());          
       }
    }
    
}