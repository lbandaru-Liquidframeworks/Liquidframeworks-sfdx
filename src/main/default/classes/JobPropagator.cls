public class JobPropagator
{   
    public static Boolean IsActive()
    {
        return !FXSettingHelper.TurnOffJobPropagator;
    }
    
    Static Boolean JobPropagatorRunning {get;set;}

    public static void SetJobId(List<Ticket_Item__c> objs)
    {
         if(!JobPropagator.IsActive() 
            || objs == null 
            || objs.isEmpty()) return;

        Set<Id> ids = new Set<Id>();
        for(Ticket_Item__c o : objs)
        {
            ids.add(o.Ticket__c);
        }
        Map<Id, Id> jobLookup = new Map<Id, Id>();
        for(Ticket__c o: [SELECT Id, Job__c FROM Ticket__c WHERE IsDeleted=false AND Id IN :ids])
        {
            jobLookup.put(o.Id, o.Job__c);
        }
        for(Ticket_Item__c o : objs)
        {
            if(!jobLookup.containsKey(o.Ticket__c)) continue;
            o.Job__c = jobLookup.get(o.Ticket__c);
        }
    }

    public static void SetJobId(List<Ticket_Log__c> objs)
    {
         if(!JobPropagator.IsActive() 
            || objs == null 
            || objs.isEmpty()) return;
         
        Set<Id> ids = new Set<Id>();
        for(Ticket_Log__c o : objs)
        {
            ids.add(o.Ticket__c);
        }
        Map<Id, Id> jobLookup = new Map<Id, Id>();
        for(Ticket__c o: [SELECT Id, Job__c FROM Ticket__c WHERE IsDeleted=false AND Id IN :ids])
        {
            jobLookup.put(o.Id, o.Job__c);
        }
        for(Ticket_Log__c o : objs)
        {
            if(!jobLookup.containsKey(o.Ticket__c)) continue;
            o.Job__c = jobLookup.get(o.Ticket__c);
        }
    }

    public static void SetJobId(List<Ticket_Checklist_Step__c> objs)
    {
        if(!JobPropagator.IsActive() 
            || objs == null 
            || objs.isEmpty()) return;

        Set<Id> ids = new Set<Id>();
        for(Ticket_Checklist_Step__c o : objs)
        {
            ids.add(o.Ticket__c);
        }
        Map<Id, Id> jobLookup = new Map<Id, Id>();
        for(Ticket__c o: [SELECT Id, Job__c FROM Ticket__c WHERE IsDeleted=false AND Id IN :ids])
        {
            jobLookup.put(o.Id, o.Job__c);
        }
        for(Ticket_Checklist_Step__c o : objs)
        {
            if(!jobLookup.containsKey(o.Ticket__c)) continue;
            o.Job__c = jobLookup.get(o.Ticket__c);
        }
    } 


    public static void SetJobId(List<sObject> items)
    {
        if(!JobPropagator.IsActive() 
            || items == null 
            || items.isEmpty()) return;

        //this will run on after insert and after update trigger, 
        //to prevent recursive infinite loop, check JobPropagatorRunning to only run the code once
        if(JobPropagatorRunning == true) return;
        JobPropagatorRunning = true;

        Set<Id> objIds = new Map<Id, sObject>(items).keySet();

        Schema.DescribeSObjectResult r = items.get(0).getSObjectType().getDescribe();
        if(!r.fields.getMap().containsKey('Job_Share__c')) return;

        String objType = r.getName();
        String jobField = GetPathsToJob(r);
       
        String soql = String.format('SELECT Id, {0} FROM {1} WHERE Id IN :objIds FOR UPDATE',
            new String[]{jobField, objType });

        soql = soql.replace('__c.', '__r.');

        //System.debug(soql);
        List<sObject> objs = Database.query(soql);
        for(sObject o : objs)
        {
            Object v = GetJobId(o, jobField);

            if(v!=null)
            {
                o.put('Job_Share__c', v);
            }
        }
        Database.update(objs, false);
    }

    @testVisible
    static Object GetJobID(sObject obj, String path)
    {
        path = path.replace('__c.', '__r.');
        
        String[] entries = path.split('\\.');
        if(entries.size()==1)
        {
            return (Id)obj.get(path);
        }
        sObject source = obj;
        while(entries.size()>1)
        {
            String fk = entries.remove(0);        

            source = source.getsObject(fk);
            if(source==null) return null;
        }
        return source.get(entries.remove(0));           
    }          

    @testVisible
    static String GetKeySObject(String form)
    {
        if(formKeySObjs == null)
        {
            formKeySObjs = new Map<String,String>();
            for(eForm_Config__c c: [SELECT Id, eForm_SObject__c, Key_SObject__c FROM eForm_Config__c WHERE IsDeleted=false])
            {
                formKeySObjs.put(c.eForm_SObject__c, c.Key_SObject__c);
            }
        }
        return formKeySObjs.containsKey(form)? formKeySObjs.get(form) : null;
    }

    @testVisible
    Static Map<String, String> formKeySObjs {get;set;}

    @testVisible
    static String GetPathsToJob(Schema.DescribeSObjectResult r)
    {
        String ns = StringUtility.FXNamespace();

        String objType = r.getName();

        String root = '';

        String keySObj = GetKeySObject(objType);

        Schema.DescribeSObjectResult dsrWithJobPath = r;

        //while keySObj is blank, this might be a child eForm or one not properly configured
        if(String.isBlank(keySObj))
        {
            dsrWithJobPath = null;
            for(Schema.SObjectField f: r.fields.getMap().values())
            {
                Schema.DescribeFieldResult fd = f.getDescribe();
                if(!fd.isCustom()) continue;
                String fieldName = fd.getName();
                if(fieldName == 'Job_Share__c') continue;
                System.debug(fieldName + ':' + fd.getRelationshipOrder());
                if(fd.getRelationshipOrder()>=0)
                {
                    List<Schema.sObjectType> fks = fd.getReferenceTo();
                    if(fks.isEmpty()) continue; 
                    Schema.DescribeSObjectResult fkDsr = fks.get(0).getDescribe();
                    if(!fkDsr.isCustom()) continue;

                    String fkKeySobj = GetKeySObject(fkDsr.getName());
                    if(!String.isBlank(fkKeySobj))
                    {
                        dsrWithJobPath = fkDsr;
                        root = fieldName;
                        keySObj = fkKeySobj;
                        break;
                    }
                }           
            }
        }
        if(String.isBlank(keySObj) || dsrWithJobPath == null) return null;

        keySObj = keySObj.replace('FX5__', ns);

        String path = '';

        for(Schema.SObjectField f: dsrWithJobPath.fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe();
            if(!fd.isCustom()) continue;

            String fieldName = fd.getName();
            if(fieldName == 'Job_Share__c') continue;

            List<Schema.sObjectType> fks = fd.getReferenceTo();
            if(fks.isEmpty()) continue; 

            Schema.DescribeSObjectResult fkDsr = fks.get(0).getDescribe();
            if(!fkDsr.isCustom()) continue;

            if(fkDsr.getName() == keySObj)
            {
                if(keySObj == ns + 'Job__c')
                {
                    path = fieldName;
                    break;
                }
                if(keySObj == ns + 'Ticket__c')
                {
                    path = fieldName.removeEndIgnorecase('__c') + '__r.' + ns + 'Job__c';
                    break;
                }
            }
        }
        if(String.isBlank(path)) return null;

        if(!String.isBlank(root))
        {
            path = root.removeEndIgnorecase('__c') + '__r.' + path;
        }
        return path;
    }
    
}