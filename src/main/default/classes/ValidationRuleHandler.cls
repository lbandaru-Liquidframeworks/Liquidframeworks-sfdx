public class ValidationRuleHandler implements IFXWorker, Schedulable
{
    public virtual SvcResult DoWork(String param)
    {
        String msg = ValidationRuleHandler.RefreshMobileRules();
        SvcResult r = new SvcResult();
        r.Message = msg;
        return r;
    }

    public virtual void execute(SchedulableContext sc)
    {
        ValidationRuleHandler.RefreshMobileRules();
    }

    public static String RefreshMobileRules()
    {
        String rulesStr = ValidationRuleHandler.GetMobileRules();               
        return StaticResourceHandler.UpsertFile('FX_Mobile_Rules', rulesStr);   
    }   
   
    @testVisible
    public static List<SingleRuleServiceResponse> GetValidationRuleInfo()
    {   
        List<SingleRuleServiceResponse> results = new List<SingleRuleServiceResponse>();
        ValidationRuleServiceResponse rules = GetValidationRules();

        String apiUrlRoot = URL.getSalesforceBaseUrl().toExternalForm();
        Map<String, sObjectType> allTypes = Schema.getGlobalDescribe();

        String ns = StringUtility.FXNamespace();

        for(ValidationRuleEntry r : rules.records)
        {
            if(!allTypes.containsKey(r.GetEntityType()) && !allTypes.containsKey(ns + r.GetEntityType())) continue;

            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
            req.setHeader('Content-Type', 'application/json');

            String endPoint = String.format('{0}/services/data/v33.0/tooling/sobjects/ValidationRule/{1}',
                new String[]{apiUrlRoot, r.Id});

            req.setEndpoint(endPoint);
            req.setMethod('GET');
            Http h = new Http();
            HttpResponse res = null;
            if(Test.isRunningTest())
            {
                // Create a fake response
                res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"Id" : "03d360000002t7DAAQ","ValidationName" : "Single_Assignment","LastModifiedDate" : "2016-05-02T18:34:47.000+0000","Metadata" : {"errorConditionFormula" : "1=1","errorDisplayField" : null,"errorMessage" : "You may only select one location value. Please clear the other value."},"FullName" : "Crew_Planning__c.Single_Assignment"}');
                res.setStatusCode(200);
            }
            else
            {
                res = h.send(req); 
            }

            ValidationRuleHandler.SingleRuleServiceResponse m = (ValidationRuleHandler.SingleRuleServiceResponse)JSON.deserialize(res.getBody(), 
                ValidationRuleHandler.SingleRuleServiceResponse.class);
            results.add(m);

        }

        return results;  
           
    }


    @testVisible
    public static ValidationRuleServiceResponse GetValidationRules()
    {     
        String apiUrlRoot = URL.getSalesforceBaseUrl().toExternalForm();
        HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
            req.setHeader('Content-Type', 'application/json');
            String endPoint = String.format('{0}/services/data/v35.0/tooling/query?q=Select+Id,EntityDefinition.DeveloperName+From+ValidationRule+WHERE+Active=true',
                new String[]{apiUrlRoot});

            req.setEndpoint(endPoint);
            req.setMethod('GET');
            Http h = new Http();
            HttpResponse res = null;
            if(Test.isRunningTest())
            {
                // Create a fake response
                res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"size" : 1,"totalSize" : 1,"records" : [ {"Id" : "03d360000002t7CAAQ","EntityDefinition" : {"DeveloperName" : "Crew_Planning"}}]}');
                res.setStatusCode(200);
            }
            else
            {
                res = h.send(req); 
            }
            String rawStr = res.getBody();

        System.debug(rawStr);

        ValidationRuleHandler.ValidationRuleServiceResponse m = (ValidationRuleHandler.ValidationRuleServiceResponse)JSON.deserialize(rawStr, ValidationRuleHandler.ValidationRuleServiceResponse.class);

           
        return m;

             
    }

    public static String GetMobileRules()
    {
        List<SingleRuleServiceResponse> rules = GetValidationRuleInfo();

        Map<String, Map<String, RuleMetadataInfoExt>> objRules =  new Map<String, Map<String, RuleMetadataInfoExt>>();
        for(SingleRuleServiceResponse r : rules)
        {
            String entityType = r.GetEntityType();
            if(!objRules.containsKey(entityType))
            {
                objRules.put(entityType, new Map<String, RuleMetadataInfoExt>());
            }

            objRules.get(entityType).put(r.ValidationName, r.GetRuleMetadataInfoExt());
        }


        return 'window.FX_Mobile_Rules = {\r\n"validationRules" : ' + JSON.serializePretty(objRules) + '\r\n};';        
    }

    public class ValidationRuleServiceResponse 
    {
        public Integer size {get; set;}
        public Integer totalSize {get; set;}
        public List<ValidationRuleEntry> records {get;set;}
    }


    public class SingleRuleServiceResponse
    {
        public String Id {get; set;}
        public String ValidationName {get; set;}
        public String LastModifiedDate {get; set;}
        public RuleMetadataInfo MetaData {get; set;}
        public String FullName {get; set;}
        public String GetEntityType()
        {
            //System.debug('FullName: ' + FullName);
            return FullName.split('[.]')[0];
        }

        public RuleMetadataInfoExt GetRuleMetadataInfoExt()
        {
            return new RuleMetadataInfoExt(ValidationName, Metadata);
        }        
    }
    public virtual class RuleMetadataInfo 
    {
        public String errorConditionFormula {get;set;}
        public String errorDisplayField {get;set;}
        public String errorMessage {get;set;}
    }

    public class RuleMetadataInfoExt extends RuleMetadataInfo
    {
        public RuleMetadataInfoExt(){}
        public RuleMetadataInfoExt(String name, RuleMetadataInfo b)
        {
            fullName = name;
            errorConditionFormula = b.errorConditionFormula;
            errorDisplayField = b.errorDisplayField;
            errorMessage = b.errorMessage;
        }        
        public String fullName {get; set; }
    }

    public class ValidationRuleEntry
    {
        public String Id {get;set;}
        public sObjectTypeInfo EntityDefinition {get;set;}
        public  String GetEntityType()
        {
            return EntityDefinition.DeveloperName + '__c';
        }

    }

    public class sObjectTypeInfo
    {
        public String DeveloperName {get;set;}
    }

    
}