global virtual with sharing class FXEditorController
{
    global FXEditorController(ApexPages.StandardController controller) 
    {  
        Init();
    }  

    global virtual void Init()
    {
        Map<String, String> params = System.currentPageReference().getParameters();  
        IsInsert = !params.containsKey('id');

        LoadUserInfo();  

        if(params.containsKey('retURL'))
        {
            String p = params.get('retURL');
            Matcher mKeyPrefix =  Pattern.compile('/[a-zA-Z0-9]{3}(/|\\?)(.)*').matcher(p);
            if(mKeyPrefix.matches())
            {
                ReturnUrlObjectId = p.substring(1, 4);
            }                
            else
            {
                ReturnUrlObjectId = p.replace('/', '');
            }              
        }
        if(params.get('clone')=='1')
        {
            String sourceId = params.get('common.udd.actions.ActionsUtilORIG_URI').replace('/e', '').replace('/', '');           
            sObject source = GetSObject(sourceId, true);
            EntityObj = source.clone();
        }
        else if(params.containsKey('id'))
        {
            EntityId = params.get('id');
            EntityObj = GetSObject(EntityId, false);                    
        }        
        else
        {
            Set<String> fieldIds = new Set<String>();
            for(String key : params.keySet())
            {
                if(key.startsWith('CF00N'))
                {
                    String p = key.replace('_lkid', '');
                    String fieldId = StringUtility.GetCasesafeId(p.replace('CF', ''));
                    fieldIds.add(fieldId); 
                }
            }
            if(!fieldIds.isEmpty())
            {
                List<CustomFieldInfo__c> cfInfo = [SELECT CustomObject__c, DeveloperName__c, FullName__c, FieldDefinitionId__c  FROM CustomFieldInfo__c WHERE FieldDefinitionId__c IN :fieldIds];               
                sObjectType sType = Schema.getGlobalDescribe().get(cfInfo.get(0).CustomObject__c);

                EntityRecordTypeId = params.containsKey('RecordType')? (Id)params.get('RecordType') : null;
               
                EntityObj = CreateNewInstance(sType, EntityRecordTypeId);

                for(CustomFieldInfo__c cf : cfInfo)
                {
                    String lkIdKey = 'CF' + cf.FieldDefinitionId__c.substring(0, 15) + '_lkid';
                    if(params.containsKey(lkIdKey))
                    {
                        EntityObj.put(cf.DeveloperName__c, params.get(lkIdKey));
                    }
                }
            } 
            else if(params.containsKey('RecordType') && !params.get('RecordType').startsWith('012000000000000')) 
            {
                EntityRecordTypeId = (Id)params.get('RecordType');
                RecordType rt = [SELECT Id,SobjectType FROM RecordType WHERE Id=:EntityRecordTypeId];
                Schema.sObjectType objType = Schema.getGlobalDescribe().get(rt.SobjectType);
                EntityObj = CreateNewInstance(objType, EntityRecordTypeId);
            } 
            else if(params.containsKey('EntityType'))
            {
                EntityType = params.get('EntityType');
                EntityObj = CreateNewInstance(Schema.getGlobalDescribe().get(EntityType), null); 
   
            }
            else if(ReturnUrlObjectId.length() == 3) //keyprefix
            {
                for(sObjectType t : Schema.getGlobalDescribe().values())
                {
                    Schema.DescribeSObjectResult dsr = t.getDescribe();
                    if(ReturnUrlObjectId.equals(dsr.getKeyPrefix()))
                    {                        
                        EntityObj = CreateNewInstance(t, null);
                        break;
                    }                   
                }
            }
     
        }
        if(String.isBlank(EntityRecordTypeId))
        {
            EntityRecordTypeId = '012000000000000AAA';
        }

        if(EntityObj != null)
        {
            Schema.DescribeSObjectResult sobjDsr = EntityObj.getSObjectType().getDescribe();
            EntityType = sobjDsr.getName();
            EntityTypeDisplayLabel = sobjDsr.getLabel();
        }   

        FXNamespace = StringUtility.FXNamespace();  
        FXNamespaceWithoutUnderscores = FXNamespace.replace('__', '');

        List<LayoutDescribe.EditLayoutSection> sections = Test.isRunningTest()? 
                LayoutDescribe.GetEditLayoutSectionTestData(EntityType) 
                : GetLayout(EntityType, EntityRecordTypeId).editLayoutSections; 
        LayoutSections = new List<LayoutSection>();
        for(LayoutDescribe.EditLayoutSection s : sections)
        {
            LayoutSections.add(new LayoutSection(s));
        }

        if(String.isBlank(EntityType) && Test.isRunningTest())
        {
            EntityType = params.get('EntityType');
        }

        List<LayoutDescribe.FieldInfo> fields = Test.isRunningTest()? LayoutDescribe.GetFieldInfoTestData(EntityType) 
                : GetLayout(EntityType, EntityRecordTypeId).getFieldInfo();

        LayoutFields = new List<LayoutField>();
        for(LayoutDescribe.FieldInfo f: fields)
        {
            LayoutFields.add(new LayoutField(f));
        }
    }

    static sObject CreateNewInstance(sObjectType objType, Id recordTypeId)
    {
        DescribeSObjectResult dsr = objType.getDescribe();
        sObject obj = objType.newSObject(recordTypeId, true); 
        sObject result = objType.newSObject(recordTypeId, false);
        Map<String, Schema.sObjectField> fields = dsr.fields.getMap();
        for(Schema.sObjectField f : fields.values())
        {
            Schema.DescribeFieldResult dfr = f.getDescribe();
            if(!dfr.isCreateable()) continue;
            result.put(f, obj.get(f));
        }
        if(fields.containsKey('recordtypeid'))
        {
            result.put('RecordTypeId', recordTypeId);
        }
        return result;
    }
    sObject GetSObject(String idStr, Boolean isForCloning)
    {
        Id objId = Id.valueOf(idStr);
        Schema.DescribeSObjectResult r = objId.getSObjectType().getDescribe();
        EntityType = r.getName();

        Map<String, sObjectField> fieldMap = r.fields.getMap();
        Set<String> fields = new Set<String>();
        //fields.addAll(fieldMap.keySet());

            
        for(sObjectField f : fieldMap.values())
        {
            Schema.DescribeFieldResult dfr = f.getDescribe();

            if(isForCloning && dfr.isUnique()) continue;
            fields.add(dfr.getName());           
        }
        String soql = 'SELECT ' + String.join(new List<String>(fields), ',') + ' FROM ' + r.getName() + ' WHERE Id=:objId LIMIT 1';
        sObject obj =  Database.query(soql).get(0);
        if(fieldMap.containsKey('recordtypeid'))
        {
            EntityRecordTypeId = String.valueOf(obj.get('RecordTypeId'));
        }   
        return obj;
    }

    void LoadUserInfo()
    {
        List<String> userFields = new List<String>();
        for(Schema.SObjectField f :  User.sObjectType.getDescribe().fields.getMap().values())
        {
            Schema.DescribeFieldResult dfr = f.getDescribe();
            if(!dfr.isAccessible() || !dfr.isCustom()) continue;
            userFields.add(dfr.getName());
        }
        List<String> contactFields = new List<String>();
        for(Schema.SObjectField f :  Contact.sObjectType.getDescribe().fields.getMap().values())
        {
            Schema.DescribeFieldResult dfr = f.getDescribe();
            if(!dfr.isAccessible() || !dfr.isCustom()) continue;
            contactFields.add(dfr.getName());
        }
        
        String userId = System.UserInfo.getUserId();
        String userSoql = 'SELECT ' + String.join(userFields, ', ') + 
            + ', Contact.' +  String.join(contactFields, ', Contact.')
            + ' FROM User WHERE Id=:userId';
        FXUserInfo = Database.query(userSoql);
        if(FXUserInfo.Contact==null)
        {
            String contactSoql = String.format('SELECT {1} FROM Contact WHERE {0}User__c=:userId LIMIT 1',
                new String[]{StringUtility.FXNamespace(), String.join(contactFields, ',')});
            List<Contact> contacts = Database.query(contactSoql);
            if(!contacts.isEmpty())
            {
               FXUserInfo.Contact = contacts.get(0);
            }
        }

        CurrentUserContactOffice = FXUserInfo.Contact==null? '':FXUserInfo.Contact.Office__c;

    }

    

    LayoutDescribe.RecordTypeLayout GetLayout(String objType, String recordTypeId)
    {     
        Map<String, LayoutDescribe.RecordTypeLayout> layoutCache = null;
        if(!String.isBlank(LayoutJsonString))   
        {
             layoutCache = (Map<String, LayoutDescribe.RecordTypeLayout>)JSON.deserialize(LayoutJsonString, 
                Map<String, LayoutDescribe.RecordTypeLayout>.class);
        }
        String key = objType + recordTypeId;
        if(layoutCache == null)
        {
            layoutCache = new Map<String, LayoutDescribe.RecordTypeLayout>();
        }
        if(layoutCache.containsKey(key))
        {
            return layoutCache.get(key);
        }
        LayoutDescribe.RecordTypeLayout layout = MetadataService.getLayout(objType, recordTypeId);
        layoutCache.put(key, layout);
        LayoutJsonString = JSON.serialize(layoutCache);
        return layout;
        
    }   

    global virtual PageReference save() 
    {       
        Database.UpsertResult r = Database.upsert(EntityObj, false);
        if(r.isSuccess()) 
        {
            return redirectPage(false);
        }        
        String msg = '';
        for(Database.Error err : r.getErrors()) {
            msg += err.getMessage();
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
        return null;                             
    }

  
    global virtual PageReference doCancel()
    {
        String pageUrl = System.currentPageReference().getParameters().get('retURL');
        PageReference pageRef = new PageReference(pageUrl);
        pageRef.setRedirect(true);
        return pageRef;
    }


    global virtual PageReference saveAndNew() 
    {
        try
        {
            upsert EntityObj;  
            return redirectPage(true);
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL, ex.getMessage()));
            return null;
        }
    }

    PageReference redirectPage(Boolean isSaveAndNew)
    {
        String pageUrl = '';
        if(!isSaveAndNew)
        { 
            Map<String, String> params = System.currentPageReference().getParameters();
            if(params.get('clone')=='1' && !String.isBlank(EntityObj.Id))
            {
                 pageUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + EntityObj.Id;    
            }
            else if(StringUtility.IsValidID(ReturnUrlObjectId))
            {
                pageUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + ReturnUrlObjectId;
            }
            else
            {
                 pageUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + EntityObj.Id; 
            }            
        }
        else
        {
            PageReference pr = ApexPages.currentPage();  
            pageUrl = pr.getUrl();
        }

        PageReference pageRef = new PageReference(pageUrl);
        if(isSaveAndNew)
        {
            Map<String, String> params = pageRef.getParameters(); 
            params.clear(); 
            if(!String.isBlank(EntityRecordTypeId) && !EntityRecordTypeId.startsWith('012000000000000'))
            {
                params.put('RecordType', EntityRecordTypeId);
            }
            else
            {
                params.put('EntityType', EntityType);
            }
            params.put('retURL', EntityObj.Id);

        }
        pageRef.setRedirect(true);
        return pageRef;
    }   

    global virtual String GetEditorPageUrl()
    {
        PageReference pr = ApexPages.currentPage();  
        return pr.getUrl();
    }
    
    global sObject EntityObj {get;set;}
    global String EntityType {get;set;}
    global String EntityTypeDisplayLabel {get;set;}
    global String EntityId {get;set;}    
    global String ReturnUrlObjectId {get;set;}
    global User FXUserInfo {get;set;}

    global String CurrentUserContactOffice {get;set;}
    global Boolean IsInsert {get;set;}
    
    global String FXNamespace { get; set;}   
    global String FXNamespaceWithoutUnderscores { get; set;}
    global List<LayoutSection> LayoutSections {get;set;}
    global List<LayoutField> LayoutFields {get;set;}        
    global String LayoutJsonString {get;set;}


    global String EntityRecordTypeId {get; protected set;}
    
}