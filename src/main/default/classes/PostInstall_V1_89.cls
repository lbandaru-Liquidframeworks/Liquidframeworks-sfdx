global class PostInstall_V1_89 implements InstallHandler {
  global void onInstall(InstallContext context) {
    if(!context.isUpgrade()) return;

    Version prevVer = context.previousVersion();

    if(prevVer.major() >=1 && prevVer.minor()>=89)
    {

      Id orgId = UserInfo.getOrganizationId();
      List<FX_Settings__c> items = [SELECT Id, SyncVersion__c, SetupOwnerId FROM FX_Settings__c];

      List<FX_Settings__c> itemsToUpdate = new List<FX_Settings__c>();
      Boolean hasGlobal = false;
      for(FX_Settings__c s : items)
      {
          if(s.SyncVersion__c<4)
          {
              s.SyncVersion__c = 4.0;
              itemsToUpdate.add(s);
          }
          if(s.SetupOwnerId == orgId)
          {
              hasGlobal = true;
          }
      }
      Database.update(itemsToUpdate, false);

      if(!hasGlobal)
      {
          FX_Settings__c gs  = new FX_Settings__c(SyncVersion__c=4.0, SetupOwnerId = orgId);
          insert gs;
      }
    }
  }
}