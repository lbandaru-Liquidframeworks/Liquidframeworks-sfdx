public class InvoiceItemHandler
{
    static String invoiceItemKeyPrefix = Invoice_Item__c.sObjectType.getDescribe().keyPrefix;
    static String ticketItemKeyPrefix = Ticket_Item__c.sObjectType.getDescribe().keyPrefix;
    static String pricebookItemKeyPrefix = Price_Book_Item__c.sObjectType.getDescribe().keyPrefix;

    public static String InvoiceItemsFetch(String processStr) {
        JSONParser parser = JSON.createParser(processStr);
        Type resultType = null;
        String invItemId = '';
        String invId = '';
        String invFields = '';
        String invItemFields = '';
        InvItemsFilterResponse filter = null;

        resultType = Type.forName('InvoiceItemHandler.InvItemsResponseWithFilter');
        InvoiceItemHandler.InvItemsResponseWithFilter readValueAsResults1 = (InvoiceItemHandler.InvItemsResponseWithFilter)parser.readValueAs(resultType);
        invItemId = readValueAsResults1.invItemId;
        invId = readValueAsResults1.invId;
        invFields = readValueAsResults1.invFields;
        invItemFields = readValueAsResults1.invItemFields;
        filter = readValueAsResults1.filter;

        InvoiceItemsFetchResult resInvoiceItemFetch = InvoiceItemsFetch(invItemId, invId, invFields, invItemFields, filter);
        System.debug(resInvoiceItemFetch);

        return JSON.serializePretty(resInvoiceItemFetch, false);
    }

    private static string GetInvItemsFilterSoql(InvItemsFilterResponse filter) {
        if (filter == null) return '';

        String ns = UtilityGetNamespace.CurrentNamespace();
        String keyword = filter.keyword;
        String itemType = filter.itemType;
        String itemLimit = filter.itemLimit;
        String itemOffset = filter.itemOffset;
        String sortby = filter.sortby;
        String sortdir = filter.sortdir;

        String invItemssql = '';

        if (keyword != null && keyword != '') {
            invItemssql += ' AND (' +  ns + 'Item_Code__c LIKE \'%' + keyword + '%\' OR ' +  ns + 'Description__c LIKE \'%' + keyword + '%\' OR Name LIKE \'%' + keyword + '%\') ';
        }

        String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
        String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
        String nullsLast = (sb != '') ? 'NULLS LAST' : '';
        invItemssql += sb + ' ' + sd + ' ' + nullsLast;

        String lim = (itemLimit != '' && itemLimit != null ) ? (Integer.valueOf(itemLimit) > 2000) ? '2000' : itemLimit : '2000';
        String off = (itemOffset != '' && itemOffset != null ) ? (Integer.valueOf(itemOffset) > 2000) ? '2000' : itemOffset : '0';
        invItemssql += ' LIMIT ' + lim + ' OFFSET ' + off + ' ';

        return invItemssql;
    }

    public static InvoiceItemsFetchResult InvoiceItemsFetch(String invItemId, String invId, string invFields, string invItemFields, InvItemsFilterResponse filter) {
        String ns = UtilityGetNamespace.CurrentNamespace();
        InvoiceItemsFetchResult invoiceItemsFetchResult = new InvoiceItemsFetchResult();

        String invItemsFilterSoql = GetInvItemsFilterSoql(filter);

        if (!invFields.contains('LastModifiedDate')) {
            invFields += ', LastModifiedDate';
        }

        if (!invItemFields.contains('LastModifiedDate')) {
            invItemFields += ', LastModifiedDate';
        }

        //get inv
        String invsql = 'SELECT ' + invFields + ' FROM '+ns+'Invoice__c WHERE Id=\'' + invId + '\' LIMIT 1';
        Invoice__c inv = database.query(invsql);

        //get invItems
        String invItemssql = 'SELECT ' + invItemFields + ', Invoice__c, IsDeleted FROM '+ns+'Invoice_Item__c WHERE IsDeleted=false and '+ns+'Invoice__c=\'' + invId + '\'';
        invItemssql += invItemsFilterSoql;

        List<Invoice_Item__c> invItems = database.query(invItemssql);

        //get invItem
        Invoice_Item__c invi = null;
        List<Invoice_Item__c> invItemSiblings = null;
        List<Invoice_Item__c> inviChildren = null;
        String siblingsql = 'SELECT ' + invItemFields + ', Invoice__c' + ' FROM '+ns+'Invoice_Item__c WHERE IsDeleted=false and '+ns+'Parent_Invoice_Item__c = NULL and '+ns+'Invoice__c=\'' + inv.Id + '\' ';

        if (invItemId != null) {
          String invisql = 'SELECT ' + invItemFields + ', Invoice__c' + ' FROM '+ns+'Invoice_Item__c WHERE Id=\'' + invItemId + '\'';
          invi = database.query(invisql);

          invoiceItemsFetchResult.invItem = invi;

          siblingsql+= ' AND Id!=\'' + invItemId + '\' ';
        }

        //get invItem siblings
        siblingsql += invItemsFilterSoql;
        invItemSiblings = database.query(siblingsql);

        //get inv children
        String inviChildrenSql = 'SELECT ' + invItemFields + ' FROM '+ns+'Invoice_Item__c WHERE IsDeleted=false and '+ns+'Parent_Invoice_Item__c != NULL AND '+ns+'Invoice__c=\'' + inv.Id + '\'';
        inviChildrenSql += invItemsFilterSoql;
        inviChildren = database.query(inviChildrenSql);

        invoiceItemsFetchResult.invoice = inv;
        invoiceItemsFetchResult.invItemChildren = inviChildren;
        invoiceItemsFetchResult.invItemSiblings = invItemSiblings;
        invoiceItemsFetchResult.invItems = invItems;

        return invoiceItemsFetchResult;
    }

    public static String InvoiceItemsUpdate(String processStr) {
        JSONParser parser = JSON.createParser(processStr);
        Type resultType = Type.forName('InvoiceItemHandler.InvItemsRequest');
        InvoiceItemHandler.InvItemsRequest readValueAsResults = (InvoiceItemHandler.InvItemsRequest)parser.readValueAs(resultType);

        InvoiceItemsUpdateResult resInvoiceItemsUpdate = InvoiceItemsUpdate(readValueAsResults);
        System.debug(resInvoiceItemsUpdate);

        return JSON.serializePretty(resInvoiceItemsUpdate, false);
    }

    public static InvoiceItemsUpdateResult InvoiceItemsUpdate(InvItemsRequest request) {
        List<Invoice_Item__c> inviList = request.inviList;
        string typeStr = request.typeStr;
        string invFields = request.invFields;
        string invItemFields = request.invItemFields;

        String ns = UtilityGetNamespace.CurrentNamespace();

        if (!invFields.contains('LastModifiedDate')) {
            invFields += ', LastModifiedDate';
        }

        //get invItem
        String invItemsql = 'SELECT Invoice__c FROM '+ns+'Invoice_Item__c WHERE IsDeleted=false and Id=\'' + inviList[0].Id + '\'';
        System.debug(invItemsql);
        Invoice_Item__c invi = database.query(invItemsql);

        //get inv
        String invsql = 'SELECT ' + invFields + ' FROM '+ns+'Invoice__c WHERE Id=\'' + invi.Invoice__c + '\' LIMIT 1';
        System.debug(invsql);
        Invoice__c inv = database.query(invsql);

        InvoiceItemsUpdateResult invoiceItemsUpdateResult = new InvoiceItemsUpdateResult();
        invoiceItemsUpdateResult.updateResult = new List<InvoiceItemUpdateResult>();

        if (inviList.size()>200) {
            Database.SaveResult[] res = Database.update(inviList, false);
            System.Debug(res);

            Integer i = 0;
            for (Database.SaveResult sr : res) {
                InvoiceItemUpdateResult result = new InvoiceItemUpdateResult();
                result.id = sr.getId();
                result.success = sr.success;

                result.errors = new List<InvoiceItemUpdateError>();
                for(Database.Error err : sr.getErrors()) {
                    InvoiceItemUpdateError ue = new InvoiceItemUpdateError();
                    ue.message = err.getMessage();
                    ue.fields = err.getFields();
                    result.errors.add(ue);
                    result.id = inviList[i].Id;
                }

                invoiceItemsUpdateResult.updateResult.add(result);
                i++;
            }
        } else {
            for(Invoice_Item__c invi1 : inviList) {
                Database.SaveResult sr1 = Database.update(invi1, false);
                System.Debug(sr1);

                InvoiceItemUpdateResult result = new InvoiceItemUpdateResult();
                result.id = sr1.getId();
                result.success = sr1.success;

                result.errors = new List<InvoiceItemUpdateError>();
                for(Database.Error err : sr1.getErrors()) {
                    InvoiceItemUpdateError ue = new InvoiceItemUpdateError();
                    ue.message = err.getMessage();
                    ue.fields = err.getFields();
                    result.errors.add(ue);
                    result.id = invi1.Id;
                }

                invoiceItemsUpdateResult.updateResult.add(result);

            }
        }

        //validate inviList list
        String tiSoql = 'SELECT Id FROM '+ns+'Invoice_Item__c WHERE IsDeleted=false and '+ns+'Invoice__c=\'' + invi.Invoice__c + '\'';
        List<Invoice_Item__c> verifiedTiList = (List<Invoice_Item__c>)Database.query(tiSoql);
        System.debug(verifiedTiList);

        if (!invItemFields.contains('LastModifiedDate')) {
            invItemFields += ', LastModifiedDate';
        }

        //get invItems
        String invItemssql = 'SELECT ' + invItemFields + ', Invoice__c, IsDeleted FROM '+ns+'Invoice_Item__c WHERE IsDeleted=false and '+ns+'Invoice__c=\'' + inv.Id + '\'';
        System.debug(invItemssql);
        List<Invoice_Item__c> invItems = database.query(invItemssql);

        invoiceItemsUpdateResult.invoice = inv;
        invoiceItemsUpdateResult.invItems = invItems;

        return invoiceItemsUpdateResult;
    }

    public static String GetAvailableTicketsSearchFilter() {
      String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
      String searchFieldSetName = fxNamespacePrefix+'IIBSearchFields';

      String jobObjName = fxNamespacePrefix+'Job__c';
      List<ItemBuilderHelper.SearchFieldResult> jobSearchFields = new List<ItemBuilderHelper.SearchFieldResult>();
      List<Schema.FieldSetMember> jobFields = new List<Schema.FieldSetMember>();
      Schema.FieldSet jobFieldSet = MetadataHelper.GetFieldSet(jobObjName, searchFieldSetName);
System.Debug(jobFieldSet);
      if (jobFieldSet != null) jobFields = jobFieldSet.getFields();

      SObjectType jobObjType = Schema.getGlobalDescribe().get(jobObjName);
      Schema.DescribeSObjectResult jobObj = jobObjType.getDescribe();
      Map<String,Schema.SObjectField> jobFieldsMap = jobObj.fields.getMap();
      Schema.DescribeFieldResult jobStatusFieldInfo = jobFieldsMap.get(fxNamespacePrefix+'Status__c').getDescribe();

      Boolean found = false;
      if (jobFields != null) {
        jobSearchFields = ItemBuilderHelper.ProcessSearchFieldSet(jobObjName, searchFieldSetName);

        //look for status in the filter fieldSet. If not there is needs to be added.

        String jobStatusFieldInfoName = jobStatusFieldInfo.getName();
        for(Schema.FieldSetMember field: jobFields) {
          if (field.getFieldPath() == jobStatusFieldInfoName) {
            found = true;
            break;
          }
        }
      }
      if (!found) {
        ItemBuilderHelper.SearchFieldResult searchField = new ItemBuilderHelper.SearchFieldResult();
        if(jobStatusFieldInfo.getReferenceTo().size()>0) {
          Schema.SObjectType reference = jobStatusFieldInfo.getReferenceTo()[0];
          Schema.DescribeSObjectResult fieldObjDescribe = reference.getDescribe();
          searchField.keyPrefix = fieldObjDescribe.getKeyPrefix();
          searchField.ApiName = fieldObjDescribe.getName();
          searchField.label = fieldObjDescribe.getLabel();
          searchField.type = Schema.DisplayType.Reference;
        }

        jobSearchFields.add(searchField);
      }

      GetAvailableTicketsSearchFilterResult result = new GetAvailableTicketsSearchFilterResult();
      result.ticketSearchFields = ItemBuilderHelper.ProcessSearchFieldSet(fxNamespacePrefix+'Ticket__c', searchFieldSetName);
      result.ticketItemSearchFields = ItemBuilderHelper.ProcessSearchFieldSet(fxNamespacePrefix+'Ticket_Item__c', searchFieldSetName);
      result.jobSearchFields = jobSearchFields;
      result.keyPrefixesForObjects = ItemBuilderHelper.getKeyPrefixesForObjects();

      return JSON.serializePretty(result, false);
    }

    public static String GetAvailableTicketsPBISearchFilter() {
      String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
      String objName = fxNamespacePrefix+'Price_Book_Item__c';
      String searchFieldSetName = fxNamespacePrefix+'IIBSearchFields';
      List<ItemBuilderHelper.SearchFieldResult> pbiSearchFields = new List<ItemBuilderHelper.SearchFieldResult>();
      List<Schema.FieldSetMember> fields = new List<Schema.FieldSetMember>();

      Schema.FieldSet fieldSet = MetadataHelper.GetFieldSet(objName, searchFieldSetName);
System.Debug(fieldSet);
      if (fieldSet != null) fields = fieldSet.getFields();

      SObjectType objType = Schema.getGlobalDescribe().get(objName);
      Schema.DescribeSObjectResult obj = objType.getDescribe();
      Map<String,Schema.SObjectField> fieldsMap = obj.fields.getMap();
      Schema.DescribeFieldResult priceBookFieldInfo = fieldsMap.get(fxNamespacePrefix+'Price_Book__c').getDescribe();

      Boolean found = false;
      if (fields != null) {
        pbiSearchFields = ItemBuilderHelper.ProcessSearchFieldSet(objName, searchFieldSetName);

        //look for pricebook in the filter fieldSet. If not there is needs to be added.

        String priceBookFieldInfoName = priceBookFieldInfo.getName();
        for(Schema.FieldSetMember field: fields) {
          if (field.getFieldPath() == priceBookFieldInfoName) {
            found = true;
            break;
          }
        }
      }
      if (!found) {
        ItemBuilderHelper.SearchFieldResult searchField = new ItemBuilderHelper.SearchFieldResult();
        if(priceBookFieldInfo.getReferenceTo().size()>0) {
          Schema.SObjectType reference = priceBookFieldInfo.getReferenceTo()[0];
          Schema.DescribeSObjectResult fieldObjDescribe = reference.getDescribe();
          searchField.keyPrefix = fieldObjDescribe.getKeyPrefix();
          searchField.ApiName = fieldObjDescribe.getName();
          searchField.label = fieldObjDescribe.getLabel();
          searchField.type = Schema.DisplayType.Reference;
        }

        pbiSearchFields.add(searchField);
      }

      GetAvailableTicketsPBISearchFilterResult result = new GetAvailableTicketsPBISearchFilterResult();
      result.pbiSearchFields = pbiSearchFields;
      result.keyPrefixesForObjects = ItemBuilderHelper.getKeyPrefixesForObjects();

      return JSON.serializePretty(result, false);
    }

    public static String CreateInvoiceItems(String processStr) {
        JSONParser parser = JSON.createParser(processStr);
        Type resultType = Type.forName('InvoiceItemHandler.CreateInvoiceItemsRequest');
        InvoiceItemHandler.CreateInvoiceItemsRequest readValueAsResults = (InvoiceItemHandler.CreateInvoiceItemsRequest)parser.readValueAs(resultType);

        List<Invoice_Item__c> result = CreateInvoiceItems(readValueAsResults.invId, readValueAsResults.sourceIds, readValueAsResults.nextSeqNumber, readValueAsResults.parentInvItemId);

        return JSON.serializePretty(result, false);
    }

    public static String GetAvailablePBIsForInvoice(String processStr) {
        JSONParser parser = JSON.createParser(processStr);
        Type resultType = Type.forName('InvoiceItemHandler.GetAvailablePBIsForInvoiceRequest');
        InvoiceItemHandler.GetAvailablePBIsForInvoiceRequest readValueAsResults = (InvoiceItemHandler.GetAvailablePBIsForInvoiceRequest)parser.readValueAs(resultType);

        GetAvailablePBIsForInvoiceResult result = GetAvailablePBIsForInvoice(readValueAsResults);

        return JSON.serializePretty(result, false);
    }

    public static String GetAvailableTicketsForInvoice(String processStr) {
        JSONParser parser = JSON.createParser(processStr);
        Type resultType = Type.forName('InvoiceItemHandler.GetAvailableTicketsForInvoiceRequest');
        InvoiceItemHandler.GetAvailableTicketsForInvoiceRequest readValueAsResults = (InvoiceItemHandler.GetAvailableTicketsForInvoiceRequest)parser.readValueAs(resultType);

        GetAvailableTicketsForInvoiceResult result = GetAvailableTicketsForInvoice(readValueAsResults);

        return JSON.serializePretty(result, false);
    }

    public static String GetSelectedTicketsForInvoice(String processStr) {
        JSONParser parser = JSON.createParser(processStr);
        Type resultType = Type.forName('InvoiceItemHandler.GetSelectedTicketsForInvoiceRequest');
        InvoiceItemHandler.GetSelectedTicketsForInvoiceRequest readValueAsResults = (InvoiceItemHandler.GetSelectedTicketsForInvoiceRequest)parser.readValueAs(resultType);

        GetSelectedTicketsForInvoiceResult result = GetSelectedTicketsForInvoice(readValueAsResults);

        return JSON.serializePretty(result, false);
    }

    public static GetSelectedTicketsForInvoiceResult GetSelectedTicketsForInvoice(GetSelectedTicketsForInvoiceRequest request) {
        String invoiceId = request.invoiceId;
        String sortby = request.sortby;
        String sortdir = request.sortdir;
        String tktFields = request.tktFields;
        String tktItemFields = request.tktItemFields;
        String invoiceItemParentTktItemId = request.invoiceItemParentTktItemId;

        String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
        GetSelectedTicketsForInvoiceResult result = new GetSelectedTicketsForInvoiceResult();

        if(!tktItemFields.contains('Ticket__c')) {
          tktItemFields += ', '+fxNamespacePrefix+'Ticket__c';
        }
        if(!tktItemFields.contains('Parent_Ticket_Item__c')) {
          tktItemFields += ', '+fxNamespacePrefix+'Parent_Ticket_Item__c';
        }
        if(!tktItemFields.contains('Name')) {
          tktItemFields += ', '+'Name';
        }
        if(!tktItemFields.contains('Item_Code__c')) {
          tktItemFields += ', '+fxNamespacePrefix+'Item_Code__c';
        }
        if(!tktItemFields.contains('Price_Book_Item__r.Name')) {
          tktItemFields += ', '+fxNamespacePrefix+'Price_Book_Item__r.Name';
        }
        if(!tktItemFields.contains('Description__c')) {
          tktItemFields += ', '+fxNamespacePrefix+'Description__c';
        }
        if(!tktItemFields.contains('PBI_Requires_Parent_Item__c')) {
          tktItemFields += ', '+fxNamespacePrefix+'PBI_Requires_Parent_Item__c';
        }

        Set<Id> invoicedTktIds = new Set<Id>();
        Set<Id> invoicedTktItemIds = new Set<Id>();
        for(Invoice_Item__c ii : [SELECT Id, Ticket_Item__c, Ticket_Item__r.Ticket__c FROM Invoice_Item__c WHERE Invoice__c=:invoiceId]) {
            if (!invoicedTktIds.contains(ii.Ticket_Item__r.Ticket__c)) {
                invoicedTktIds.add(ii.Ticket_Item__r.Ticket__c);
            }
            if (!invoicedTktItemIds.contains(ii.Ticket_Item__c)) {
                invoicedTktItemIds.add(ii.Ticket_Item__c);
            }
        }
        String commandText = 'SELECT ' + tktFields + ' FROM ' + fxNamespacePrefix + 'Ticket__c ';
        commandText += ' WHERE IsDeleted=false ';
        commandText += ' AND Id IN :invoicedTktIds ';

        String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
        String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
        String nullsLast = (sb != '') ? 'NULLS LAST' : '';
        commandText += sb + ' ' + sd + ' ' + nullsLast;

        result.selectedTkts = Database.query(commandText);

        commandText = 'SELECT ' + tktItemFields + ' FROM ' + fxNamespacePrefix + 'Ticket_Item__c ';
        commandText += ' WHERE IsDeleted=false ';
        commandText += ' AND Id IN :invoicedTktItemIds ';
        if (invoiceItemParentTktItemId != null && invoiceItemParentTktItemId != '') {
            commandText += ' AND Id != :invoiceItemParentTktItemId ';
        }

        result.selectedTktItems = Database.query(commandText);

        commandText = 'SELECT '+tktItemFields+' FROM ' + fxNamespacePrefix + 'Ticket_Item__c WHERE ' + fxNamespacePrefix + 'Ticket__c IN :invoicedTktIds AND ' + fxNamespacePrefix + 'Parent_Ticket_Item__c = NULL';
        if (invoiceItemParentTktItemId != null && invoiceItemParentTktItemId != '') {
            commandText += ' AND Id != :invoiceItemParentTktItemId ';
        } else {
            commandText += ' AND (' + fxNamespacePrefix + 'PBI_Requires_Parent_Item__c = null OR ' + fxNamespacePrefix + 'PBI_Requires_Parent_Item__c = false) ';
        }
        result.parentTicketItems = Database.query(commandText);

        commandText = 'SELECT '+tktItemFields+' FROM ' + fxNamespacePrefix + 'Ticket_Item__c WHERE ' + fxNamespacePrefix + 'Ticket__c IN :invoicedTktIds AND ' + fxNamespacePrefix + 'Parent_Ticket_Item__c != NULL';
        if (invoiceItemParentTktItemId != null && invoiceItemParentTktItemId != '') {
            commandText += ' AND Id != :invoiceItemParentTktItemId ';
        }
        result.childTicketItems = Database.query(commandText);

        return result;
    }

    public static GetAvailableTicketsForInvoiceResult GetAvailableTicketsForInvoice(GetAvailableTicketsForInvoiceRequest request) {
      String invoiceId = request.invoiceId;
      String showItemsAlreadyOnTheInvoice = request.showItemsAlreadyOnTheInvoice;
      String itemLimit = request.itemLimit;
      String itemOffset = request.itemOffset;
      String sortby = request.sortby;
      String sortdir = request.sortdir;
      String tktFields = request.tktFields;
      String tktItemFields = request.tktItemFields;
      String invoiceItemParentTktItemId = request.invoiceItemParentTktItemId;
      String showItemsAlreadyInvoiced = request.showItemsAlreadyInvoiced;

      String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
      GetAvailableTicketsForInvoiceResult result = new GetAvailableTicketsForInvoiceResult();

      if(!tktItemFields.contains('Ticket__c')) {
        tktItemFields += ', '+fxNamespacePrefix+'Ticket__c';
      }
      if(!tktItemFields.contains('Parent_Ticket_Item__c')) {
        tktItemFields += ', '+fxNamespacePrefix+'Parent_Ticket_Item__c';
      }
      if(!tktItemFields.contains('Name')) {
        tktItemFields += ', '+'Name';
      }
      if(!tktItemFields.contains('Item_Code__c')) {
        tktItemFields += ', '+fxNamespacePrefix+'Item_Code__c';
      }
      if(!tktItemFields.contains('Price_Book_Item__r.Name')) {
        tktItemFields += ', '+fxNamespacePrefix+'Price_Book_Item__r.Name';
      }
      if(!tktItemFields.contains('Description__c')) {
        tktItemFields += ', '+fxNamespacePrefix+'Description__c';
      }
      if(!tktItemFields.contains('PBI_Requires_Parent_Item__c')) {
        tktItemFields += ', '+fxNamespacePrefix+'PBI_Requires_Parent_Item__c';
      }

      Invoice__c invoice = [SELECT Id, Price_Book__c FROM Invoice__c WHERE Id=:invoiceId LIMIT 1];

      Set<Id> invoicedTktIds = new Set<Id>();
      Set<Id> invoicedTktItemIds = new Set<Id>();

      for(Invoice_Item__c ii : [SELECT Id, Ticket_Item__c, Ticket_Item__r.Ticket__c FROM Invoice_Item__c WHERE Invoice__c=:invoiceId]) {
        if (!invoicedTktIds.contains(ii.Ticket_Item__r.Ticket__c)) {
            invoicedTktIds.add(ii.Ticket_Item__r.Ticket__c);
        }
        if (!invoicedTktItemIds.contains(ii.Ticket_Item__c)) {
            invoicedTktItemIds.add(ii.Ticket_Item__c);
        }
      }

      String commandText = 'SELECT ' + tktFields + ' FROM ' + fxNamespacePrefix + 'Ticket__c ';
      commandText += ' WHERE IsDeleted=false ';
      commandText += ' AND Id IN :invoicedTktIds ';

      result.selectedTkts = Database.query(commandText);

      commandText = 'SELECT ' + tktItemFields + ' FROM ' + fxNamespacePrefix + 'Ticket_Item__c ';
      commandText += ' WHERE IsDeleted=false ';
      commandText += ' AND Id IN :invoicedTktItemIds ';

      result.selectedTktItems = Database.query(commandText);

      commandText = 'SELECT ' + tktFields + ' FROM ' + fxNamespacePrefix + 'Ticket__c ';
      commandText += ' WHERE IsDeleted=false ';
      //commandText += ' AND ' + fxNamespacePrefix + 'Job__r.Price_Book__c = \''+invoice.Price_Book__c+'\'';

      if (showItemsAlreadyInvoiced != 'true') {
          //filter items that are on any invoice
          commandText += ' AND Id IN (SELECT ' + fxNamespacePrefix + 'Ticket__c FROM ' + fxNamespacePrefix + 'Ticket_Item__c WHERE IsDeleted=false AND ' + fxNamespacePrefix + 'Invoice_Item__c = NULL) ';
      }

      if (showItemsAlreadyOnTheInvoice == 'false') {
          if (invoicedtktIds.size() > 0) {
              commandText += ' AND Id not in :invoicedTktIds ';
          }
      }

      if (invoiceItemParentTktItemId != null && invoiceItemParentTktItemId != '') {
          commandText += ' AND Id != :invoiceItemParentTktItemId ';
      }

      commandText += ItemBuilderHelper.GetFilterSoql(request.availableticketJobfilters, fxNamespacePrefix+'Job__r.');
      commandText += ItemBuilderHelper.GetFilterSoql(request.availableticketTicketfilters, '');

      String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
      String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
      String nullsLast = (sb != '') ? 'NULLS LAST' : '';
      commandText += sb + ' ' + sd + ' ' + nullsLast;

      String lim = (itemLimit != '' ) ? (Integer.valueOf(itemLimit) > 1000) ? '1000' : itemLimit : '1000';
      String off = (itemOffset != '' ) ? (Integer.valueOf(itemOffset) > 1000) ? '1000' : itemOffset : '0';
      commandText += ' LIMIT ' + lim + ' OFFSET ' + off + ' ';

      result.soql = commandText;

      result.availableTickets = Database.query(commandText);
System.debug(result.availableTickets.size());

      Set<Id> availableTktIds = new Map<Id, Ticket__c>(result.availableTickets).keySet();

      String ticketItemFilterSoql = ItemBuilderHelper.GetFilterSoql(request.availableticketTicketItemfilters, '');
      commandText = 'SELECT '+tktItemFields+' FROM ' + fxNamespacePrefix + 'Ticket_Item__c WHERE ' + fxNamespacePrefix + 'Ticket__c IN :availableTktIds AND ' + fxNamespacePrefix + 'Parent_Ticket_Item__c = NULL';
      commandText += ticketItemFilterSoql;

      if (invoiceItemParentTktItemId != null && invoiceItemParentTktItemId != '') {
          commandText += ' AND Id != :invoiceItemParentTktItemId ';
      } else {
          commandText += ' AND (' + fxNamespacePrefix + 'PBI_Requires_Parent_Item__c = null OR ' + fxNamespacePrefix + 'PBI_Requires_Parent_Item__c = false) ';
      }

      if (showItemsAlreadyInvoiced != 'true') {
          //filter items that are on any invoice
          commandText += ' AND (' + fxNamespacePrefix + 'Invoice_Item__c = NULL OR ' + fxNamespacePrefix + 'Invoice_Item__r.' + fxNamespacePrefix + 'Invoice__c = :invoiceId) ';
      }

      result.parentTicketItems = Database.query(commandText);

      commandText = 'SELECT '+tktItemFields+' FROM ' + fxNamespacePrefix + 'Ticket_Item__c WHERE ' + fxNamespacePrefix + 'Ticket__c IN :availableTktIds AND ' + fxNamespacePrefix + 'Parent_Ticket_Item__c != NULL';
      commandText += ticketItemFilterSoql;

      if (invoiceItemParentTktItemId != null && invoiceItemParentTktItemId != '') {
          commandText += ' AND Id != :invoiceItemParentTktItemId ';
      }

      if (showItemsAlreadyInvoiced != 'true') {
          //filter items that are on any invoice
          commandText += ' AND (' + fxNamespacePrefix + 'Invoice_Item__c = NULL OR ' + fxNamespacePrefix + 'Invoice_Item__r.' + fxNamespacePrefix + 'Invoice__c = :invoiceId) ';
      }

      result.childTicketItems = Database.query(commandText);

      return result;
    }

    public static GetAvailablePBIsForInvoiceResult GetAvailablePBIsForInvoice(GetAvailablePBIsForInvoiceRequest request) {
        String invoiceId = request.invoiceId;
        String showItemsAlreadyOnTheInvoice = request.showItemsAlreadyOnTheInvoice;
        String itemLimit = request.itemLimit;
        String itemOffset = request.itemOffset;
        String sortby = request.sortby;
        String sortdir = request.sortdir;
        String pbiFields = request.pbiFields;
        String invoiceItemParentPBIId = request.invoiceItemParentPBIId;

        String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
        GetAvailablePBIsForInvoiceResult result = new GetAvailablePBIsForInvoiceResult();

        if(!pbiFields.contains('Price_Book__c')) {
          pbiFields += ', '+fxNamespacePrefix+'Price_Book__c';
        }
        if(!pbiFields.contains('Requires_Parent_Item__c')) {
          pbiFields += ', '+fxNamespacePrefix+'Requires_Parent_Item__c';
        }
        if(!pbiFields.contains('Parent_Price_Book_Item__c')) {
          pbiFields += ', '+fxNamespacePrefix+'Parent_Price_Book_Item__c';
        }
        if(!pbiFields.contains('Name')) {
          pbiFields += ', '+'Name';
        }
        if(!pbiFields.contains('Catalog_Item_Code__c')) {
          pbiFields += ', '+fxNamespacePrefix+'Catalog_Item_Code__c';
        }
        if(!pbiFields.contains('Description_Override__c')) {
          pbiFields += ', '+fxNamespacePrefix+'Description_Override__c';
        }
        if(!pbiFields.contains('Catalog_Description__c')) {
          pbiFields += ', '+fxNamespacePrefix+'Catalog_Description__c';
        }

        Set<Id> invoicedPBIIds = new Set<Id>();

        for(Invoice_Item__c ii : [SELECT Id, Price_Book_Item__c FROM Invoice_Item__c WHERE Invoice__c=:invoiceId]) {
          if (!invoicedPBIIds.contains(ii.Price_Book_Item__c)) {
              invoicedPBIIds.add(ii.Price_Book_Item__c);
          }
        }

        String commandText = 'SELECT ' + pbiFields + ' FROM ' + fxNamespacePrefix + 'Price_Book_Item__c ';
        commandText += ' WHERE IsDeleted=false ';
        commandText += ' AND Id IN :invoicedPBIIds ';

        result.selectedPBIs = Database.query(commandText);

        commandText = 'SELECT ' + pbiFields + ' FROM ' + fxNamespacePrefix + 'Price_Book_Item__c ';
        commandText += ' WHERE IsDeleted=false ';
        commandText += ' AND ' + fxNamespacePrefix + 'Parent_Price_Book_Item__c = NULL ';

        if (showItemsAlreadyOnTheInvoice == 'false') {
            if (invoicedPBIIds.size() > 0) {
                commandText += ' AND Id not in :invoicedPBIIds ';
            }
        }

        if (invoiceItemParentPBIId != null && invoiceItemParentPBIId != '') {
            commandText += ' AND Id != :invoiceItemParentPBIId ';
        }

        commandText += ItemBuilderHelper.GetFilterSoql(request.availableticketPBIfilters, '');

        String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
        String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
        String nullsLast = (sb != '') ? 'NULLS LAST' : '';
        commandText += sb + ' ' + sd + ' ' + nullsLast;

        String lim = (itemLimit != '' ) ? (Integer.valueOf(itemLimit) > 2000) ? '2000' : itemLimit : '2000';
        String off = (itemOffset != '' ) ? (Integer.valueOf(itemOffset) > 2000) ? '2000' : itemOffset : '0';
        commandText += ' LIMIT ' + lim + ' OFFSET ' + off + ' ';

        result.soql = commandText;

        result.availablePBIs = Database.query(commandText);

        Set<Id> availablePBIIds = new Map<Id, Price_Book_Item__c>(result.availablePBIs).keySet();

        commandText = 'SELECT '+pbiFields+' FROM ' + fxNamespacePrefix + 'Price_Book_Item__c WHERE ' + fxNamespacePrefix + 'Parent_Price_Book_Item__c in :availablePBIIds';

        if (invoiceItemParentPBIId != null && invoiceItemParentPBIId != '') {
            commandText += ' AND Id != :invoiceItemParentPBIId ';
        }

        result.childPBIs = Database.query(commandText);

        return result;
    }

    public static List<Invoice_Item__c> CreateInvoiceItems(Id invId, List<Id> sourceIds, Decimal nextSeqNumber, String invoiceItemParentId)
    {
        if(sourceIds.isEmpty()) return null;
        Schema.DescribeSObjectResult rInvoiceItem = Invoice_Item__c.sObjectType.getDescribe();
        if(!rInvoiceItem.isAccessible() || !rInvoiceItem.isCreateable()) {
            return null;
        }

        Invoice__c invoice = [SELECT Id, Price_Book__c FROM Invoice__c WHERE Id=:invId];
        Price_Book__c pricebook = [SELECT Id, AddTktItemsByPBSeqNum__c FROM Price_Book__c WHERE Id=:invoice.Price_Book__c ];

        String itemId = sourceIds.get(0);
        List<Invoice_Item__c> newItems = null;
        List<Invoice_Item__c> rootItems = null;

        try
        {
          if(itemId.startsWith(ticketItemKeyPrefix)) {
              List<Ticket_Item__c> parentTktItems = [SELECT Id FROM Ticket_Item__c WHERE Id IN :sourceIds AND Parent_Ticket_Item__c = null ];
              Map<Id, Ticket_Item__c> parentTktItemsMap = new Map<Id, Ticket_Item__c>(parentTktItems);

              List<Ticket_Item__c> sourceTktItems = [SELECT Id FROM Ticket_Item__c WHERE Id IN :sourceIds];
              Set<Id> sourceTktItemIds = new Map<Id, Ticket_Item__c>(sourceTktItems).keySet();

              rootItems =  CreateInvoiceItemWithTicketItem(invId, sourceTktItemIds, null, invoiceItemParentId);
              insert rootItems;

              List<Id> tktItemToUpdateIds = new List<Id>();
              for(Invoice_Item__c ii : rootItems) {
                tktItemToUpdateIds.add(ii.Ticket_Item__c);
              }
              List<Ticket_Item__c> tktItemsToUpdate = [SELECT Id, Invoice_Item__c FROM Ticket_Item__c WHERE Id IN :sourceTktItemIds];
              Map<Id, Ticket_Item__c> tktItemsToUpdateMap = new Map<Id, Ticket_Item__c>(tktItemsToUpdate);
              for(Invoice_Item__c ii : rootItems) {
                if (tktItemsToUpdateMap.containsKey(ii.Ticket_Item__c)) {
                  Ticket_Item__c ti = tktItemsToUpdateMap.get(ii.Ticket_Item__c);
                  ti.Invoice_Item__c = ii.Id;
                }
              }
              update tktItemsToUpdate;

              Map<Id, Invoice_Item__c> invItemToParentTktItemMap = new Map<Id, Invoice_Item__c>();
              for(Invoice_Item__c ii : [SELECT Id, Parent_Invoice_Item__c, Ticket_Item__c FROM Invoice_Item__c WHERE Id IN :rootItems AND Ticket_Item__r.Parent_Ticket_Item__c = null]) {
                if (!invItemToParentTktItemMap.containsKey(ii.Ticket_Item__c)) {
                  invItemToParentTktItemMap.put(ii.Ticket_Item__c, ii);
                }
              }

              List<Invoice_Item__c> invItemsToUpdate = new List<Invoice_Item__c>();
              for(Invoice_Item__c ii : [SELECT Id, Parent_Invoice_Item__c, Ticket_Item__r.Parent_Ticket_Item__c FROM Invoice_Item__c WHERE Id IN :rootItems AND Ticket_Item__r.Parent_Ticket_Item__c != null]) {
                if (parentTktItemsMap.containsKey(ii.Ticket_Item__r.Parent_Ticket_Item__c)) {
                  if (invItemToParentTktItemMap.containsKey(ii.Ticket_Item__r.Parent_Ticket_Item__c)) {
                    Invoice_Item__c parentii = invItemToParentTktItemMap.get(ii.Ticket_Item__r.Parent_Ticket_Item__c);
                    ii.Parent_Invoice_Item__c = parentii.Id;

                    invItemsToUpdate.add(ii);
                  }
                }
              }

              update invItemsToUpdate;

          } else if(itemId.startsWith(pricebookItemKeyPrefix)) {
              List<Price_Book_Item__c> parentPBItems = [SELECT Id FROM Price_Book_Item__c WHERE Id IN :sourceIds AND Parent_Price_Book_Item__c = null ];
              Map<Id, Price_Book_Item__c> parentPBItemsMap = new Map<Id, Price_Book_Item__c>(parentPBItems);

              List<Price_Book_Item__c> sourcePBItems = [SELECT Id FROM Price_Book_Item__c WHERE Id IN :sourceIds];
              Map<Id, Price_Book_Item__c> sourcePBItemsMap = new Map<Id, Price_Book_Item__c>(sourcePBItems);
              List<Id> sourcePBItemIds = new List<Id>();
              for(Id sourceId :  sourceIds) {
                if(sourcePBItemsMap.containsKey(sourceId)) {
                  sourcePBItemIds.add(sourceId);
                }
              }

              rootItems =  CreateInvoiceItemWithPBItem(invId, sourcePBItemIds, null, invoiceItemParentId);
              insert rootItems;

              Map<Id, Invoice_Item__c> invItemToParentPBItemMap = new Map<Id, Invoice_Item__c>();
              for(Invoice_Item__c invi : [SELECT Id, Price_Book_Item__c, Parent_Invoice_Item__c FROM Invoice_Item__c WHERE Id IN :rootItems AND Price_Book_Item__r.Parent_Price_Book_Item__c = null]) {
                if (!invItemToParentPBItemMap.containsKey(invi.Price_Book_Item__c)) {
                  invItemToParentPBItemMap.put(invi.Price_Book_Item__c, invi);
                }
              }

              List<Invoice_Item__c> invItemsToUpdate = new List<Invoice_Item__c>();
              for(Invoice_Item__c invi : [SELECT Id, Parent_Invoice_Item__c, Price_Book_Item__r.Parent_Price_Book_Item__c FROM Invoice_Item__c WHERE Id IN :rootItems AND Price_Book_Item__r.Parent_Price_Book_Item__c != null]) {
                if (parentPBItemsMap.containsKey(invi.Price_Book_Item__r.Parent_Price_Book_Item__c)) {
                  if (invItemToParentPBItemMap.containsKey(invi.Price_Book_Item__r.Parent_Price_Book_Item__c)) {
                    Invoice_Item__c parentinvi = invItemToParentPBItemMap.get(invi.Price_Book_Item__r.Parent_Price_Book_Item__c);
                    invi.Parent_Invoice_Item__c = parentinvi.Id;

                    invItemsToUpdate.add(invi);
                  }
                }
              }

              update invItemsToUpdate;
          }

          if(rootItems == null || rootItems.isEmpty()) return null;

          if (!pricebook.AddTktItemsByPBSeqNum__c) {
            ApplySequenceNumber(rootItems, nextSeqNumber);
            update rootItems;
          }

          Map<Id, Invoice_Item__c> newItemsMap = new Map<Id, Invoice_Item__c>(rootItems);
          Set<Id> invItemIds = newItemsMap.keySet();

          List<String> fields = new List<String>(Schema.sObjectType.Invoice_Item__c.fields.getMap().keySet());
          String fieldsStr = String.join(fields, ',');

          String ns = StringUtility.FXNamespace();
          String inviSoql = String.format('SELECT {0} FROM {1} WHERE Id IN :invItemIds', new String[]{fieldsStr, ns+'Invoice_Item__c'});
          List<Invoice_Item__c> invItems = (List<Invoice_Item__c>)Database.query(inviSoql);

          return invItems;
        }
        catch (Exception ex)
        {
            throw ex;
        }
        finally
        {
            //RuleEngineCore.RuleEngineInProgress = flagValue;
        }
    }

    static List<Invoice_Item__c> CreateInvoiceItemWithPBItem(Id invId, List<Id> sourceItemIds, List<Invoice_Item__c> parentInvItems, String invoiceItemParentId)
    {
        List<Invoice_Item__c> newItems = new List<Invoice_Item__c>();
        //for setting up InvoiceItem parent/child relationship with PBItem parent/child info
        Map<Id, Invoice_Item__c> pbItemToInvItemLookup = new Map<Id, Invoice_Item__c>();
        if(parentInvItems != null) {
          for(Invoice_Item__c parentInvItem: parentInvItems) {
            pbItemToInvItemLookup.put(parentInvItem.Price_Book_Item__c, parentInvItem);
          }
        }

        String ns = UtilityGetNamespace.CurrentNamespace();

        Map<String, Id> rtLookup = GetInvoiceItemRecordTypeLookup();

        Set<String> pbItemFields = Price_Book_Item__c.sObjectType.getDescribe().fields.getMap().keySet();
        Set<String> pbItemQueryFields = new Set<String>();
        pbItemQueryFields.addAll(pbItemFields);
        pbItemQueryFields.add('RecordType.DeveloperName');
        pbItemQueryFields.add('RecordType.Name');

        String soql = String.format('SELECT {1} FROM {0}Price_Book_Item__c WHERE IsDeleted=false AND (Id IN :sourceItemIds OR {0}Parent_Price_Book_Item__c IN :sourceItemIds) ORDER BY {0}Parent_Price_Book_Item__c NULLS FIRST',
            new String[]{ns, String.join(new List<String>(pbItemQueryFields), ',')});

        List<Price_Book_Item__c> sources = (List<Price_Book_Item__c>)Database.query(soql);
        Map<Id, Price_Book_Item__c> sourcesLookup = new Map<Id, Price_Book_Item__c>(sources);

        Map<String, String> invItemToPBItemFieldMapping =  GetInvoiceItemToPBItemFieldMapping(ns.toLowercase(), pbItemFields);

        SobjectType invItemType = Invoice_Item__c.SobjectType;

        for(Id sourceItemId: sourceItemIds)
        {
            Price_Book_Item__c obj = sourcesLookup.get(sourceItemId);
            Id inviRecordType = rtLookup.containsKey(obj.RecordType.DeveloperName)? rtLookup.get(obj.RecordType.DeveloperName) : null;
            Invoice_Item__c invi = (Invoice_Item__c)invItemType.newSObject(inviRecordType, true);
            for(String f: invItemToPBItemFieldMapping.keySet())
            {
                invi.put(f, obj.get(invItemToPBItemFieldMapping.get(f)));
            }
            invi.Invoice__c = invId;
            invi.Price_Book_Item__c = obj.Id;
            invi.Sequence_Number__c = obj.Sequence_Number__c;

            //field name exceptions
            if(String.IsEmpty(obj.Description_Override__c)) {
              if(!String.IsEmpty(obj.Catalog_Description__c)) {
                invi.Description__c = obj.Catalog_Description__c;
              }
            } else {
              invi.Description__c = obj.Description_Override__c;
            }
            if(!String.IsEmpty(obj.Catalog_Item_Code__c)) {
              invi.Item_Code__c = obj.Catalog_Item_Code__c;
            }
            invi.Qty__c = obj.Default_Quantity__c;

            if (!String.IsEmpty(invoiceItemParentId)) {
              invi.Parent_Invoice_Item__c = invoiceItemParentId;
            } else if (pbItemToInvItemLookup.containsKey(obj.Parent_Price_Book_Item__c)) {
              invi.Parent_Invoice_Item__c = pbItemToInvItemLookup.get(obj.Parent_Price_Book_Item__c).Id;
            }
            newItems.add(invi);
        }
        return newItems;
    }

    static List<Invoice_Item__c> CreateInvoiceItemWithTicketItem(Id invId, Set<Id> sourceItemIds, List<Invoice_Item__c> parentInvItems, String invoiceItemParentId)
    {

        List<Invoice_Item__c> newItems = new List<Invoice_Item__c>();
        //for setting up InvoiceItem parent/child relationship with TicketItem parent/child info
        Map<Id, Invoice_Item__c> ticketItemToInvItemLookup = new Map<Id, Invoice_Item__c>();
        if(parentInvItems != null) {
          for(Invoice_Item__c parentInvItem: parentInvItems) {
            ticketItemToInvItemLookup.put(parentInvItem.Ticket_Item__c, parentInvItem);
          }
        }

        String ns = UtilityGetNamespace.CurrentNamespace();

        Map<String, Id> rtLookup = GetInvoiceItemRecordTypeLookup();

        Set<String> tktItemFields = Ticket_Item__c.sObjectType.getDescribe().fields.getMap().keySet();
        Set<String> tktItemQueryFields = new Set<String>();
        tktItemQueryFields.addAll(tktItemFields);
        tktItemQueryFields.add('RecordType.DeveloperName');
        tktItemQueryFields.add('RecordType.Name');

        String soql = String.format('SELECT {1}, {0}Price_Book_Item__r.{0}Sequence_Number__c FROM {0}Ticket_Item__c WHERE IsDeleted=false AND (Id IN :sourceItemIds OR {0}Parent_Ticket_Item__c IN :sourceItemIds) ORDER BY {0}Parent_Ticket_Item__c NULLS FIRST',
            new String[]{ns, String.join(new List<String>(tktItemQueryFields), ',')});

        List<Ticket_Item__c> sources = (List<Ticket_Item__c>)Database.query(soql);
        Map<Id, Ticket_Item__c> sourcesLookup = new Map<Id, Ticket_Item__c>(sources);

        Map<String, String> invItemToTicketItemFieldMapping =  GetInvoiceItemToTicketItemFieldMapping(ns.toLowercase(), tktItemFields);

        SobjectType invItemType = Invoice_Item__c.SobjectType;

        for(Id sourceItemId: sourceItemIds)
        {
            Ticket_Item__c obj = sourcesLookup.get(sourceItemId);
            Id inviRecordType = rtLookup.containsKey(obj.RecordType.DeveloperName)? rtLookup.get(obj.RecordType.DeveloperName) : null;
            Invoice_Item__c invi = (Invoice_Item__c)invItemType.newSObject(inviRecordType, true);
            for(String f: invItemToTicketItemFieldMapping.keySet())
            {
                invi.put(f, obj.get(invItemToTicketItemFieldMapping.get(f)));
            }
            invi.Invoice__c = invId;
            invi.Ticket_Item__c = obj.Id;
            invi.Sequence_Number__c = obj.Price_Book_Item__r.Sequence_Number__c;

            if (!String.IsEmpty(invoiceItemParentId)) {
              invi.Parent_Invoice_Item__c = invoiceItemParentId;
            } else if (ticketItemToInvItemLookup.containsKey(obj.Parent_Ticket_Item__c)) {
              invi.Parent_Invoice_Item__c = ticketItemToInvItemLookup.get(obj.Parent_Ticket_Item__c).Id;
            }
            newItems.add(invi);
        }
        return newItems;
    }

    static Map<String, String> GetInvoiceItemToTicketItemFieldMapping(String nsLowercase, Set<String> ticketItemFields)
    {
        Map<String, String> inviToTicketFieldMapping = new Map<String, String>();
        Boolean isInDev = String.isBlank(nsLowercase);

        for(Schema.SObjectField f: Schema.sObjectType.Invoice_Item__c.fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe();

            if (!fd.isCustom() || !fd.isAccessible() || !fd.isCreateable() || fd.isCalculated() || fd.isAutoNumber())
            {
                continue;
            }
            String inviFieldName = fd.getName().toLowercase();
            if(ticketItemFields.contains(inviFieldName))
            {
                inviToTicketFieldMapping.put(inviFieldName, inviFieldName);
            }
            else if(!isInDev)
            {
                String tiField = '';
                if(inviFieldName.startsWith(nsLowercase))
                {
                    tiField = inviFieldName.replace(nsLowercase, '');
                }
                else
                {
                    tiField = nsLowercase + inviFieldName;
                }
                if(ticketItemFields.contains(tiField))
                {
                    inviToTicketFieldMapping.put(inviFieldName, tiField);
                }
            }
        }
        return inviToTicketFieldMapping;
    }

    static Map<String, String> GetInvoiceItemToPBItemFieldMapping(String nsLowercase, Set<String> pbItemFields)
    {
        Map<String, String> inviToPBIFieldMapping = new Map<String, String>();
        Boolean isInDev = String.isBlank(nsLowercase);

        for(Schema.SObjectField f: Schema.sObjectType.Invoice_Item__c.fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe();

            if (!fd.isCustom() || !fd.isAccessible() || !fd.isCreateable() || fd.isCalculated() || fd.isAutoNumber())
            {
                continue;
            }
            String inviFieldName = fd.getName().toLowercase();
            if(pbItemFields.contains(inviFieldName))
            {
                inviToPBIFieldMapping.put(inviFieldName, inviFieldName);
            }
            else if(!isInDev)
            {
                String pbiField = '';
                if(inviFieldName.startsWith(nsLowercase))
                {
                    pbiField = inviFieldName.replace(nsLowercase, '');
                }
                else
                {
                    pbiField = nsLowercase + inviFieldName;
                }
                if(pbItemFields.contains(pbiField))
                {
                    inviToPBIFieldMapping.put(inviFieldName, pbiField);
                }
            }
        }
        return inviToPBIFieldMapping;
    }

    public static void ApplySequenceNumber(List<Invoice_Item__c> parentItems, Decimal nextSeqNumber)
    {
        if(nextSeqNumber == null || nextSeqNumber<0) return;

        for(Invoice_Item__c parentItem : parentItems)
        {
            parentItem.Sequence_Number__c = nextSeqNumber;
            nextSeqNumber++;
        }
    }

    public static Map<String, Id> GetInvoiceItemRecordTypeLookup()
    {
        String ns = StringUtility.FXNamespace();
        String invItemFullName = ns + 'Invoice_Item__c';
        Map<String, Id> rtLookup = new Map<String, Id>();
        for(RecordType rt : [SELECT Id, Name, DeveloperName FROM RecordType WHERE IsActive=true AND SobjectType = :invItemFullName])
        {
            rtLookup.put(rt.Name, rt.Id);
            rtLookup.put(rt.DeveloperName, rt.Id);
        }
        return rtLookup;
    }

    public class CreateInvoiceItemsRequest {
      public Id invId;
      public List<Id> sourceIds;
      public Decimal nextSeqNumber;
      public String parentInvItemId;
    }

    public class GetAvailableTicketsForInvoiceRequest {
        public String invoiceId;
        public String showItemsAlreadyOnTheInvoice;
        public String itemLimit;
        public String itemOffset;
        public String sortby;
        public String sortdir;
        public String tktFields;
        public String tktItemFields;
        public String invoiceItemParentTktItemId;
        public String showItemsAlreadyInvoiced;
        public List<ItemBuilderHelper.SearchFieldRequest> availableticketJobfilters;
        public List<ItemBuilderHelper.SearchFieldRequest> availableticketTicketfilters;
        public List<ItemBuilderHelper.SearchFieldRequest> availableticketTicketItemfilters;
    }

    public class GetAvailableTicketsForInvoiceResult {
        public List<Ticket__c> selectedTkts;
        public List<Ticket_Item__c> selectedTktItems;
        public List<Ticket__c> availableTickets;
        public List<Ticket_Item__c> childTicketItems;
        public List<Ticket_Item__c> parentTicketItems;
        public string soql;
    }

    public class GetAvailablePBIsForInvoiceRequest {
        public String invoiceId;
        public String showItemsAlreadyOnTheInvoice;
        public String itemLimit;
        public String itemOffset;
        public String sortby;
        public String sortdir;
        public String pbiFields;
        public String invoiceItemParentPBIId;
        public List<ItemBuilderHelper.SearchFieldRequest> availableticketPBIfilters;
    }

    public class GetAvailablePBIsForInvoiceResult {
        public List<Price_Book_Item__c> selectedPBIs;
        public List<Price_Book_Item__c> availablePBIs;
        public List<Price_Book_Item__c> childPBIs;
        public string soql;
    }

    public class GetSelectedTicketsForInvoiceRequest {
        public String invoiceId;
        public String sortby;
        public String sortdir;
        public String tktFields;
        public String tktItemFields;
        public String invoiceItemParentTktItemId;
    }

    public class GetSelectedTicketsForInvoiceResult {
        public List<Ticket__c> selectedTkts;
        public List<Ticket_Item__c> selectedTktItems;
        public List<Ticket_Item__c> childTicketItems;
        public List<Ticket_Item__c> parentTicketItems;
    }

    public class GetAvailableTicketsSearchFilterResult {
      public List<ItemBuilderHelper.SearchFieldResult> jobSearchFields;
      public List<ItemBuilderHelper.SearchFieldResult> ticketSearchFields;
      public List<ItemBuilderHelper.SearchFieldResult> ticketItemSearchFields;
      public Map<String, String> keyPrefixesForObjects;
    }

    public class GetAvailableTicketsPBISearchFilterResult {
      public List<ItemBuilderHelper.SearchFieldResult> pbiSearchFields;
      public Map<String, String> keyPrefixesForObjects;
    }

    public class InvoiceItemsUpdateResult {
        public List<InvoiceItemUpdateResult> updateResult  { get; set; }
        public Invoice__c invoice;
        public List<Invoice_Item__c> invItems;
    }

    public class InvoiceItemUpdateResult {
        public String id { get; set; }
        public Boolean success  { get; set; }
        public List<InvoiceItemUpdateError> errors  { get; set; }
    }

    public class InvoiceItemUpdateError {
        public String message { get; set; }
        public List<String> fields { get; set; }
    }

    public class InvItemsRequest {
        public string typeStr;
        public String invFields;
        public String invItemFields;
        public List<Invoice_Item__c> inviList;
    }

    public class InvoiceItemsFetchResult {
        public Invoice__c invoice;
        public List<Invoice_Item__c> invItems;
        public Invoice_Item__c invItem;
        public List<Invoice_Item__c> invItemSiblings;
        public List<Invoice_Item__c> invItemChildren;
    }

    public class InvItemsResponseWithFilter {
        public String invFields;
        public String invItemFields;
        public String invId;
        public String invItemId;
        public InvItemsFilterResponse filter;
    }

    public class InvItemsFilterResponse {
        public string keyword;
        public string itemType;
        public string classification;
        public string itemLimit;
        public string itemOffset;
        public string sortby;
        public string sortdir;
    }
}
