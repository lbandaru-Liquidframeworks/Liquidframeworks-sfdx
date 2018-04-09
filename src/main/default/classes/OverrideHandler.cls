public class OverrideHandler
{
    public static Set<String> GetContextFields(String filter)
    {
        Set<String> fields = new Set<String>();
        for(String f: GetRawContextFields(filter))
        {
            fields.add(f.toLowercase().removeStart('$'));
        }      
        return fields;
    }

    static Set<String> GetRawContextFields(String filter)
    {
        Set<String> fields = new Set<String>();
        //$FX5__Contamanent__r.FX5__Override__r.Price__c
        String reg = '(?i)[$]([\\w]+__r[\\.])*([\\w]+)';
        Pattern p = Pattern.compile(reg);
        Matcher fm = p.matcher(filter);
        while(fm.find())
        {
            String f = fm.group(0);
            fields.add(f);
        }
        
        return fields;
    }

    public static void Validate(List<Override_Config__c> items)
    {
        String ns = StringUtility.FXNamespace();
        
        for(Override_Config__c c: items)
        {
            List<String> msgs = new List<String>();            

            String filter = c.Filter_Clause__c;
            Set<String> fields = GetRawContextFields(c.Filter_Clause__c);

            List<String> subjectFields = new List<String>();
            for(String f: fields)
            {
                filter = filter.replace(f, 'null');
                subjectFields.add(f.removeStart('$'));
            }
            String subjectSoql = 'SELECT ' + String.join(subjectFields, ',');

            for(String t: c.Applies_to_SObject__c.split(';'))
            {
                String contextObjType = ns + t + '_Item__c';
                String targetSoql = subjectSoql +  ' FROM ' + contextObjType + ' LIMIT 1';
                try
                {
                    Database.query(targetSoql);
                }
                catch(Exception e1)
                {
                    msgs.add(targetSoql + ': ' + e1.getMessage());
                }                
            }

            filter = filter.replace('<=', '=').replace('>=', '=').replace('<', '=').replace('>', '=');

            String soql = 'SELECT ' + c.Override_Fields__c + ' FROM ' + ns + 'Override__c WHERE ' + filter + ' LIMIT 1';
            try 
            {
                Database.query(soql);
            }
            catch (Exception ex) 
            {
                msgs.add(soql + ': ' + ex.getMessage() );                   
            }
            if(!msgs.isEmpty())
            {
                 c.addError(String.join(msgs, '<br />'), false);
            }
        }
    }


    public static void ApplyOverride(List<sObject> objs)
    {   
        String ns = StringUtility.FXNamespace();
        String appliesTo = objs.get(0).getSObjectType().getDescribe().getName().removeStartIgnoreCase(ns).removeEndIgnoreCase('_Item__c');
        

        String costOverrideField = ns + 'PBI_Override_Cost_Method__c';
        String priceOverrideField = ns + 'PBI_Override_Price_Method__c';

        List<sObject> itemsOfInterest = new List<sObject>();
        for(sObject o : objs)
        {
            if(o.get(costOverrideField) == null && o.get(priceOverrideField)==null) continue;
            itemsOfInterest.add(o);
        }
        if(!itemsOfInterest.isEmpty())
        {
            ApplyOverrideInternal(itemsOfInterest, appliesTo, costOverrideField, priceOverrideField);
        }        
    }

    @testVisible
    static void ApplyOverrideInternal(List<sObject> objs, 
            String appliesTo,
            String costOverrideField, 
            String priceOverrideField)
    {
        Map<Id, Override_Config__c> overrideConfigs = new Map<Id, Override_Config__c>([SELECT Id, Applies_to_SObject__c, Filter_Clause__c, Limit__c, Override_Fields__c, Override_Type__c, Sort_Clause__c, Apply_Null__c, IsAggregation__c FROM Override_Config__c WHERE IsDeleted=false]);
        

        for(sObject o : objs)
        {
            Id configId = (Id)o.get(costOverrideField);
            if(!String.isBlank(configId) && overrideConfigs.containsKey(configId))
            {
                Override_Config__c config = overrideConfigs.get(configId);
                ApplyOverride(o, config, appliesTo);
            }

            configId = (Id)o.get(priceOverrideField);
            if(!String.isBlank(configId) && overrideConfigs.containsKey(configId))
            {
                Override_Config__c config = overrideConfigs.get(configId);
                ApplyOverride(o, config, appliesTo);
            }
        }
    }
    
    static String OverrideTrackingField
    {
        get
        {
            if(String.isBlank(OverrideTrackingFieldLocal))
            {
                OverrideTrackingFieldLocal = StringUtility.FXNamespace() + 'Override__c';
            }
            return OverrideTrackingFieldLocal;
        }
    }
    static String OverrideTrackingFieldLocal = null;
        
    static void ApplyOverride(sObject obj, Override_Config__c config, String appliesTo)
    {
        List<sObject> overrides = GetOverrides(obj, config, appliesTo);
        if(overrides==null || overrides.isEmpty()) return;

        Set<String> fieldsToOverride = new Set<String>();
        Map<String, Schema.sObjectField> objFields = obj.getSObjectType().getDescribe().fields.getMap();
        
        for(String f : config.Override_Fields__c.split(','))
        {
            String s = f.trim();
            if(config.IsAggregation__c == true)
            {
                String[] fields = s.split(' ');
                if(fields.size()==2)
                {
                    s = fields.get(1).trim();
                }
            }
            if(!objFields.containsKey(s)) continue;
            fieldsToOverride.add(s);
        }   
        
        Boolean applyNull = config.Apply_Null__c;

        sObject overrideObj = overrides.get(0);     
        for(String f : fieldsToOverride)
        {
            Object v = overrideObj.get(f);
            if(v!=null || applyNull)
            {
                obj.put(f, v);
            }
        }  
        if(!config.IsAggregation__c)
        {
            obj.put(OverrideTrackingField, overrideObj.Id);
        }     
    }

    


    
    public static List<sObject> GetOverrides(sObject subject, Override_Config__c config, String appliesTo)
    {       
       
        String configFilter = config.Filter_Clause__c.toLowercase();

        List<Object> values = new List<Object>();
        List<String> fields = new List<String>(GetContextFields(configFilter));
        for(Integer j =0; j<fields.size(); j++)
        {
            values.add(subject.get(fields.get(j)));
        }

        Integer i =0;
        Object v0 = values.size()>= i+1? values.get(i): null; i++;
        Object v1 = values.size()>= i+1? values.get(i): null; i++;
        Object v2 = values.size()>= i+1? values.get(i): null; i++;
        Object v3 = values.size()>= i+1? values.get(i): null; i++;
        Object v4 = values.size()>= i+1? values.get(i): null; i++;
        Object v5 = values.size()>= i+1? values.get(i): null; i++;
        Object v6 = values.size()>= i+1? values.get(i): null; i++;
        Object v7 = values.size()>= i+1? values.get(i): null; i++;
        Object v8 = values.size()>= i+1? values.get(i): null; i++;
        Object v9 = values.size()>= i+1? values.get(i): null; i++;
        Object v10 = values.size()>= i+1? values.get(i): null; i++;
        Object v11 = values.size()>= i+1? values.get(i): null; i++;
        Object v12 = values.size()>= i+1? values.get(i): null; i++;
        Object v13 = values.size()>= i+1? values.get(i): null; i++;
        Object v14 = values.size()>= i+1? values.get(i): null; i++;
        Object v15 = values.size()>= i+1? values.get(i): null; i++;
        Object v16 = values.size()>= i+1? values.get(i): null; i++;
        Object v17 = values.size()>= i+1? values.get(i): null; i++;
        Object v18 = values.size()>= i+1? values.get(i): null; i++;
        Object v19 = values.size()>= i+1? values.get(i): null; i++;
        Object v20 = values.size()>= i+1? values.get(i): null; i++;
        Object v21 = values.size()>= i+1? values.get(i): null; i++;
        Object v22 = values.size()>= i+1? values.get(i): null; i++;
        Object v23 = values.size()>= i+1? values.get(i): null; i++;
        Object v24 = values.size()>= i+1? values.get(i): null; i++;
        Object v25 = values.size()>= i+1? values.get(i): null; i++;
        Object v26 = values.size()>= i+1? values.get(i): null; i++;
        Object v27 = values.size()>= i+1? values.get(i): null; i++;
        Object v28 = values.size()>= i+1? values.get(i): null; i++;
        Object v29 = values.size()>= i+1? values.get(i): null; i++;
        Object v30 = values.size()>= i+1? values.get(i): null; i++;
        Object v31 = values.size()>= i+1? values.get(i): null; i++;
        Object v32 = values.size()>= i+1? values.get(i): null; i++;
        Object v33 = values.size()>= i+1? values.get(i): null; i++;
        Object v34 = values.size()>= i+1? values.get(i): null; i++;
        Object v35 = values.size()>= i+1? values.get(i): null; i++;
        Object v36 = values.size()>= i+1? values.get(i): null; i++;
        Object v37 = values.size()>= i+1? values.get(i): null; i++;
        Object v38 = values.size()>= i+1? values.get(i): null; i++;
        Object v39 = values.size()>= i+1? values.get(i): null; i++;
        Object v40 = values.size()>= i+1? values.get(i): null; i++;
        Object v41 = values.size()>= i+1? values.get(i): null; i++;
        Object v42 = values.size()>= i+1? values.get(i): null; i++;
        Object v43 = values.size()>= i+1? values.get(i): null; i++;
        Object v44 = values.size()>= i+1? values.get(i): null; i++;
        Object v45 = values.size()>= i+1? values.get(i): null; i++;
        Object v46 = values.size()>= i+1? values.get(i): null; i++;
        Object v47 = values.size()>= i+1? values.get(i): null; i++;
        Object v48 = values.size()>= i+1? values.get(i): null; i++;
        Object v49 = values.size()>= i+1? values.get(i): null; i++;
        
        for(Integer j=0; j<fields.size(); j++)
        {
            String f = '$' + fields.get(j);
            configFilter = configFilter.replace(f, ':v' + j);
        }

        String ns = StringUtility.FXNamespace();
        String soql = 'SELECT ' + config.Override_Fields__c + ' FROM ' 
            + ns + 'Override__c WHERE IsDeleted=false AND '
            + ns + 'IsActive__c=true AND ' 
            + ns + 'Applies_to_SObject__c INCLUDES (\'' + appliesTo + '\') AND '
            + configFilter;

        if(!String.isBlank(config.Sort_Clause__c))
        {
            soql += ' ORDER BY ' + config.Sort_Clause__c;
        }

        if(!String.isBlank(String.valueOf(config.Limit__c)))
        {
            soql += ' LIMIT ' + config.Limit__c;
        }        
        return Database.query(soql);
    }
    
}