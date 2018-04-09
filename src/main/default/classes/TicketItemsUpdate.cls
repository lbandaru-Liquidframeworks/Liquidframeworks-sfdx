public class TicketItemsUpdate {
    public static String Process(String processStr) {
        //need updated list, not updated, error messages returned

        JSONParser parser = JSON.createParser(processStr);
        Type resultType = Type.forName('TicketItemsUpdate.TktItemsResponse');
        TicketItemsUpdate.TktItemsResponse readValueAsResults = (TicketItemsUpdate.TktItemsResponse)parser.readValueAs(resultType);

        TicketItemsUpdateResult resTicketItemUpdate = TicketItemsUpdate(readValueAsResults.itemsStr, readValueAsResults.typeStr, readValueAsResults.tktFields, readValueAsResults.tktItemFields);
        System.debug(resTicketItemUpdate);

        return JSON.serializePretty(resTicketItemUpdate, false);
    }

    public static TicketItemsUpdateResult TicketItemsUpdate(List<Ticket_Item__c> tiList, string typeStr, string tktFields, string tktItemFields) {
        String ns = UtilityGetNamespace.CurrentNamespace();

        if (!tktFields.contains('LastModifiedDate')) {
            tktFields += ', LastModifiedDate';
        }

        //get tktItem
        String tktItemsql = 'SELECT Ticket__c FROM '+ns+'Ticket_Item__c WHERE IsDeleted=false and Id=\'' + tiList[0].Id + '\'';
        System.debug(tktItemsql);
        Ticket_Item__c ti = database.query(tktItemsql);

        //get tkt
        String tktsql = 'SELECT ' + tktFields + ' FROM '+ns+'Ticket__c WHERE Id=\'' + ti.Ticket__c + '\' LIMIT 1';
        System.debug(tktsql);
        Ticket__c t = database.query(tktsql);

        TicketItemsUpdateResult ticketItemsUpdateResult = new TicketItemsUpdateResult();
        ticketItemsUpdateResult.updateResult = new List<TicketItemUpdateResult>();

        if (tiList.size()>200) {
            Database.SaveResult[] res = Database.update(tiList, false);
            System.Debug(res);

            Integer i = 0;
            for (Database.SaveResult sr : res) {
                TicketItemUpdateResult result = new TicketItemUpdateResult();
                result.id = sr.getId();
                result.success = sr.success;

                result.errors = new List<TicketItemUpdateError>();
                for(Database.Error err : sr.getErrors()) {
                    TicketItemUpdateError ue = new TicketItemUpdateError();
                    ue.message = err.getMessage();
                    ue.fields = err.getFields();
                    result.errors.add(ue);
                    result.id = tiList[i].Id;
                }

                ticketItemsUpdateResult.updateResult.add(result);
                i++;
            }


        } else {
            for(Ticket_Item__c ti1 : tiList) {
                Database.SaveResult sr1 = Database.update(ti1, false);
                System.Debug(sr1);

                TicketItemUpdateResult result = new TicketItemUpdateResult();
                result.id = sr1.getId();
                result.success = sr1.success;

                result.errors = new List<TicketItemUpdateError>();
                for(Database.Error err : sr1.getErrors()) {
                    TicketItemUpdateError ue = new TicketItemUpdateError();
                    ue.message = err.getMessage();
                    ue.fields = err.getFields();
                    result.errors.add(ue);
                    result.id = ti1.Id;
                }

                ticketItemsUpdateResult.updateResult.add(result);

            }
        }

        //validate tiList list
        String tiSoql = 'SELECT Id FROM '+ns+'Ticket_Item__c WHERE IsDeleted=false and '+ns+'Ticket__c=\'' + ti.Ticket__c + '\'';
        List<Ticket_Item__c> verifiedTiList = (List<Ticket_Item__c>)Database.query(tiSoql);
        System.debug(verifiedTiList);

        if (!tktItemFields.contains('LastModifiedDate')) {
            tktItemFields += ', LastModifiedDate';
        }
        if (!tktItemFields.contains('Ticket__c')) {
            tktItemFields += ', '+ns+'Ticket__c';
        }

        //get tktItems
        String tktItemssql = 'SELECT ' + tktItemFields + ', IsDeleted FROM '+ns+'Ticket_Item__c WHERE IsDeleted=false and '+ns+'Ticket__c=\'' + t.Id + '\'';
        System.debug(tktItemssql);
        List<Ticket_Item__c> tktItems = database.query(tktItemssql);
System.debug(tktItems);
System.debug(t);

        ticketItemsUpdateResult.ticket = t;
        ticketItemsUpdateResult.tktItems = tktItems;

        return ticketItemsUpdateResult;
    }

    public class TicketItemsUpdateResult {
        public List<TicketItemUpdateResult> updateResult  { get; set; }
        public Ticket__c ticket;
        public List<Ticket_Item__c> tktItems;
    }

    public class TicketItemUpdateResult {
        public String id { get; set; }
        public Boolean success  { get; set; }
        public List<TicketItemUpdateError> errors  { get; set; }
    }

    public class TicketItemUpdateError {
        public String message { get; set; }
        public List<String> fields { get; set; }
    }

    public class TktItemsResponse {
        public TktItemsResponse() {}
        public string typeStr;
        public String tktFields;
        public String tktItemFields;
        public List<Ticket_Item__c> itemsStr;
    }

}
