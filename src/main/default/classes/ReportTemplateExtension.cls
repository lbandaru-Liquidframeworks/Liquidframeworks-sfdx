global with sharing class ReportTemplateExtension
{
    private ApexPages.StandardController controller;

    private sObject srecord { get; set; }
    global String PagePath {get; private set;}

    global ReportTemplateExtension(ApexPages.StandardController controller)
    {
       this.controller = controller;
       srecord = controller.getRecord();
       SetPagePath();
    }


    //for testing
    // for test purposes
    global ReportTemplateExtension(sobject record)
    {
        srecord = record;
        SetPagePath();
    }

    // This method is deprecated. DO NOT USE THIS. IT DOES NOTHING
    global ReportTemplateExtension(String entityId) {

    }

    // rluo 06/04/2014
    // mingle card #2301
    // for console, the pagePath will always be 'apex'
    // for Community user, the pagePage will be the Name of the Community
    // this is used to set a hidden text in OpenReport visualForce page. When clicking the report button, this pagePath needs to be in the url.
    void SetPagePath()
    {
       string path = URL.getCurrentRequestUrl().getPath();
       if(path .startsWith('/'))
       {
            path = path.subString(1, path .length()-1);
       }
       PagePath  = path.split('/',0).get(0);
    }

    global ReportTemplateExtension()
    {
        SetPagePath();
    }

    global Component.Apex.Form getForm()
    {

        string namespace = UtilityGetNamespace.CurrentNamespace();
        Component.Apex.Form form = new Component.Apex.Form();
        form.id = 'openReportForm';

        Component.Apex.PageBlock pageBlock = new Component.Apex.PageBlock();
        pageBlock.id = 'reportPageBlock';
        pageBlock.title='';
        pageBlock.mode = 'maindetail';
        form.ChildComponents.Add(pageBlock);


         List<Report_Template__c> reports = GetReportTemplates(srecord);

         //System.debug('reprot count=' + reports.size());

        if(reports.isEmpty()) return form;

        Component.Apex.PageBlockButtons cmdButtons = new Component.Apex.PageBlockButtons();
        cmdButtons.location = 'top';

        for(Report_Template__c rt : reports)
        {
            Component.Apex.CommandButton command = new Component.Apex.CommandButton();

            command.onclick = 'jsOpenReport("' + srecord.Id  + '", "' + rt.Id + '", "' + rt.SObject__c + '", "' + namespace + '");';

            command.oncomplete='refreshPage();';

            command.id = 'rt' + rt.Id;
            command.value = rt.Name;
            command.title = 'Open ' + rt.Name + ' report';
            command.rendered = true;
            Set<string> ops = new Set<string>();
            ops.add('redirectPanel');
            command.rerender = ops;

            cmdButtons.ChildComponents.Add(command);

        }

        pageBlock.ChildComponents.Add(cmdButtons);

        return form;
    }

    global static List<Report_Template__c> GetReportTemplates(sObject obj)
    {
        string namespace = UtilityGetNamespace.CurrentNamespace().toLowerCase();
        DescribeSObjectResult  desObj= obj.getSObjectType().getDescribe();
        String theQuery = 'SELECT ';
        string sep = '';

        Set<string> types = new Set<string>();
        types.add('ID');
        types.add('STRING');
        types.add('PICKLIST');
        types.add('REFERENCE');

        Set<string> fieldNames = new Set<string>();
        Map<String, Schema.SObjectField> objFields = desObj.fields.getMap();

        Boolean trimNamespace = namespace != '';
        for(SObjectField field : objFields.values())
        {
            Schema.DescribeFieldResult dr = field.getDescribe();
            if(!dr.isAccessible() || !types.contains(string.valueOf(dr.getType()))) continue;
            theQuery += sep + dr.getName();
            sep = ',';
            string fieldName = dr.getName().toLowerCase();
            fieldNames.add(fieldName);
            if(trimNamespace) fieldNames.add(fieldName.replace(namespace, ''));
        }



        theQuery += ' FROM  ' + desObj.getName() + ' WHERE Id=\'' + obj.get('Id') + '\'';

        sObject source = Database.query(theQuery).get(0);

        string jobFilter = '';

        string accountField = namespace + 'account__c';
        string customerField = namespace + 'customeraccount__c';
        string segmentField = namespace + 'segment__c';
        string officeField = namespace + 'office__c';
        string jobTypeField = namespace + 'job_type__c';

        string query = 'SELECT Id, Name, ' + namespace + 'SObject__c FROM ' + namespace + 'Report_Template__c ';
        query += ' WHERE IsDeleted=false AND ' + namespace + 'SObject__c=\'' + desObj.getName() + '\'';

        if(fieldNames.contains('recordtypeid'))
        {
            string col = namespace + 'SObject_Record_Type_Id__c';

            query += ' AND (' + col + '= null OR ' + col + '=\'' +  source.get('recordtypeid') + '\')';
        }

        string jobField = namespace + 'job__c';

        if(fieldNames.contains(jobField) && source.get(jobField) != null)
        {
            object jobID = source.get(jobField);

            Job__c job = [SELECT CustomerAccount__c, Office__c, Segment__c, RecordType.DeveloperName FROM Job__c WHERE Id=: String.valueOf(jobID) LIMIT 1];
            sep = '';
            if(job.CustomerAccount__c != null)
            {
                jobFilter += sep +  '(' + accountField + ' = null OR ' + accountField + ' = \'' + job.CustomerAccount__c + '\')';
                sep = ' AND ';
            }
            if(job.Segment__c != null)
            {
                jobFilter += sep +  '(' + segmentField + ' = null OR ' + segmentField + ' = \'' + job.Segment__c + '\')';
                sep = ' AND ';
            }
            if(job.Office__c != null)
            {
                jobFilter += sep +  '(' + officeField + '= null OR ' + officeField + ' = \'' + job.Office__c + '\')';
                sep = ' AND ';
            }

            jobFilter = '((' + jobTypeField + '= null OR ' + jobTypeField + ' = \'' + job.RecordType.DeveloperName + '\') AND ' + jobFilter + ')';

            query += ' AND (' + jobFilter + ')';
        }
        else
        {
            Object fieldValue = null;
            if(fieldNames.contains(customerField))
            {
                fieldValue = source.get(customerField);
                if(fieldValue==null)
                {
                     query = query + ' AND (' + accountField + ' = null)';
                }
                else
                {
                     query = query + ' AND (' + accountField + ' = null OR ' + accountField + ' = \'' + fieldValue + '\')';
                }

            }

            if(fieldNames.contains(segmentField))
            {
                fieldValue = source.get(segmentField);
                if(fieldValue==null)
                {
                     query = query + ' AND (' + segmentField + ' = \'\' OR ' + segmentField + '=null)';
                }
                else
                {
                     query = query + ' AND (' + segmentField + ' = \'\' OR ' + segmentField  + ' = \'' + fieldValue + '\')';
                }
            }

            if(fieldNames.contains(officeField))
            {
                fieldValue = source.get(officeField);
                if(fieldValue==null)
                {
                     query = query + ' AND (' + officeField + ' = null)';
                }
                else
                {
                     query = query + ' AND (' + officeField + ' = null OR ' + officeField + '= \'' + fieldValue + '\')';
                }
            }
        }

        query = query + ' ORDER BY '+namespace+'Sequence_Number__c, Name ';

        //System.debug('query=' + query);

        List<Report_Template__c> items = new  List<Report_Template__c> ();

        for(sObject o:Database.query(query))
        {
           items.add((Report_Template__c)o);
        }
        return items;
    }
}