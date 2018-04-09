public class WorkOrderSchedulerBatchable extends FXBatchableBase
{       
    Set<Id> equipIds {get; set;}
    Datetime now {get; set;}
    String pmsNamespace {get;set;}   

    Map<Id, sObject> oldToNewLookup {get;set;}    
   
    public WorkOrderSchedulerBatchable()
    {
        this(null);
    }

    public WorkOrderSchedulerBatchable(Set<Id> theEquipIds)
    {   
        equipIds =  theEquipIds;
        now = Datetime.now();

        oldToNewLookup = new Map<Id, sObject>();       

        pmsNamespace = GetPmsNamespace();    
     
        Set<String> equipFields = GetFieldsForCloning(Equipment__c.sObjectType.getDescribe());
        String equipFkFields = pmsNamespace+'Equipment__r.' 
            + String.join(new List<String>(equipFields), ','+pmsNamespace+'Equipment__r.');

        soqlQuery = String.format('SELECT {1}, {2}, '
            + '( SELECT {3} FROM {0}Preventative_Maintenance_Criteria__r '
            +'   WHERE IsDeleted=false AND {0}Effective_Date__c<=:now AND ({0}Expiration_Date__c=null OR {0}Expiration_Date__c>:now) '
            + '  ORDER BY {0}Sequence_Number__c'
            + ') '
            + ' FROM {0}Preventative_Maintenance_Schedule__c '
            + ' WHERE IsDeleted=false AND {0}IsActive__c=true AND {0}HasOpenWorkOrder__c=false',
            new String[]{pmsNamespace, 
                String.join(new List<String>(Preventative_Maintenance_Schedule__c.sObjectType.getDescribe().fields.getMap().keySet()), ','),
                equipFkFields, 
                String.join(new List<String>(Preventative_Maintenance_Criterion__c.sObjectType.getDescribe().fields.getMap().keySet()), ',')
                });       
        if(equipIds!=null && !equipIds.isEmpty())
        {
            soqlQuery += String.format(' AND {0}Equipment__c IN :equipIds', new String[]{pmsNamespace});
        }       
    }   

    public override Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(soqlQuery);
    }

    public override void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<Preventative_Maintenance_Schedule__c> workOrderSchedules = new List<Preventative_Maintenance_Schedule__c>();
        
        for(sObject o: scope)
        {
            Preventative_Maintenance_Schedule__c s = (Preventative_Maintenance_Schedule__c)o;
            if(s.Preventative_Maintenance_Criteria__r.isEmpty()) continue;

            Boolean opOR = s.Grouping_Operator__c =='OR';
            Boolean opAND = s.Grouping_Operator__c =='AND';

            Integer trueCount = 0;

            for(Preventative_Maintenance_Criterion__c c : s.Preventative_Maintenance_Criteria__r)
            {
                Boolean cResult = EvaluateCriterion(c, s.Equipment__r);
                if(cResult)
                {
                    ++trueCount;
                    if(opOR) break;
                }
                else if(opAND) 
                {
                    break;
                }               
            }
            if(opOR && trueCount>0 || opAND && trueCount == s.Preventative_Maintenance_Criteria__r.size())
            {
               workOrderSchedules.add(s);
            }            
        }
        List<Preventative_Maintenance_Criterion__c> criteriaForUpdate = new List<Preventative_Maintenance_Criterion__c>();

        if(workOrderSchedules.isEmpty()) return;

        Map<String, List<sObject>> itemsByType = new Map<String, List<sObject>>();

        CreateWorkOrders(itemsByType, workOrderSchedules);

        for(Preventative_Maintenance_Schedule__c s : workOrderSchedules)
        {           
            for(Preventative_Maintenance_Criterion__c c : s.Preventative_Maintenance_Criteria__r)
            {
                c.Evaluation_Timestamp__c = Datetime.now();
                if(!String.isBlank(c.Target_Field__c))
                {
                    c.Last_Meter_Value__c = String.valueOf(s.Equipment__r.get(c.Target_Field__c));
                }     
                criteriaForUpdate.add(c);           
            }           
        }
        String itemType ='Work_Order__c';
        if(itemsByType.containsKey(itemType))
        {
           Database.insert(itemsByType.get(itemType));            
        }

        itemType ='Work_Order_Item__c';
        if(itemsByType.containsKey(itemType))
        {
           Database.insert(itemsByType.get(itemType));            
        }

        itemType ='Work_Order_Task__c';
        if(itemsByType.containsKey(itemType))
        {
           Database.insert(itemsByType.get(itemType));            
        }

        itemType ='Work_Order_Qualification__c';
        if(itemsByType.containsKey(itemType))
        {
           Database.insert(itemsByType.get(itemType));            
        }

        //Database.insert(workOrders);
        Database.update(criteriaForUpdate);        
        
    }    

    public void CreateWorkOrders(Map<String, List<sObject>> itemsByType, List<Preventative_Maintenance_Schedule__c> pmsEntries)
    {       
        Set<Id> woTemplateIds = new Set<Id>();
        for(Preventative_Maintenance_Schedule__c pms : pmsEntries)
        {
            woTemplateIds.add(pms.Template_Work_Order__c);
        }

        String workOrderFieldName = pmsNamespace + 'Work_Order__c';       

        Set<String> woFields = GetFieldsForCloning(Work_Order__c.sObjectType.getDescribe());
        woFields.remove(pmsNamespace + 'Source_PMS__c');
        woFields.remove(pmsNamespace + 'Status__c');
        woFields.remove(pmsNamespace + 'Tracking_Number__c');
        woFields.remove(pmsNamespace + 'IsTemplate__c');
        woFields.remove(pmsNamespace + 'Equipment__c');
        woFields.remove(pmsNamespace + 'Actual_Finish_Date__c');
        woFields.remove(pmsNamespace + 'Actual_Start_Date__c');
        woFields.remove(pmsNamespace + 'Due_Date__c');
        woFields.remove(pmsNamespace + 'Planned_Finish_Date__c');
        woFields.remove(pmsNamespace + 'Planned_Start_Date__c');
        woFields.remove(pmsNamespace + 'SyncID__c');

        Set<String> woItemFields = GetFieldsForCloning(Work_Order_Item__c.sObjectType.getDescribe());
        Set<String> woTaskFields = GetFieldsForCloning(Work_Order_Task__c.sObjectType.getDescribe());      
        Set<String> woQualificationFields = GetFieldsForCloning(Work_Order_Qualification__c.sObjectType.getDescribe());      
        woItemFields.remove(workOrderFieldName);
        woTaskFields.remove(workOrderFieldName);
        woQualificationFields.remove(pmsNamespace + 'Work_Order_Task__c');

        String soql = String.format('SELECT {1}, '
            + ' (SELECT {2} FROM {0}Work_Order_Items__r), '
            + ' (SELECT {3} FROM {0}Work_Order_Tasks__r)'
            + ' FROM {0}Work_Order__c WHERE Id IN :woTemplateIds',
            new String[]{pmsNamespace,
                 String.join(new List<String>(Work_Order__c.sObjectType.getDescribe().fields.getMap().keySet()), ','),
                 String.join(new List<String>(Work_Order_Item__c.sObjectType.getDescribe().fields.getMap().keySet()), ','),
                 String.join(new List<String>(Work_Order_Task__c.sObjectType.getDescribe().fields.getMap().keySet()), ',')});

        List<sObject> templateWorkOrders = Database.query(soql);
        Map<Id, sObject> templateWorkOrderLookup = new Map<Id, sObject>(templateWorkOrders);

        for(Preventative_Maintenance_Schedule__c pms : pmsEntries)
        {
            CreateWorkOrder(itemsByType, pms, (Work_Order__c)templateWorkOrderLookup.get(pms.Template_Work_Order__c), 
                woFields, woItemFields, woTaskFields);
        }  

        Set<Id> workOrderIds = templateWorkOrderLookup.keySet();
        if(!woQualificationFields.isEmpty())
        {
            String woqSoql = String.format('SELECT {1} FROM {0}Work_Order_Qualification__c WHERE {0}Work_Order_Task__r.{0}Work_Order__c IN :workOrderIds',
                    new String[]{pmsNamespace, String.join(new List<String>(Work_Order_Qualification__c.sObjectType.getDescribe().fields.getMap().keySet()), ',') });            

            List<sObject> taskQualifications = Database.query(woqSoql);

            List<sObject> newTaskQualifications = new List<sObject>();
            for(sObject o : taskQualifications)
            {
                Work_Order_Qualification__c source = (Work_Order_Qualification__c)o;
                Work_Order_Qualification__c q = new Work_Order_Qualification__c();

                q.Work_Order_Task__r = (Work_Order_Task__c)oldToNewLookup.get(source.Work_Order_Task__c);
               
                for(String f : woQualificationFields)
                {
                    q.put(f, source.get(f));
                }
                newTaskQualifications.add(q);
            }
            if(!newTaskQualifications.isEmpty())
            {
                itemsByType.put('Work_Order_Qualification__c', newTaskQualifications);
            } 
        }          
    }


    void CreateWorkOrder(Map<String, List<sObject>> itemsByType, Preventative_Maintenance_Schedule__c pms, 
        Work_Order__c template, Set<String> workOrderFields, Set<String> woItemFields, 
        Set<String> woTaskFields)
    {       
        String woSyncID = StringUtility.newGuid();

        Work_Order__c newWorkOrder = new Work_Order__c();
        for(String f: workOrderFields)
        {
            newWorkOrder.put(f, template.get(f));
        }
        newWorkOrder.Tracking_Number__c = null;
        newWorkOrder.IsTemplate__c = false;
        newWorkOrder.Equipment__c = pms.Equipment__c;
        newWorkOrder.SyncID__c = woSyncID;
        newWorkOrder.Source_PMS__c = pms.Id; 

        String itemType='Work_Order__c';
        if(!itemsByType.containsKey(itemType))
        {
            itemsByType.put(itemType, new List<sObject>());
        }
        itemsByType.get(itemType).add(newWorkOrder);         

        Work_Order__c woReference = new Work_Order__c(SyncID__c = woSyncID);  
        oldToNewLookup.put(template.Id, woReference);

        for(Work_Order_Item__c wi : template.Work_Order_Items__r)
        {          
            Work_Order_Item__c newItem = new Work_Order_Item__c();
            for(String f:woItemFields)
            {
                newItem.put(f, wi.get(f));
            }
            newItem.Work_Order__r = woReference;
            newItem.SyncID__c = StringUtility.newGuid();

            itemType='Work_Order_Item__c';
            if(!itemsByType.containsKey(itemType))
            {
                itemsByType.put(itemType, new List<sObject>());
            }
            itemsByType.get(itemType).add(newItem);

            oldToNewLookup.put(wi.Id, new Work_Order_Item__c(SyncID__c = newItem.SyncID__c));

        }

        for(Work_Order_Task__c wt : template.Work_Order_Tasks__r)
        {
            String taskSyncID = StringUtility.newGuid();

            //Work_Order_Task__c newTask = wt.clone();
            //newTask.Work_Order__c = null;

            Work_Order_Task__c newTask = new Work_Order_Task__c();
            for(String f:woTaskFields)
            {
                newTask.put(f, wt.get(f));
            }

            newTask.Work_Order__r = woReference;
            newTask.SyncID__c = taskSyncID;

            itemType='Work_Order_Task__c';
            if(!itemsByType.containsKey(itemType))
            {
                itemsByType.put(itemType, new List<sObject>());
            }
            itemsByType.get(itemType).add(newTask);


            oldToNewLookup.put(wt.Id, new Work_Order_Task__c(SyncID__c = newTask.SyncID__c));
        }       
    }


    static Boolean EvaluateCriterion(Preventative_Maintenance_Criterion__c c, Equipment__c equip)
    {  
        if(c.Next_Run__c!=null) return c.Next_Run__c <= Datetime.now();

        if(String.isBlank(c.Target_Field__c) || String.isBlank(c.Value__c)) return true;

        Schema.SObjectField equipTargetField =  equip.Id.getSObjectType().getDescribe().fields.getMap().get(c.Target_Field__c);
        
        if(equipTargetField==null)
        {
            System.debug('Equipment does NOT have this customField [' + c.Target_Field__c + ']');           
            return false;
        }
        Schema.DescribeFieldResult fd = equipTargetField.getDescribe(); 

        Schema.DisplayType type = fd.getType();

        Object equipValue = equip.get(c.Target_Field__c);

        Object thresholdValue = null;

        Boolean evalResult = false;
        if(c.Operator__c == 'Every')
        {
            thresholdValue = GetValue(type, c.Value__c, c.Last_Meter_Value__c);
            evalResult = EvalValues(type, '>=', equipValue, thresholdValue);
        }
        else 
        {
            thresholdValue = GetValue(type, c.Value__c, null);
            evalResult = EvalValues(type, c.Operator__c, equipValue, thresholdValue);

        } 
        //System.debug(c.Target_Field__c + ': equipValue=' + equipValue);
        //System.debug('thresholdValue=' + thresholdValue);
        //System.debug('evalResult=' + evalResult);
        return evalResult;
    }

    public static Boolean EvalValues(Schema.DisplayType type, String op, Object value1, Object value2)
    {
        System.debug('EvalValues(' + String.valueOf(type) + ',' + op + ',' + value1 + ',' + value2 + ')');
        if(type ==  Schema.DisplayType.Double)
        {
            Double v1 = (Double)value1;
            Double v2 = (Double)value2;
            if(op == '=' || op == '==') return v1 == v2;                
            if(op == '>') return v1 > v2;       
            if(op == '<') return v1 < v2;
            if(op == '<=') return v1 <= v2;            
            if(op == '>=') return v1 >= v2;          
            if(op == '!=') return v1 != v2;
        }
        if(type ==  Schema.DisplayType.Integer)
        {
            Integer v1 = (Integer)value1;
            Integer v2 = (Integer)value2;
            if(op == '=' || op == '==') return v1 == v2;                
            if(op == '>') return v1 > v2;       
            if(op == '<') return v1 < v2;
            if(op == '<=') return v1 <= v2; 
            if(op == '>=') return v1 >= v2;                                                              
            if(op == '!=') return v1 != v2;
        }
        /*
        if(type ==  Schema.DisplayType.Currency)
        {            
            Currency v1 = (Currency)value1;
            Currency v2 = (Currency)value2;
            if(op == '=' || op == '==') return v1 == v2;                
            if(op == '>') return v1 > v2;       
            if(op == '<') return v1 < v2;
            if(op == '<=') return v1 <= v2;            
            if(op == '>=') return v1 >= v2;          
            if(op == '!=') return v1 != v2;
        }
        
        if(type ==  Schema.DisplayType.Percent)
        {
            Percent v1 = (Percent)value1;
            Percent v2 = (Percent)value2;
            if(op == '=' || op == '==') return v1 == v2;                
            if(op == '>') return v1 > v2;       
            if(op == '<') return v1 < v2;
            if(op == '<=') return v1 <= v2;            
            if(op == '>=') return v1 >= v2;          
            if(op == '!=') return v1 != v2;
        }
        */
        if(type ==  Schema.DisplayType.Time)
        {
            Time v1 = (Time)value1;
            Time v2 = (Time)value2;
            if(op == '=' || op == '==') return v1 == v2;                
            if(op == '>') return v1 > v2;       
            if(op == '<') return v1 < v2;
            if(op == '<=') return v1 <= v2;            
            if(op == '>=') return v1 >= v2;          
            if(op == '!=') return v1 != v2;
        }
        if(type ==  Schema.DisplayType.DateTime)
        {
            DateTime v1 = (DateTime)value1;
            DateTime v2 = (DateTime)value2;
            if(op == '=' || op == '==') return v1 == v2;                
            if(op == '>') return v1 > v2;       
            if(op == '<') return v1 < v2;
            if(op == '<=') return v1 <= v2;            
            if(op == '>=') return v1 >= v2;          
            if(op == '!=') return v1 != v2;
        }
        if(type ==  Schema.DisplayType.Date)
        {
            Date v1 = (Date)value1;
            Date v2 = (Date)value2;
            if(op == '=' || op == '==') return v1 == v2;                
            if(op == '>') return v1 > v2;       
            if(op == '<') return v1 < v2;
            if(op == '<=') return v1 <= v2;            
            if(op == '>=') return v1 >= v2;          
            if(op == '!=') return v1 != v2;
        }    
        
        String v1 = String.valueOf(value1);
        String v2 = String.valueof(value2);
        if(op == '=' || op == '==') return v1 == v2;                
        if(op == '>') return v1 > v2;       
        if(op == '<') return v1 < v2;
        if(op == '<=') return v1 <= v2;            
        if(op == '>=') return v1 >= v2;          
        if(op == '!=') return v1 != v2;
        return false;  

    }
    static Object GetValue(Schema.DisplayType type, String v, String baseValue)
    {
        //http://www.salesforce.com/us/developer/docs/apexcode/Content/apex_enum_Schema_DisplayType.htm

        if(type ==  Schema.DisplayType.Double)
        {
           return String.isBlank(baseValue)? Double.valueOf(v) : Double.valueOf(baseValue) + Double.valueOf(v);            
        }
        if(type ==  Schema.DisplayType.Integer)
        {
            return String.isBlank(baseValue)? Integer.valueOf(v) : Integer.valueOf(baseValue) + Integer.valueOf(v);
        }
        if(type ==  Schema.DisplayType.Currency)
        {            
            //return String.isBlank(baseValue)? Currency.valueOf(v) : Currency.valueOf(baseValue) + Currency.valueOf(v);
        }
        if(type ==  Schema.DisplayType.Percent)
        {
            //return String.isBlank(baseValue)? Percent.valueOf(v) : Percent.valueOf(baseValue) + Percent.valueOf(v);
        }
        if(type ==  Schema.DisplayType.Time)
        {
            //return Time.valueOf(v);
        }
        if(type ==  Schema.DisplayType.DateTime)
        {
            return DateTime.valueOf(v);
        }
        if(type ==  Schema.DisplayType.Date)
        {
            return Date.valueOf(v);
        }       
        return v;          
    }
      
    public static String GetPmsNamespace()
    {
        return Preventative_Maintenance_Criterion__c.sObjectType.getDescribe().Name.replace('Preventative_Maintenance_Criterion__c', '');
    }   

    public static List<String> GetFields(Schema.DescribeSObjectResult r, Boolean customFieldsOnly)
    {
        return GetFields(r, customFieldsOnly, new Set<String>());
    }

    public static List<String> GetFields(Schema.DescribeSObjectResult r, Boolean customFieldsOnly, Set<String> excludeFields)
    {
        List<String> fields = new List<String>();

        for(Schema.SObjectField f: r.fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe(); 
            String fieldName = fd.getName();
            if (excludeFields.contains(fieldName) || fd.isCalculated() || !fd.isAccessible() || (customFieldsOnly && !fieldName.endsWith('__c'))) continue; //fd.isExternalId() || fd.isUnique() 

            fields.add(fieldName);
        }
        return fields;
    }  


    static Set<String> GetFieldsForCloning(Schema.DescribeSObjectResult r)
    {
        Set<String> fields = new Set<String>();
        Map<String, Schema.SObjectField> m = r.fields.getMap();
        Set<String> allFields = m.keySet();

        for(Schema.SObjectField f: m.values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe(); 
            String fieldName = fd.getName();
            if ((fd.isNameField() || fd.isCustom()) 
                && fd.isCreateable()
                && !fd.isCalculated() 
                && fd.isAccessible()
                && !fd.isUnique()
                && !fd.isAutoNumber())
            {
                fields.add(fieldName);
            }
            
        }
        //fields.add('Name');
        if(allFields.contains('recordtypeid'))
        {
            fields.add('RecordTypeId');
        }        
        return fields;
    }  

}