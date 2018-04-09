@RestResource(urlMapping='/SObjectChecksum/*')
global with sharing class SObjectChecksum {
   @HttpGet
   global static String getChecksum(){
      String sobjectName = RestContext.request.params.get('sobjectName');
      String lastSyncStr = RestContext.request.params.get('lastSync');
      Datetime lastSync = Datetime.valueOfGMT(lastSyncStr.replace('T',' '));
      return GetSObjectChecksum(sobjectName, lastSync);
    }

    @testVisible
    static String GetSObjectChecksum(String sObjectType, Datetime lastSync)
    {
        String ns = StringUtility.FXNamespace();
        //String ns = 'FX5__';
        String uid = UserInfo.getUserId();

        FX_Settings__c settings = FX_Settings__c.getInstance(uid);
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(sObjectType).getDescribe().fields.getMap();

        String extraPredicates = '';
        String sep = ' AND ';
        if(fields.containsKey(ns + 'sync__c'))
        {
           extraPredicates = sep + ns + 'Sync__c = true ';
        }
        else if(fields.containsKey('sync__c'))
        {
           extraPredicates = sep + 'Sync__c = true ';
        }

        if(fields.containsKey('altsync__c'))
        {
            extraPredicates += sep + ' AltSync__c=true ';
        }

        if(settings.SyncV4Config__c) {
            String jobField = null;
            if (fields.containsKey(ns + 'Job__c'))
            {
                jobField = ns + 'Job__c';
            }
            else if(fields.containsKey('Job_Share__c'))
            {
                jobField = 'Job_Share__c';
            }
            if (sobjectType == ns + 'Job__c' ){
                jobField = 'Id';
            }

            if(jobField != null) {
                extraPredicates += sep + jobField + ' IN (SELECT [ns]Job__c FROM [ns]Sync_Assignment__c WHERE IsDeleted=false AND [ns]Contact__r.[ns]User__c=\''+uid+'\')';
                extraPredicates = extraPredicates.replace('[ns]', ns);
            }
        }
        String soql = String.format('SELECT Id FROM {0} WHERE CreatedDate <=:lastSync {1} AND (IsDeleted = false OR (IsDeleted = true AND SystemModstamp >:lastSync)) ORDER By Id ALL ROWS',
         new String[]{sObjectType, extraPredicates});

        Set<Id> ids = new Map<Id, sObject>(Database.query(soql)).keySet();
        return GetChecksum(new List<Id>(ids));

    }

    @testVisible
    static String GetChecksum(List<Id> ids)
    {
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(String.join(ids, '')));
        return EncodingUtil.convertToHex(hash);
    }
}
