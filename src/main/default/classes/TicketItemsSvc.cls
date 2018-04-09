@RestResource(urlMapping = '/updateTktItem/*')
global with sharing class TicketItemsSvc {

    public static String TicketItemUpdate(string ticketItemUpdateStr) {
        JSONParser parser = JSON.createParser(ticketItemUpdateStr);

        String typeStr = '';
        Ticket_Item__c obj = null;
        String tktFields = '';
        String tktItemFields = '';

        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'typeStr')) {
                parser.nextToken();
                typeStr = parser.getText();
                System.debug(typeStr);
            } else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'objStr')) {
                parser.nextToken();
                obj = (Ticket_Item__c)parser.readValueAs(Ticket_Item__c.class);
                System.debug(obj);
            } else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'tktFields')) {
                parser.nextToken();
                tktFields = parser.getText();
                System.debug(tktFields);
            } else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'tktItemFields')) {
                parser.nextToken();
                tktItemFields = parser.getText();
                System.debug(tktItemFields);
            }
        }

        UpdateTktItemResult resTicketItemUpdate = TicketItemUpdate(obj, typeStr, tktFields, tktItemFields);
        return JSON.serializePretty(resTicketItemUpdate, false);
    }

    @HttpPost
    global static UpdateTktItemResult updateTktItem(string objStr, string typeStr, string tktFields, string tktItemFields) {
        Type objType = Type.forName(typeStr);

        System.debug(objStr);

        sObject obj = (sObject)JSON.deserialize(objStr, objType);

        return TicketItemUpdate(obj, typeStr, tktFields, tktItemFields);
    }

    public static UpdateTktItemResult TicketItemUpdate(sObject obj, string typeStr, string tktFields, string tktItemFields) {
        sObject[] objs = new sObject[]{ obj };
        Database.SaveResult[] res = Database.update(objs, false);

        UpdateTktItemResult results = new UpdateTktItemResult();
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

        if (!tktItemFields.contains('LastModifiedDate')) {
            tktItemFields += ', LastModifiedDate';
        }
        if (!tktFields.contains('LastModifiedDate')) {
            tktFields += ', LastModifiedDate';
        }
        if (!tktItemFields.contains('Ticket__c')) {
            tktItemFields += ', '+ns+'Ticket__c';
        }

        //get tkt id
        String sql = 'SELECT Ticket__c' + ' FROM '+ns+'Ticket_Item__c WHERE Id=\'' + obj.Id + '\' LIMIT 1';
        System.debug(sql);
        Ticket_Item__c ti = database.query(sql);

        //get tkt
        String tktsql = 'SELECT ' + tktFields + ' FROM '+ns+'Ticket__c WHERE Id=\'' + ti.Ticket__c + '\' LIMIT 1';
        System.debug(tktsql);
        Ticket__c t = database.query(tktsql);

        //get tktItem
        String tisql = 'SELECT ' + tktItemFields + ' FROM '+ns+'Ticket_Item__c WHERE Id=\'' + obj.Id + '\'';
        System.debug(tisql);
        ti = database.query(tisql);

        //get tktItem siblings
        String siblingsql = 'SELECT ' + tktItemFields + ' FROM '+ns+'Ticket_Item__c WHERE IsDeleted=false and '+ns+'Parent_Ticket_Item__c = NULL and '+ns+'Ticket__c=\'' + t.Id + '\' AND Id!=\'' + obj.Id + '\'';
        System.debug(siblingsql);
        List<Ticket_Item__c> tktItemSiblings = database.query(siblingsql);

        //get tkt children
        String tiChildrenSql = 'SELECT ' + tktItemFields + ' FROM '+ns+'Ticket_Item__c WHERE IsDeleted=false and '+ns+'Parent_Ticket_Item__c != NULL AND '+ns+'Ticket__c=\'' + t.Id + '\'';
        System.debug(tktsql);
        List<Ticket_Item__c> tiChildren = database.query(tiChildrenSql);

        results.tktItem = ti;
        results.ticket = t;
        results.tktItemChildren = tiChildren;
        results.tktItemSiblings = tktItemSiblings;

        return results;
    }

    global class UpdateTktItemResult {
        public Ticket_Item__c tktItem;
        public Ticket__c ticket;
        public List<Ticket_Item__c> tktItemChildren;
        public List<Ticket_Item__c> tktItemSiblings;

        public String id { get; set; }
        public Boolean success  { get; set; }
        public List<UpdateError> errors  { get; set; }
    }

    public class UpdateError {
        public String message { get; set; }
        public List<String> fields { get; set; }
    }

}
