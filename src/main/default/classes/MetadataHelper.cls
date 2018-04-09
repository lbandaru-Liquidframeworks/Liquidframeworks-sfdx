global with sharing class MetadataHelper
{
  public static Set<String> GetRollupSummaryFields(sObjectType t)
  {
    Set<String> fields = new Set<String>();
    Schema.DescribeSObjectResult dsr = t.getDescribe();
    String objType = dsr.getName();
    for(Schema.SObjectField f: dsr.fields.getMap().values())
    {
        Schema.DescribeFieldResult dfr = f.getDescribe();
        if(!dfr.isCustom() || !dfr.isCalculated() || dfr.getCalculatedFormula()!=null) continue;
        fields.add(dfr.getName());
    }
    if(Schema.getGlobalDescribe().containsKey('dlrs__LookupRollupSummary__c'))
    {
        for(sObject o: Database.query('SELECT dlrs__AggregateResultField__c FROM dlrs__LookupRollupSummary__c WHERE dlrs__ParentObject__c=:objType'))
        {
           fields.add(String.valueOf(o.get('dlrs__AggregateResultField__c')));
        }
    }
    return fields;
  }
  global static Map<String, Schema.FieldSet> GetFieldSets(String objName)
  {
    String ns = UtilityGetNamespace.CurrentNamespace();
    if(!String.isBlank(ns) && !objName.toLowerCase().startsWith(ns.toLowerCase()))
    {
      objName = ns + objName;
    }
    Schema.DescribeSObjectResult obj = Schema.getGlobalDescribe().get(objName).getDescribe();
    return obj.FieldSets.getMap();
  }

  global static Schema.FieldSet GetFieldSet(String objName, String fieldSetName)
  {
    String ns = UtilityGetNamespace.CurrentNamespace();
    if(!String.isBlank(ns) && !objName.toLowerCase().startsWith(ns.toLowerCase()))
    {
      objName = ns + objName;
    }
    Schema.DescribeSObjectResult obj = Schema.getGlobalDescribe().get(objName).getDescribe();
    Schema.FieldSet fieldSetObj = obj.FieldSets.getMap().get(fieldSetName);
    return fieldSetObj;
  }

  global static String GetSelectQuery(Schema.DescribeSObjectResult r)
  {
    return GetSelectQuery(r, false);
  }

  global static String GetSelectQuery(Schema.DescribeSObjectResult r, Boolean customFieldsOnly)
  {
    String soql = 'SELECT ';
    String sep = '';
    for(String f: r.fields.getMap().keySet())
        {
          if(customFieldsOnly && !f.endsWith('__c')) continue;
          soql += sep + f;
          sep = ',';
        }
        if(customFieldsOnly)
        {
          soql += sep + 'Id';
        }
        soql += ' FROM ' + r.getName();
        return soql;
  }

}
