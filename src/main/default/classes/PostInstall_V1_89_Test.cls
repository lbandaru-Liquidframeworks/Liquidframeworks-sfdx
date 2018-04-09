@isTest
private class PostInstall_V1_89_Test {
    static testmethod void testInstallScript_LowerVersion() {
        
       insert new FX_Settings__c(SyncVersion__c=4.0, SetupOwnerId = UserInfo.getUserId());
       PostInstall_V1_89 postinstall = new PostInstall_V1_89();
       Test.testInstall(postinstall, new Version(1,57));

  }
  
  static testmethod void testInstallScript_HigherVersion() {
  
       Test.StartTest();
       FX_Settings__c s = new FX_Settings__c(SyncVersion__c=3.0, SetupOwnerId = UserInfo.getUserId());
       insert s;
       
       PostInstall_V1_89 postinstall = new PostInstall_V1_89();
       Test.testInstall(postinstall, new Version(1,90));
       Test.StopTest();
       
       FX_Settings__c dbItem = [Select SyncVersion__c FROM FX_Settings__c WHERE Id=:s.Id];
       System.assertEquals(4.0, dbItem.SyncVersion__c);
       
       List<FX_Settings__c> items = [Select SyncVersion__c FROM FX_Settings__c WHERE SetupOwnerId=:UserInfo.getOrganizationId()];
       System.assertEquals(1.0, items.size());       
       System.assertEquals(4.0, items.get(0).SyncVersion__c);
  }
}