global with sharing class WorkflowControllerExtension
{
    private ApexPages.StandardController controller;
    private final string prefix;
    private final string typeName;
    global sObject srecord { get; private set; }

    global String JobKeyPrefix {get; private set;}
    global String TicketKeyPrefix {get; private set;}



    global WorkflowControllerExtension(ApexPages.StandardController controller)
    {
       this(controller.getId());
       this.controller = controller;
       controller.addFields(new List<string>{prefix + 'Status__c'});
       srecord = controller.getRecord();


    }

    // for test purposes
    global WorkflowControllerExtension(Id controllerId, sobject record)
    {
        this(controllerId);
        srecord = record;
    }

    global WorkflowControllerExtension(Id controllerId)
    {
       this.typeName = UtilityGetTypeNameFromId.CurrentTypeName(controllerId);
       this.prefix = UtilityGetNamespace.CurrentNamespace();

       JobKeyPrefix = Job__c.sObjectType.getDescribe().keyPrefix;
       TicketKeyPrefix = Ticket__c.sObjectType.getDescribe().keyPrefix;
    }

    global PageReference executeStatusChange()
    {
        if(!string.isBlank(HiddenTextValue))
        {
            Object oldStatus = this.srecord.get(prefix + 'Status__c');

            try
            {
                this.srecord.put(prefix + 'Status__c', HiddenTextValue);
                upsert srecord;
                String objId = String.valueOf(srecord.get('Id'));


                if(objId.startsWith(JobKeyPrefix) || objId.startsWith(TicketKeyPrefix))
                {
                    Status_History__c sh = new Status_History__c();
                    if(objId.startsWith(JobKeyPrefix))
                    {
                        sh.Job__c = objId;
                    }
                    else
                    {
                        sh.Ticket__c = objId;
                    }
                    sh.New_Status__c = HiddenTextValue;
                    sh.Changed_Date__c = Datetime.now();
                    sh.Changed_By__c = UserInfo.getUserId();
                    insert sh;
                }
            }
            catch(System.DmlException dmlEx)
            {
                String msg = '';
                String sep = '';
                for (Integer i = 0; i < dmlEx.getNumDml(); i++)
                {
                    msg += sep + dmlEx.getDmlMessage(i);
                    sep = ' | ';
                }
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
                this.srecord.put(prefix + 'Status__c', oldStatus);
            }
            catch(Exception ex)
            {

                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));

                this.srecord.put(prefix + 'Status__c', oldStatus);
            }
        }
        return ApexPages.currentPage();
    }

    global Component.Apex.Form getForm()
    {
        Component.Apex.Form form = new Component.Apex.Form();

        form.id = 'form';

        if (!Schema.sObjectType.Status__c.isAccessible()
            || !Schema.sObjectType.Status__c.fields.Id.IsAccessible()
            || !Schema.sObjectType.Status__c.fields.Name.IsAccessible()
            || !Schema.sObjectType.Status_Workflow__c.fields.Old_Status__c.IsAccessible()
            || !Schema.sObjectType.Status_Workflow__c.fields.New_Status__c.IsAccessible()
            || !Schema.getGlobalDescribe().get(typeName).getDescribe().fields.getMap().get('Status__c').getDescribe().isAccessible())
            return form;
        String ns = StringUtility.FXNamespace();

        String statusIdStr = String.valueOf(this.srecord.get(ns + 'Status__c'));
        if(String.isBlank(statusIdStr)) return form;

        Id existingStatusId = Id.valueOf(statusIdStr);

        List<Status_Workflow__c> transitionStatuses = new List<Status_Workflow__c>();
        String workflowForSobject = typeName.removeStartIgnoreCase(ns);

        Map<String, Schema.SObjectField> objFields = Schema.getGlobalDescribe().get(typeName).getDescribe().fields.getMap();
        if(objFields.containsKey('RecordTypeId')) {
          Id EntityRecordTypeId = (Id)this.srecord.get('RecordTypeId');
          RecordType rt = [SELECT Id, Name, DeveloperName FROM RecordType WHERE Id=:EntityRecordTypeId];

          transitionStatuses = [SELECT New_Status__c, Old_Status__c, Confirmation_Text__c, Command_Text__c, New_Status__r.Name FROM Status_Workflow__c WHERE Old_Status__c =:existingStatusId AND Application__c='Console' AND SObject__c=:workflowForSobject AND (SObject_Record_Type__c=null OR SObject_Record_Type__c=:rt.Name OR SObject_Record_Type__c=:rt.DeveloperName) ORDER BY Sequence_Number__c, Command_Text__c];
        }
        else
        {
          //if no transitions are found for the record type of the object then get all transitions for that object type
          transitionStatuses = [SELECT New_Status__c, Old_Status__c, Confirmation_Text__c, Command_Text__c, New_Status__r.Name FROM Status_Workflow__c WHERE Old_Status__c =:existingStatusId AND Application__c='Console' AND SObject__c=:workflowForSobject ORDER BY Sequence_Number__c, Command_Text__c];
        }

        Component.Apex.PageBlock pageBlock = new Component.Apex.PageBlock();
        pageBlock.id = 'pageBlock';
        pageBlock.title='';
        pageBlock.mode = 'maindetail';
        form.ChildComponents.Add(pageBlock);

        Component.Apex.PageBlockSection section = new Component.Apex.PageBlockSection();
        section.id = 'pageBlockSection';
        pageBlock.ChildComponents.Add(section);

        Component.Apex.OutputField statusOutput = new Component.Apex.OutputField();
        statusOutput.expressions.value = '{!' + typeName +  '.' + prefix + 'Status__c}';
        section.ChildComponents.Add(statusOutput);

        if(transitionStatuses.isEmpty()) return form;

        Component.Apex.PageBlockButtons cmdButtons = new Component.Apex.PageBlockButtons();
        cmdButtons.location = 'top';

        Map<Id, string> allStatuses = new Map<Id, string>();
        for(Status_Workflow__c sw : transitionStatuses)
        {
            string value = (sw.Command_Text__c == null || sw.Command_Text__c == '') ? sw.New_Status__r.Name : sw.Command_Text__c;
            allStatuses.put(sw.New_Status__c, value);
        }

        Set<Id> newStatusButtons = new Set<Id>();
        
        for (Status_Workflow__c workflow: transitionStatuses) {
            
            if(newStatusButtons.contains(workflow.New_Status__c)) continue;
            
            Component.Apex.CommandButton command = new Component.Apex.CommandButton();

            if(string.isBlank(workflow.Confirmation_Text__c))
            {
                command.onclick = 'document.getElementById(pagePath + ":hiddenInput").value = "' + workflow.New_Status__c + '";';
            }
            else
            {
                //command.onclick = 'if (!confirm("' +  workflow.Confirmation_Text__c + '")) return false; document.getElementById(pagePath + ":hiddenInput").value = "' + workflow.New_Status__c + '";';
                command.onclick = String.format('if (!confirm(decodeURIComponent("{0}".replace(/\\+/g, " ")))) return false; document.getElementById(pagePath + ":hiddenInput").value = "{1}";',
                    new String[]{EncodingUtil.urlEncode(workflow.Confirmation_Text__c, 'UTF-8'), workflow.New_Status__c});

            }
            command.id = 'status' + workflow.New_Status__c;
            command.value = allStatuses.get(workflow.New_Status__c);
            command.title = 'Transition to ' + allStatuses.get(workflow.New_Status__c);
            command.expressions.action = '{!executeStatusChange}';
            command.rendered = true;
            cmdButtons.ChildComponents.Add(command);
            newStatusButtons.add(workflow.New_Status__c);
        }

        pageBlock.ChildComponents.Add(cmdButtons);
        Component.Apex.InputHidden hidden = new Component.Apex.InputHidden();
        hidden.id = 'hiddenInput';
        hidden.expressions.value = '{!hiddenTextValue}';
        form.ChildComponents.Add(hidden);

        return form;
    }

    global string HiddenTextValue { get; set; }
}
