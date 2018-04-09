public class eFormHandler
{
    public static void InitForms(Set<String> forms)
    {
        if(FXSettingHelper.TurnOffJobPropagator || System.isFuture()) return;

        Set<String> formsOfInterest = new Set<String>();
        formsOfInterest.addAll(forms);
        Map<String, sObjectType> types = Schema.getGlobalDescribe();
        for(String f: forms)
        {
            if(!types.containsKey(f)) 
            {
                formsOfInterest.remove(f);
                continue;
            }
            sObjectType t = types.get(f);
            Schema.DescribeSObjectResult r = t.getDescribe();
            for(Schema.ChildRelationship c : r.getChildRelationships())
            {
                Schema.SObjectType objType = c.getChildSObject();

                Schema.DescribeSObjectResult child = objType.getDescribe();
                if(!child.isCustom()) continue;
                Schema.DescribeFieldResult dfr = c.getField().getDescribe();

                if(dfr.getRelationshipOrder()>=0)
                {
                    String childTypeName = child.getName();  
                    formsOfInterest.add(childTypeName); 
                }  
            }    
        }
        InitFormsAsync(formsOfInterest, UserInfo.getSessionId());
    }

    //Enforce KeySObject Singleton
    //Validate eForm Object has a Master/Detail or Lookup field referring to Key_SObject__c
    public static void Validate(List<eForm_Config__c> items, Boolean isInsert)
    {
        if(FXSettingHelper.TurnOffJobPropagator) return;

        Set<String> forms = new Set<String>();
        Set<Id> eConfigIds = new Set<Id>();
        for(eForm_Config__c c : items)
        {
            forms.add(c.eForm_SObject__c);
            if(!isInsert)
            {
                eConfigIds.add(c.Id);
            }
        }
        List<eForm_Config__c> dbItems = (isInsert==true)? [SELECT Id, eForm_SObject__c, Key_SObject__c FROM eForm_Config__c WHERE IsDeleted=false AND eForm_SObject__c IN :forms]
            :[SELECT Id, eForm_SObject__c, Key_SObject__c FROM eForm_Config__c WHERE Id NOT IN :eConfigIds AND IsDeleted=false AND eForm_SObject__c IN :forms];

        Map<String, Set<String>> formKeyObjs = new Map<String, Set<String>>();
        for(eForm_Config__c c : dbItems)
        {
            if(!formKeyObjs.containsKey(c.eForm_SObject__c))
            {
                formKeyObjs.put(c.eForm_SObject__c, new Set<String>());
            }
            formKeyObjs.get(c.eForm_SObject__c).add(c.Key_SObject__c);
        }
        
        for(eForm_Config__c c: items)
        {
            String msg = ''; 
            String sep = '';

            if(!formKeyObjs.containsKey(c.eForm_SObject__c))
            {
                formKeyObjs.put(c.eForm_SObject__c, new Set<String>());
            } 
            Set<String> subObjs =  formKeyObjs.get(c.eForm_SObject__c);         
            subObjs.add(c.Key_SObject__c);

            if(subObjs.size() > 1) 
            {
                subObjs.remove(c.Key_SObject__c);
                msg += c.eForm_SObject__c + ' has been configured for ' + String.join(new List<String>(subObjs), ', ') + '. Each FX Form can only be configured for one Key SObject.';
                sep = '<br/>';
            }
            //msg += ValidateReferenceToKeySobject(c);

            msg += sep +  ValidateReferenceToKeySobject(c);
            if(!String.isBlank(msg) && !Test.isRunningTest())
            {
                c.addError(msg, false);  
            }                           
        }
    }

    @future(callout=true)
    static void InitFormsAsync(Set<String> forms, String userSessionId)
    {
        for(String f: forms)
        {
            CreateFXFields(f, userSessionId);
        }    

        List<ApexTrigger> triggers = [SELECT Id,Name,TableEnumOrId FROM ApexTrigger WHERE TableEnumOrId IN :forms AND Name LIKE '%Trigger_FX5Auto'];
        for(ApexTrigger t : triggers)
        {
            forms.remove(t.TableEnumOrId);
        }
        for(String f: forms)
        {
            CreateTrigger(f, userSessionId);
        }       
    }

   
    static void CreateTrigger(String objType, String userSessionId)
    {        
        String triggerName = objType.removeEndIgnoreCase('__c').replace('_', '') + 'Trigger_FX5Auto';
        String bodyStr = 'trigger ' + triggerName + ' on ' + objType + ' (before insert, before update, after insert, after update) { if(trigger.isBefore) {[ns]StringUtility.setSyncID(trigger.new, \'SyncId__c\'); } else { [ns]JobPropagatorExt.Run(trigger.new); }} ';    

        String ns = StringUtility.FXNamespace().replace('__', '.');

        bodyStr = bodyStr.replace('[ns]', ns);

        ApexTrigger t = new ApexTrigger(Name = triggerName, 
            TableEnumOrId = objType,
            Body = bodyStr);

        String jsonStr = JSON.serialize(t, true);

        String apiUrl = URL.getSalesforceBaseUrl().toExternalForm() 
            + '/services/data/v40.0/sobjects/ApexTrigger/';

        Post(apiUrl, jsonStr, userSessionId);        
    }

    
    static void CreateFXFields(String eform, String userSessionId)
    {        
        Map<String, sObjectType> types = Schema.getGlobalDescribe();
        if(!types.containsKey(eform)) return;

        Schema.DescribeSObjectResult r = types.get(eform).getDescribe();
        Map<String, SObjectField> fields = r.fields.getMap();

        String apiUrl = URL.getSalesforceBaseUrl().toExternalForm() 
            + '/services/data/v40.0/tooling/sobjects/CustomField/';

        if(!fields.containsKey('Job_Share__c'))
        {   
            String relationshipLabel = r.getLabel() + ' Share';
            String relationshipName = eform.removeEndIgnoreCase('__c')+'Share';
            String jobStr = JSON.serialize(new FieldInfo(eForm + '.Job_Share__c', 
                CreateJobField(relationshipLabel, relationshipName)));
            System.debug(jobStr);
            Post(apiUrl, jobStr, userSessionId);     

        }
        if(!fields.containsKey('SyncId__c'))
        {            
            String syncIdStr = JSON.serialize(new FieldInfo(eForm + '.SyncId__c', CreateSyncIDField()));
            System.debug(syncIdStr);
            Post(apiUrl, syncIdStr, userSessionId);     

        }  
    }

    class FieldInfo
    {
        public FieldInfo(){}

        public FieldInfo(String name, CustomField f)
        {
            FullName = name;
            Metadata = f;
        }
        public String FullName {get;set;}
        public CustomField Metadata {get;set;}
    }

    @testVisible
    static CustomField CreateSyncIDField()
    {
        CustomField f = new CustomField();
        f.label = 'SyncId';
        f.type = 'Text';
        f.length = 50;
        f.description = 'Trigger will populate this property when it is null. It should populate with a guid if possible.';
        f.caseSensitive = false;
        f.inlineHelpText = 'Unique identifier assigned automatically after syncing.';
        f.required = false;
        f.externalId = true;
        f.unique = true;
        return f;
    }


    static CustomField CreateJobField(String relationshipLabel, String relationshipName)
    {
        CustomField f = new CustomField();
        String ns = StringUtility.FXNamespace();
        f.label = 'Job Share';
        f.type = 'Lookup';
        f.description = 'Trigger will populate the value.';        
        f.inlineHelpText = 'Job lookup assigned automatically.';
        f.referenceTo = ns + 'Job__c';
        f.required = false;
        f.relationshipLabel = relationshipLabel;
        f.relationshipName = relationshipName;
        return f;
    }

    @testVisible
    class CustomField
    {
        public String inlineHelpText {get;set;}
        public String description {get;set;}
        public String label {get;set;}
        public String referenceTo {get;set;}
        public String relationshipName {get;set;}
        public String relationshipLabel {get;set;}

        public Boolean required {get;set;}
        public Boolean unique {get;set;}
        public Boolean externalId {get;set;}
        public Boolean caseSensitive {get;set;}
        public String type {get;set;}
        public Integer length {get;set;}
    }

    static void Post(String apiUrl, String body, String userSessionId)
    {
        Httprequest req = new HttpRequest(); 
        req.setEndpoint(apiUrl); 
        req.setMethod('POST'); 
        req.setHeader('Content-Type', 'application/json'); 
        req.setHeader('Authorization', 'OAuth ' + userSessionId); 
        req.setBody(body); 
        Http httpReq = new Http(); 
        if(!Test.isRunningTest()) httpReq.send(req); 
    }
    
    
    static String ValidateReferenceToKeySobject(eForm_Config__c c)
    {
        
        String keyObj = c.Key_SObject__c;
        String form = c.eForm_SObject__c;
        String ns = StringUtility.FXNamespace();
        keyObj = keyObj.replace('FX5__', ns);
        Map<String, SObjectType> types = Schema.getGlobalDescribe();

        if(!types.containsKey(form))
        {
            return 'You must enter the API name of the FX Form object. ' + form + ' does NOT exist or you may have no access. ';
        }
        
        String msg = '';
        Boolean isValid = false;
        List<SObjectField> fields = types.get(form).getDescribe().fields.getMap().values();
        for(SObjectField f: fields)
        {
            DescribeFieldResult dfr = f.getDescribe();
            if(!dfr.isCustom() || dfr.getName()=='Job_Share__c') continue;

            List<Schema.sObjectType> refs = dfr.getReferenceTo();
            if(refs.isEmpty()) continue; 
            Schema.DescribeSObjectResult r = refs.get(0).getDescribe();
            if(!r.isCustom()) continue;

            if(keyObj.equalsIgnoreCase(r.getName()))
            {
                isValid = true;
                break;
            }
        }
        if(!isValid)
        {
            msg = ' The FX Form must have a Master/Detail or Lookup relationship with the object specified in Key SObject. ';
        }
        return msg;

    }
    


}
