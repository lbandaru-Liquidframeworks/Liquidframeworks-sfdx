@RestResource(urlMapping = '/updateQtItem/*')
global with sharing class QuoteItemsUpdate {

    @HttpPost
    global static UpdateQtItemResult updateQtItem(string objStr, string typeStr, string qtFields, string qtItemFields) {
        return QuoteItemUpdate(objStr, typeStr, qtFields, qtItemFields);
    }

    public static UpdateQtItemResult QuoteItemUpdate(string objStr, string typeStr, string qtFields, string qtItemFields) {
        Type objType = Type.forName(typeStr);

        sObject obj = (sObject)JSON.deserialize(objStr, objType);

        sObject[] objs = new sObject[]{ obj };

        Database.SaveResult[] res = Database.update(objs, false);

        UpdateQtItemResult results = new UpdateQtItemResult();
        results.id = obj.id;
        results.success = res[0].success;
        results.errors = new List<UpdateError>();

        for (Database.SaveResult sr : res) {
            for(Database.Error err : sr.getErrors()) {
                UpdateError ue = new UpdateError();
                ue.message = err.getMessage();
                ue.fields = err.getFields();
                results.errors.add(ue);
            }
        }

        String ns = UtilityGetNamespace.CurrentNamespace();

        //get qtItem
        String sql = 'SELECT ' + qtItemFields + ', '+ns+'Quote__c' + ' FROM '+ns+'Quote_Item__c WHERE Id=\'' + obj.id + '\'';
        System.debug(sql);
        Quote_Item__c qi = database.query(sql);

        //get qt
        String qtsql = 'SELECT ' + qtFields + ' FROM '+ns+'Quote__c WHERE Id=\'' + qi.Quote__c + '\'';
        System.debug(qtsql);
        Quote__c q = database.query(qtsql);

        //get qtItem children
        String qiChildrenSql = 'SELECT ' + qtItemFields + ' FROM '+ns+'Quote_Item__c WHERE IsDeleted=false AND '+ns+'Parent_Quote_Item__c=\'' + qi.id + '\'';
        System.debug(qtsql);
        List<Quote_Item__c> qiChildren = database.query(qiChildrenSql);

        results.qtItem = qi;
        results.quote = q;
        results.qtItemChildren = qiChildren;

        return results;
    }

    global class UpdateQtItemResult {
        public Quote_Item__c qtItem;
        public Quote__c quote;
        public List<Quote_Item__c> qtItemChildren;

        public String id { get; set; }
        public Boolean success  { get; set; }
        public List<UpdateError> errors  { get; set; }
    }

    public class UpdateError {
        public String message { get; set; }
        public List<String> fields { get; set; }
    }

    public static String Process(String processStr) {
        //need updated list, not updated, error messages returned

        JSONParser parser = JSON.createParser(processStr);
        Type resultType = Type.forName('QuoteItemsUpdate.QtItemsResponse');
        QuoteItemsUpdate.QtItemsResponse readValueAsResults = (QuoteItemsUpdate.QtItemsResponse)parser.readValueAs(resultType);
        
        QuoteItemsUpdateResult resQuoteItemUpdate = QuoteItemsUpdate(readValueAsResults.itemsStr, readValueAsResults.typeStr, readValueAsResults.qtFields, readValueAsResults.qtItemFields);
        System.debug(resQuoteItemUpdate);

        return JSON.serializePretty(resQuoteItemUpdate, false);                  
    }

    public static QuoteItemsUpdateResult QuoteItemsUpdate(List<Quote_Item__c> qiList, string typeStr, string qtFields, string qtItemFields) {
        String ns = UtilityGetNamespace.CurrentNamespace();
        
        if (!qtFields.contains('LastModifiedDate')) {
            qtFields += ', LastModifiedDate';
        }

        //get qtItem
        String qtItemsql = 'SELECT Quote__c FROM '+ns+'Quote_Item__c WHERE IsDeleted=false and Id=\'' + qiList[0].Id + '\'';
        System.debug(qtItemsql);
        Quote_Item__c qi = database.query(qtItemsql);

        //get qt
        String qtsql = 'SELECT ' + qtFields + ' FROM '+ns+'Quote__c WHERE Id=\'' + qi.Quote__c + '\' LIMIT 1';
        System.debug(qtsql);
        Quote__c t = database.query(qtsql);
        
        QuoteItemsUpdateResult quoteItemsUpdateResult = new QuoteItemsUpdateResult();
        quoteItemsUpdateResult.updateResult = new List<QuoteItemUpdateResult>(); 
        
        if (qiList.size()>200) {
            Database.SaveResult[] res = Database.update(qiList, false);
            System.Debug(res);
                
            Integer i = 0;
            for (Database.SaveResult sr : res) {
                QuoteItemUpdateResult result = new QuoteItemUpdateResult();
                result.id = sr.getId();
                result.success = sr.success;
    
                result.errors = new List<QuoteItemUpdateError>();
                for(Database.Error err : sr.getErrors()) {
                    QuoteItemUpdateError ue = new QuoteItemUpdateError();
                    ue.message = err.getMessage();
                    ue.fields = err.getFields();
                    result.errors.add(ue);
                    result.id = qiList[i].Id;
                }
    
                quoteItemsUpdateResult.updateResult.add(result);
                i++;
            }
                

        } else {
            for(Quote_Item__c qi1 : qiList) {
                Database.SaveResult sr1 = Database.update(qi1, false);
                System.Debug(sr1);
                
                QuoteItemUpdateResult result = new QuoteItemUpdateResult();
                result.id = sr1.getId();
                result.success = sr1.success;
    
                result.errors = new List<QuoteItemUpdateError>();
                for(Database.Error err : sr1.getErrors()) {
                    QuoteItemUpdateError ue = new QuoteItemUpdateError();
                    ue.message = err.getMessage();
                    ue.fields = err.getFields();
                    result.errors.add(ue);
                    result.id = qi1.Id;
                }
    
                quoteItemsUpdateResult.updateResult.add(result);
                    
            }
        }       

        if (!qtItemFields.contains('LastModifiedDate')) {
            qtItemFields += ', LastModifiedDate';
        }

        //get qtItems
        String qtItemssql = 'SELECT ' + qtItemFields + ', Quote__c, IsDeleted FROM '+ns+'Quote_Item__c WHERE IsDeleted=false and '+ns+'Quote__c=\'' + t.Id + '\'';
        System.debug(qtItemssql);
        List<Quote_Item__c> qtItems = database.query(qtItemssql);
System.debug(qtItems);
System.debug(t);

        quoteItemsUpdateResult.quote = t;
        quoteItemsUpdateResult.qtItems = qtItems;
        
        return quoteItemsUpdateResult;
    }    

    public class QuoteItemsUpdateResult {
        public List<QuoteItemUpdateResult> updateResult  { get; set; }
        public Quote__c quote;
        public List<Quote_Item__c> qtItems;        
    }
    
    public class QuoteItemUpdateResult {
        public String id { get; set; }
        public Boolean success  { get; set; }
        public List<QuoteItemUpdateError> errors  { get; set; }
    }

    public class QuoteItemUpdateError {
        public String message { get; set; }
        public List<String> fields { get; set; }
    }
    
    public class QtItemsResponse {
        public QtItemsResponse() {}
        public string typeStr;
        public String qtFields;
        public String qtItemFields;
        public List<Quote_Item__c> itemsStr;
    }        

}