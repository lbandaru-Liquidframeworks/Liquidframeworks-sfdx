public with sharing class QuoteExtension 
{
    private ApexPages.StandardController controller;
    private final string prefix;
    private final string typeName;
    public sObject srecord { get; set; } 
    
    Map<String, String> JobRecordTypes {get;set;}   
    public static Boolean HasQuoteV1
    {
        get
        {
            InitQuoteV1Info();
            return HasQuoteV1Internal;
        }
    }
    public static String QuoteV1FieldName
    {
        get
        {    
            InitQuoteV1Info();      
            return QuoteV1FieldNameInternal;
        }
    }
    static String QuoteV1FieldNameInternal = null;
    static Boolean HasQuoteV1Internal = null;
    static void InitQuoteV1Info()
    {
        if(String.isBlank(QuoteV1FieldNameInternal))
        { 
            QuoteV1FieldNameInternal = StringUtility.FXNamespace().toLowercase() + 'quote__c';
            HasQuoteV1Internal = Job__c.sObjectType.getDescribe().fields.getMap().keySet().contains('quote__c'); 
        }
    }
  
    public QuoteExtension(ApexPages.StandardController controller) 
    {     
       this(controller.getId());
       this.controller = controller;
       srecord = controller.getRecord();
       Init();
    }
    
    void Init()
    {
          Ticket__c t= (Ticket__c)srecord;
          TktEntity  = [SELECT Job__c, Category__c FROM Ticket__c WHERE Id =: t.Id LIMIT 1];
          isQuote  = TktEntity.Category__c == 'Quote';
          
          JobRecordTypes = new Map<String, String>();

            List<RecordTypeInfo> infos = Job__c.sObjectType.getDescribe().getRecordTypeInfos();
            for(RecordTypeInfo i : infos)
            {
                //// Ignore the Master Record Type, whose Id is always '012000000000000AAA'. We check the Id because Name can change depending on the user's language.
                if(!i.isAvailable() || String.valueOf(i.getRecordTypeId()) == '012000000000000AAA') continue;
                JobRecordTypes.put(i.RecordTypeId, i.Name);
            }            
            
    }
    // for test purposes
    public QuoteExtension(Id controllerId, sobject record)
    {
        this(controllerId);
        srecord = record;
        Init();
    }
    
    public QuoteExtension(Id controllerId) 
    {
       this.typeName = UtilityGetTypeNameFromId.CurrentTypeName(controllerId);
       this.prefix = UtilityGetNamespace.CurrentNamespace();
    }
    
    Ticket__c TktEntity { get; set; }


    List<String> GetJobFields() {
        List<String> fields = new List<String>();

        Map<string, SObjectField> fieldMap = Schema.sObjectType.Job__c.fields.getMap();
        for(String f: fieldMap.keySet())
        {       
            DescribeFieldResult res = fieldMap.get(f).getDescribe();
            if(!res.isAccessible() || !res.isUpdateable()) continue;
            fields.add(f);
        }

        return fields;
    }

    String GetJobFieldsAsString() {
        String sep = '';
        String soql = '';
        List<String> fields = GetJobFields();
        for(String f: fields)
        {          
            soql += sep + f;
            sep = ',';
        }

        return soql;
    }

    Job__c JobEntity
    {
        get
        {
            if(jobEntityLocal == null && TktEntity != null)
            {              
                String soql = 'SELECT ' + GetJobFieldsAsString() + ' FROM Job__c where Id = \'' + TktEntity.Job__c + '\'   LIMIT 1';
                jobEntityLocal = (Job__c)Database.query(soql);
            }
            return jobEntityLocal;
        }
    }
    Job__c jobEntityLocal=null;

    public PageReference convertToJob() 
    {      
        if(!string.isBlank(HiddenTextValue))
        {
            string namespace = UtilityGetNamespace.CurrentNamespace();

            Job__c s = JobEntity;          

            Job__c job = s.clone(false, false, false, false);
            job.RecordTypeId = HiddenTextValue;
            if(QuoteExtension.HasQuoteV1 == true)
            {                
                job.put(QuoteExtension.QuoteV1FieldName, TktEntity.Id);
            }
            job.SyncID__c = StringUtility.newGuid();
            job.Tracking_Number__c = null;
            job.Created_in_Mobile__c = false;
            job.Category__c = 'Job';
            job.Status__c = null;
            job.Job_Number__c = null;
            
            insert job;

            redirectUrl = '/' + job.Id;

            shouldRedirect = true;                     
            return null;
        }
       
        return ApexPages.currentPage();       
    }
  
    public Component.Apex.Form getForm() 
    {   
        if(TktEntity == null || TktEntity.Category__c != 'Quote')
        {
            return null;
        } 
            
        Component.Apex.Form form = new Component.Apex.Form();

        form.id = 'quoteToJobForm';  

        Component.Apex.PageBlock pageBlock = new Component.Apex.PageBlock();
        pageBlock.id = 'pageBlock';
        pageBlock.title='';
        pageBlock.mode = 'maindetail';
        form.ChildComponents.Add(pageBlock);      
         
        
        string jobObjectType = this.prefix  + 'Job__c';

        
        if(JobRecordTypes.isEmpty())
        {
            return form;
        }

        Component.Apex.PageBlockButtons cmdButtons = new Component.Apex.PageBlockButtons();
        cmdButtons.location = 'top';

        Id objRecordTypeID = (Id)srecord.get('RecordTypeId');       
        
        
        for(String recordTypeId : JobRecordTypes.keySet())
        {        
          
            if(recordTypeId == JobEntity.RecordTypeId)  continue;
            Component.Apex.CommandButton command = new Component.Apex.CommandButton();

            command.onclick = 'jsSetNewJobRecordType("' + recordTypeId  + '");';

            command.oncomplete='refreshPage();';

            command.id = 'rt' + recordTypeId;
            command.value = JobRecordTypes.get(recordTypeId);
            command.title = 'Create ' + JobRecordTypes.get(recordTypeId);
            command.expressions.action = '{!convertToJob}';
            command.rendered = true;  
            Set<string> ops = new Set<string>();
            ops.add('redirectPanel');
            command.rerender = ops;

            cmdButtons.ChildComponents.Add(command); 

        }         

        pageBlock.ChildComponents.Add(cmdButtons);      

        Component.Apex.InputHidden hidden = new Component.Apex.InputHidden();
        hidden.id = 'recordTypeForNewJob';
        hidden.expressions.value = '{!HiddenTextValue}';
        form.ChildComponents.Add(hidden); 

        return form;
    }   
  

    public string HiddenTextValue { get; set; }

    public Boolean shouldRedirect {public get; private set;}
    public String redirectUrl {public get; private set;}
    public Boolean isQuote {public get; private set;}
    
}