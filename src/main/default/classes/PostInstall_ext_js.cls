global class PostInstall_ext_js implements InstallHandler {
  global void onInstall(InstallContext context) {
      if(!context.isUpgrade()) return;

      String ns = UtilityGetNamespace.CurrentNamespace();

      FX_Settings__c fs = FX_Settings__c.getOrgDefaults();
     
      Set<String> objectFields = Schema.SObjectType.FX_Settings__c.fields.getMap().keySet();
      
      if(objectFields.contains('CDN_TIB_Resource_URL__c')) {
        String tib = (String)fs.get(ns+'CDN_TIB_Resource_URL__c');
        if (String.isBlank(tib)) {
            fs.put(ns+'CDN_TIB_Resource_URL__c', 'prod/tib/LATEST');
        }

        String pbb = (String)fs.get(ns+'CDN_PBB_Resource_URL__c');
        if (String.isBlank(pbb)) {
            fs.put(ns+'CDN_PBB_Resource_URL__c', 'prod/pbb/LATEST');
        }

        String jwb = (String)fs.get(ns+'CDN_JWB_Resource_URL__c');
        if (String.isBlank(jwb)) {
            fs.put(ns+'CDN_JWB_Resource_URL__c', 'prod/jwb/LATEST');
        }

        String rv = (String)fs.get(ns+'CDN_RV_Resource_URL__c');
        if (String.isBlank(rv)) {
            fs.put(ns+'CDN_RV_Resource_URL__c', 'prod/rv/LATEST');
        }

        Database.update(fs, false);
      }
    }
}