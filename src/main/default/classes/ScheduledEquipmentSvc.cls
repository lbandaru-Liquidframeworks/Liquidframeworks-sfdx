@RestResource(urlMapping = '/getScheduledEquipment/*')
global with sharing class ScheduledEquipmentSvc{

    public static String GetScheduledEquipment(String processStr) {
      JSONParser parser = JSON.createParser(processStr);
      Type resultType = Type.forName('ScheduledEquipmentSvc.ScheduledEquipmentSvcRequest');
      ScheduledEquipmentSvc.ScheduledEquipmentSvcRequest readValueAsResult = (ScheduledEquipmentSvc.ScheduledEquipmentSvcRequest)parser.readValueAs(resultType);

      Result resultV1 = searchScheduledEquipment(readValueAsResult.jobId, readValueAsResult.keyword, readValueAsResult.itemLimit, readValueAsResult.itemOffset,
                  readValueAsResult.sortby, readValueAsResult.sortdir, readValueAsResult.fields);

      ScheduledEquipmentSvcResult quoteItemsSvcResult = new ScheduledEquipmentSvcResult();
      quoteItemsSvcResult.items = resultV1.items;
      quoteItemsSvcResult.soql = resultV1.soql;

      quoteItemsSvcResult.qtItemOnObjPBIds = new Map<Id, Id>();
      String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
      for(Quote_Item__c qi : [SELECT Id, Price_Book_Item__c FROM Quote_Item__c WHERE IsDeleted=false AND Price_Book_Item__c!=null AND Quote__c=:readValueAsResult.quoteId]) {
        quoteItemsSvcResult.qtItemOnObjPBIds.put(qi.Price_Book_Item__c, qi.Id);
      }

      return JSON.serializePretty(quoteItemsSvcResult, false);
    }

    //
    @HttpGet
    global static Result getScheduledEquipment() {

        String jobId = RestContext.request.params.get('jobId');
        String keyword = RestContext.request.params.get('keyword');
        String itemLimit = RestContext.request.params.get('limit');
        String itemOffset = RestContext.request.params.get('offset');
        String sortby = RestContext.request.params.get('sortby');
        String sortdir = RestContext.request.params.get('sortdir');
        String fields = RestContext.request.params.get('fields');

        return searchScheduledEquipment(jobId, keyword, itemLimit, itemOffset, sortby, sortdir, fields);
    }

    public static Result searchScheduledEquipment(String jobId, String keyword, String itemLimit, String itemOffset, String sortby, String sortdir, String fields) {

        String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();

        Result result = new Result();

        String commandText = 'SELECT ' + fields + ' FROM ' + fxNamespacePrefix + 'Equipment_Planning__c';
        commandText += ' WHERE IsDeleted = false AND ' + fxNamespacePrefix + 'Price_Book_Item__c != null' ;

        commandText += ' AND ' + fxNamespacePrefix + 'Job__c = \'' + jobId + '\' ';

        String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
        String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
        String nullsLast = (sb != '') ? 'NULLS LAST' : '';
        commandText += sb + ' ' + sd + ' ' + nullsLast;

        String lim = (itemLimit != '' ) ? (Integer.valueOf(itemLimit) > 2000) ? '2000' : itemLimit : '2000';
        String off = (itemOffset != '' ) ? (Integer.valueOf(itemOffset) > 2000) ? '2000' : itemOffset : '0';
        commandText += ' LIMIT ' + lim + ' OFFSET ' + off + ' ';

        result.soql = commandText;

        result.items = Database.query(commandText);

        return result;
    }

    global class Result {
        public List<Equipment_Planning__c> items;
        public string soql;
    }

    public class ScheduledEquipmentSvcResult {
        public List<Equipment_Planning__c> items;
        public string soql;
        public Map<Id, Id> qtItemOnObjPBIds;
    }

    public class ScheduledEquipmentSvcRequest {
        public String jobId;
        public String ticketId;
        public String quoteId;
        public String keyword;
        public String itemLimit;
        public String itemOffset;
        public String sortby;
        public String sortdir;
        public String fields;
    }
}
