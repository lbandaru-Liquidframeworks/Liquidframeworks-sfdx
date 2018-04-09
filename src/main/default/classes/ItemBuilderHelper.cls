public class ItemBuilderHelper
{
    public static String getKeyPrefixForObject(Schema.SObjectType objType) {
      String keyPrefix = objType.getDescribe().keyPrefix;
      return keyPrefix;
    }

    public static Map<String, String> getKeyPrefixForObject(String objStr) {
      String ns = UtilityGetNamespace.CurrentNamespace();
      Schema.SObjectType objType = Schema.getGlobalDescribe().get(ns+objStr);
      String keyPrefix = objType.getDescribe().keyPrefix;

      Map<String, String> res = new Map<String, String>();
      res.put(objStr, keyPrefix);

      return res;
    }

    public static Map<String, String> getKeyPrefixesForObjects() {
      Map<String, String> keyPrefixes = new Map<String, String>();
      String ns = UtilityGetNamespace.CurrentNamespace();

      for(Schema.SObjectType objType : Schema.getGlobalDescribe().Values()){
        String objName = objType.getDescribe().getName();
        String keyPrefix = getKeyPrefixForObject(objType);
        keyPrefixes.put(objName, keyPrefix);
        objName = objName.replace(ns,'');
        keyPrefixes.put(objName, keyPrefix);
      }

      return keyPrefixes;
    }

    public static List<SearchFieldResult> ProcessSearchFieldSet(String objName, String searchFieldSetName) {
      List<SearchFieldResult> searchFields = new List<SearchFieldResult>();
      List<Schema.FieldSetMember> fields = new List<Schema.FieldSetMember>();

      Schema.FieldSet fieldSet = MetadataHelper.GetFieldSet(objName, searchFieldSetName);
      if (fieldSet != null) fields = fieldSet.getFields();

      if (fields == null) {
        return searchFields;
      }

      SObjectType objType = Schema.getGlobalDescribe().get(objName);
      Schema.DescribeSObjectResult obj = objType.getDescribe();
      Map<String,Schema.SObjectField> fieldsMap = obj.fields.getMap();
      List<Schema.RecordTypeInfo> rtiList = obj.getRecordTypeInfos();

      for(Schema.FieldSetMember field: fields) {
    System.debug(field);
        SearchFieldResult searchField = new SearchFieldResult();
        searchField.ApiName = field.getFieldPath();
        searchField.label = field.getLabel();
        searchField.type = field.getType();

        if (searchField.type==Schema.DisplayType.Picklist || searchField.type==Schema.DisplayType.Multipicklist) {
          searchfield.options = new List<SearchFieldPicklistOption>();
          Schema.DescribeFieldResult fieldResult = fieldsMap.get(searchField.ApiName.toLowerCase()).getDescribe();
          List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
          for(Schema.PicklistEntry f : ple)
          {
            SearchFieldPicklistOption option = new SearchFieldPicklistOption();
            option.label=f.getLabel();
            option.value=f.getValue();
            searchfield.options.add(option);
          }
        } else if (searchField.type==Schema.DisplayType.Reference) {
          String apiName = searchField.ApiName;
          if (apiName=='RecordTypeId') {
            searchfield.options = new List<SearchFieldPicklistOption>();
            searchField.type = Schema.DisplayType.Picklist;
            for(Schema.RecordTypeInfo rti : rtiList)
            {
              if (rti.isAvailable()) {
                SearchFieldPicklistOption option = new SearchFieldPicklistOption();
                option.label=rti.getName();
                option.value=rti.getRecordTypeId();
                searchfield.options.add(option);
              }
            }
          } else if (apiName.endsWithIgnoreCase('LastModifiedById')) {
          } else if (apiName.endsWithIgnoreCase('CreatedById')) {
          } else if (apiName.endsWithIgnoreCase('OwnerId')) {
          } else {
    System.debug(searchField.ApiName);
            Schema.DescribeFieldResult fieldResult = fieldsMap.get(searchField.ApiName.toLowerCase()).getDescribe();
            if(fieldResult.getReferenceTo().size()>0) {
              Schema.SObjectType reference = fieldResult.getReferenceTo()[0];
              Schema.DescribeSObjectResult fieldObjDescribe = reference.getDescribe();
              searchField.keyPrefix = fieldObjDescribe.getKeyPrefix();
              //searchField.ApiName = fieldObjDescribe.getName();
              //searchField.label = fieldObjDescribe.getLabel();
            }
          }
        }
        searchFields.add(searchField);
      }

      return searchFields;
    }

    public static String GetFilterSoql(List<SearchFieldRequest> itemfilters, String fieldPrefix) {
      String soql = '';

      if (itemfilters == null) {
        return soql;
      }

      for (SearchFieldRequest sfr : itemfilters) {
        if (sfr.type==Schema.DisplayType.Multipicklist.name()) {
          if (sfr.value!='\'\'') {
            soql += ' AND ' +fieldPrefix+ sfr.ApiName + ' includes (' + sfr.value + ') ';
          }
        } else if (sfr.type==Schema.DisplayType.Picklist.name()) {
            if (sfr.ApiName=='RecordTypeId') {
              soql += ' AND ' +fieldPrefix+ sfr.ApiName + ' = ' + sfr.value + ' ';
            } else {
              if (sfr.value!='\'\'') {
                soql += ' AND ' +fieldPrefix+ sfr.ApiName + ' in (' + sfr.value + ') ';
              }
            }
        } else if (sfr.type==Schema.DisplayType.Reference.name()) {
          String name = sfr.ApiName.replace('__c','__r')+'.name';
          soql += ' AND ' +fieldPrefix+ name + ' = \'' + sfr.value + '\' ';
        } else if (sfr.type==Schema.DisplayType.DateTime.name()) {
          String[] dates = sfr.value.split('\\,');
          if(dates[0]!='\'\'') {
              soql += ' AND ' +fieldPrefix+ sfr.ApiName + ' >= ' + dates[0].replace('\'','') + ' ';
          }
          if(dates[1]!='\'\'') {
            soql += ' AND ' +fieldPrefix+ sfr.ApiName + ' <= ' + dates[1].replace('\'','') + ' ';
          }
        } else if (sfr.type==Schema.DisplayType.Date.name()) {
          String[] dates = sfr.value.split('\\,');
          if(dates[0]!='\'\'') {
            soql += ' AND ' +fieldPrefix+ sfr.ApiName + ' >= ' + dates[0].replace('\'','') + ' ';
          }
          if(dates[1]!='\'\'') {
            soql += ' AND ' +fieldPrefix+ sfr.ApiName + ' <= ' + dates[1].replace('\'','') + ' ';
          }
        } else if (sfr.type==Schema.DisplayType.Double.name() || sfr.type==Schema.DisplayType.Currency.name() || sfr.type==Schema.DisplayType.Percent.name()) {
          soql += ' AND ' +fieldPrefix+ sfr.ApiName + ' = ' + sfr.value + ' ';
        } else if (sfr.type==Schema.DisplayType.Boolean.name()) {
          soql += ' AND ' +fieldPrefix+ sfr.ApiName + ' = ' + sfr.value + ' ';
        } else if (sfr.type==Schema.DisplayType.TEXTAREA.name()) {
        } else {
          soql += ' AND ' +fieldPrefix+ sfr.ApiName + ' LIKE \'%' + sfr.value + '%\' ';
        }
      }

      return soql;
    }

    public class SearchFieldResult {
      public String ApiName;
      public String label;
      public Schema.DisplayType type;
      public List<SearchFieldPicklistOption> options;
      public String keyPrefix;
    }

    public class SearchFieldPicklistOption {
      public string label;
      public string value;
    }

    public class SearchFieldRequest {
      public String ApiName;
      public String value;
      public String type;
      public String obj;
    }
}
