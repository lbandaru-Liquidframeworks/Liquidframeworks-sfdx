public class InvoiceItemHandler_AvailableTktsSearch
{
    static String invoiceItemKeyPrefix = Invoice_Item__c.sObjectType.getDescribe().keyPrefix;
    static String ticketItemKeyPrefix = Ticket_Item__c.sObjectType.getDescribe().keyPrefix;
    static String pricebookItemKeyPrefix = Price_Book_Item__c.sObjectType.getDescribe().keyPrefix;

    public static Map<String, String> GetInvoiceValuesForJobSearchFields(List<ItemBuilderHelper.SearchFieldResult> jobSearchFields, String invoiceId)
    {
      String ns = UtilityGetNamespace.CurrentNamespace();

      Set<String> invFields = Invoice__c.sObjectType.getDescribe().fields.getMap().keySet();
      Set<String> invQueryFields = new Set<String>();
      invQueryFields.addAll(invFields);

      for(Schema.SObjectField f: Schema.sObjectType.Invoice__c.fields.getMap().values())
      {
          Schema.DescribeFieldResult fd = f.getDescribe();

          if (!fd.isCustom() || !fd.isAccessible() || !fd.isCreateable() || fd.isCalculated() || fd.isAutoNumber())
          {
              continue;
          }
          if (fd.getType()==Schema.DisplayType.Reference) {
            String invFieldName = fd.getName().toLowercase();
            invQueryFields.add(invFieldName.removeEndIgnoreCase('__c')+'__r.Name');
          }
      }

      String soql = String.format('SELECT {1} FROM {0}Invoice__c WHERE IsDeleted=false AND Id=:invoiceId LIMIT 1',
          new String[]{ns, String.join(new List<String>(invQueryFields), ',') });
System.debug('7: '+soql);
      Invoice__c source = (Invoice__c)Database.query(soql);
System.debug('8: '+JSON.serializePretty(source));

      Set<String> jobFields = new Set<String>();
      for(ItemBuilderHelper.SearchFieldResult jobSearchField : jobSearchFields) {
        jobFields.add(jobSearchField.ApiName.toLowercase());
System.debug('1: '+jobSearchField.ApiName.toLowercase());

        String fieldReferenceName = GetReferenceName(jobSearchField.ApiName, jobSearchField.type);
        if (fieldReferenceName!=null) jobFields.add(fieldReferenceName);
      }
System.debug('5: '+jobFields);

      SobjectType jobType = Job__c.SobjectType;
      Map<String, String> job = new Map<String, String>();
      Map<String, String> invToJobFieldMapping =  GetInvoiceToJobFieldMapping(ns.toLowercase(), jobFields);
System.debug('3: '+invToJobFieldMapping);

      for(String f: invToJobFieldMapping.keySet())
      {
System.debug('2: '+f);
          if (f.endswith('__r.name')) {
            SObject obj = source.getSObject(f.replace('.name',''));
System.debug('7: '+obj);
            job.put(invToJobFieldMapping.get(f), String.valueOf(obj.get('name')));
          } else {
            job.put(invToJobFieldMapping.get(f), String.valueOf(source.get(f)));
          }
      }

      return job;
    }

    public static String GetAvailableTicketsSearchFilter(String processStr) {
        JSONParser parser = JSON.createParser(processStr);
        Type resultType = Type.forName('InvoiceItemHandler_AvailableTktsSearch.GetAvailableTicketsSearchFilterRequest');
        InvoiceItemHandler_AvailableTktsSearch.GetAvailableTicketsSearchFilterRequest readValueAsResults = (InvoiceItemHandler_AvailableTktsSearch.GetAvailableTicketsSearchFilterRequest)parser.readValueAs(resultType);

        return GetAvailableTicketsSearchFilter(readValueAsResults);
    }

    public static String GetAvailableTicketsSearchFilter(GetAvailableTicketsSearchFilterRequest request) {
      String fxNamespacePrefix = UtilityGetNamespace.CurrentNamespace();
      String searchFieldSetName = fxNamespacePrefix+'IIBSearchFields';

      GetAvailableTicketsSearchFilterResult result = new GetAvailableTicketsSearchFilterResult();
      result.jobSearchFields = ItemBuilderHelper.ProcessSearchFieldSet(fxNamespacePrefix+'Job__c', searchFieldSetName);
      result.ticketSearchFields = ItemBuilderHelper.ProcessSearchFieldSet(fxNamespacePrefix+'Ticket__c', searchFieldSetName);
      result.ticketItemSearchFields = ItemBuilderHelper.ProcessSearchFieldSet(fxNamespacePrefix+'Ticket_Item__c', searchFieldSetName);
      result.keyPrefixesForObjects = ItemBuilderHelper.getKeyPrefixesForObjects();

      if(request!=null) {
        result.invoiceValues = GetInvoiceValuesForJobSearchFields(result.jobSearchFields, request.invId);
      }

      return JSON.serializePretty(result, false);
    }

    public static String GetAvailableTicketsForInvoice(String processStr) {
        JSONParser parser = JSON.createParser(processStr);
        Type resultType = Type.forName('InvoiceItemHandler_AvailableTktsSearch.GetAvailableTicketsForInvoiceRequest');
        InvoiceItemHandler_AvailableTktsSearch.GetAvailableTicketsForInvoiceRequest readValueAsResults = (InvoiceItemHandler_AvailableTktsSearch.GetAvailableTicketsForInvoiceRequest)parser.readValueAs(resultType);

        GetAvailableTicketsForInvoiceResult result = GetAvailableTicketsForInvoice(readValueAsResults);

        return JSON.serializePretty(result, false);
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
      commandText += ' AND Id IN :invoicedTktIds LIMIT 2000 ';

      result.selectedTkts = Database.query(commandText);

      commandText = 'SELECT ' + tktItemFields + ' FROM ' + fxNamespacePrefix + 'Ticket_Item__c ';
      commandText += ' WHERE IsDeleted=false ';
      commandText += ' AND Id IN :invoicedTktItemIds LIMIT 2000 ';

      result.selectedTktItems = Database.query(commandText);

      String jobFilterSoql = ItemBuilderHelper.GetFilterSoql(request.availableticketJobfilters, fxNamespacePrefix+'Ticket__r.'+fxNamespacePrefix+'Job__r.');
      String ticketFilterSoql = ItemBuilderHelper.GetFilterSoql(request.availableticketTicketfilters, fxNamespacePrefix+'Ticket__r.');
      String ticketItemFilterSoql = ItemBuilderHelper.GetFilterSoql(request.availableticketTicketItemfilters, '');

      commandText = 'SELECT '+tktItemFields+' FROM ' + fxNamespacePrefix + 'Ticket_Item__c WHERE ' + fxNamespacePrefix + 'Parent_Ticket_Item__c = NULL';
      commandText += jobFilterSoql;
      commandText += ticketFilterSoql;
      commandText += ticketItemFilterSoql;

      if (invoiceItemParentTktItemId != null && invoiceItemParentTktItemId != '') {
          commandText += ' AND Id != :invoiceItemParentTktItemId ';
      }

      if (showItemsAlreadyInvoiced != 'true') {
          //filter items that are on any invoice
          commandText += ' AND (' + fxNamespacePrefix + 'Invoice_Item__c = NULL OR ' + fxNamespacePrefix + 'Invoice_Item__r.' + fxNamespacePrefix + 'Invoice__c = :invoiceId) ';
      }

      if (showItemsAlreadyOnTheInvoice == 'false') {
          if (invoicedTktItemIds.size() > 0) {
              commandText += ' AND Id not in :invoicedTktItemIds ';
          }
      }

      commandText += ' ORDER BY '+fxNamespacePrefix+'Sequence_Number__c ASC NULLS LAST LIMIT 1000';

      result.parentTicketItems = Database.query(commandText);
      result.soql = commandText;

      Set<Id> availableTktItemIds = new Map<Id, Ticket_Item__c>(result.parentTicketItems).keySet();

      commandText = 'SELECT '+tktItemFields+' FROM ' + fxNamespacePrefix + 'Ticket_Item__c WHERE ' + fxNamespacePrefix + 'Parent_Ticket_Item__c != NULL';
      commandText += ticketItemFilterSoql;
      commandText += ' AND ' + fxNamespacePrefix + 'Parent_Ticket_Item__c IN :availableTktItemIds';

      if (invoiceItemParentTktItemId != null && invoiceItemParentTktItemId != '') {
          commandText += ' AND Id != :invoiceItemParentTktItemId ';
      }

      if (showItemsAlreadyInvoiced != 'true') {
          //filter items that are on any invoice
          commandText += ' AND (' + fxNamespacePrefix + 'Invoice_Item__c = NULL OR ' + fxNamespacePrefix + 'Invoice_Item__r.' + fxNamespacePrefix + 'Invoice__c = :invoiceId) ';
      }

      if (showItemsAlreadyOnTheInvoice == 'false') {
          if (invoicedTktItemIds.size() > 0) {
              commandText += ' AND Id not in :invoicedTktItemIds ';
          }
      }

      commandText += ' ORDER BY '+fxNamespacePrefix+'Sequence_Number__c ASC NULLS LAST LIMIT 1000';

      result.childTicketItems = Database.query(commandText);

      Set<Id> availableTktIds = new Set<Id>();
      for (Ticket_Item__c ti : result.parentTicketItems) {
        if (!availableTktIds.contains(ti.Ticket__c))
        availableTktIds.add(ti.Ticket__c);
      }

      commandText = 'SELECT ' + tktFields + ' FROM ' + fxNamespacePrefix + 'Ticket__c ';
      commandText += ' WHERE IsDeleted=false ';
      commandText += ' AND Id IN :availableTktIds ';

      String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
      String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
      String nullsLast = (sb != '') ? 'NULLS LAST' : '';
      commandText += sb + ' ' + sd + ' ' + nullsLast;

      String lim = (itemLimit != '' ) ? (Integer.valueOf(itemLimit) > 2000) ? '2000' : itemLimit : '2000';
      String off = (itemOffset != '' ) ? (Integer.valueOf(itemOffset) > 2000) ? '2000' : itemOffset : '0';
      commandText += ' LIMIT ' + lim + ' OFFSET ' + off + ' ';

      result.availableTickets = Database.query(commandText);

      return result;
    }

    static String GetReferenceName(String fieldName, Schema.DisplayType fieldType) {
      if (fieldType==Schema.DisplayType.Reference) {
System.debug('6: '+fieldName);
        if (fieldName!='RecordTypeId' &&
            !fieldName.endsWithIgnoreCase('LastModifiedById') &&
            !fieldName.endsWithIgnoreCase('CreatedById') &&
            !fieldName.endsWithIgnoreCase('OwnerId'))
        {
          return (fieldName.removeEndIgnoreCase('__c')+'__r.Name').toLowercase();
        }
      }

      return null;
    }

    static Map<String, String> GetInvoiceToJobFieldMapping(String nsLowercase, Set<String> jobFields)
    {
        Map<String, String> invToJobFieldMapping = new Map<String, String>();
        Boolean isInDev = String.isBlank(nsLowercase);

        for(Schema.SObjectField f: Schema.sObjectType.Invoice__c.fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe();

            if (!fd.isCustom() || !fd.isAccessible() || !fd.isCreateable() || fd.isCalculated() || fd.isAutoNumber())
            {
                continue;
            }
            String invFieldName = fd.getName().toLowercase();
            Schema.DisplayType invFieldType = fd.getType();

            if(jobFields.contains(invFieldName))
            {
                invToJobFieldMapping.put(invFieldName, invFieldName);
                String invFieldReferenceName = GetReferenceName(invFieldName, invFieldType);
System.debug('10: '+invFieldReferenceName);
                if (invFieldReferenceName!=null) invToJobFieldMapping.put(invFieldReferenceName, invFieldName.removeEndIgnoreCase('__c')+'__r.name');
            }
            else if(!isInDev)
            {
                String jobField = '';
                if(invFieldName.startsWith(nsLowercase))
                {
                    jobField = invFieldName.replace(nsLowercase, '');
                }
                else
                {
                    jobField = nsLowercase + invFieldName;
                }
                if(jobFields.contains(jobField))
                {
                    invToJobFieldMapping.put(invFieldName, jobField);
                    String invFieldReferenceName = GetReferenceName(invFieldName, invFieldType);
System.debug('9: '+invFieldReferenceName);
                    if (invFieldReferenceName!=null) invToJobFieldMapping.put(invFieldReferenceName, invFieldName.removeEndIgnoreCase('__c')+'__r.name');
                }
            }
        }
        return invToJobFieldMapping;
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


    public class GetAvailableTicketsSearchFilterResult {
      public List<ItemBuilderHelper.SearchFieldResult> jobSearchFields;
      public List<ItemBuilderHelper.SearchFieldResult> ticketSearchFields;
      public List<ItemBuilderHelper.SearchFieldResult> ticketItemSearchFields;
      public Map<String, String> keyPrefixesForObjects;
      public Map<String, String> invoiceValues;
    }

    public class GetAvailableTicketsSearchFilterRequest {
      public String invId;
    }
}
