public with sharing class JobQualificationHandler
{
    public class ResultItem
    {
        public ResultItem() {}

        public ResultItem(Qualification_Requirement__c qr)
        {
            this.Id = qr.Qualification__r.Id;
            this.Required = qr.Required__c;
            this.Name = qr.Qualification__r.Name;
            this.Abbreviation = qr.Qualification__r.Abbreviation__c;
            this.Category = String.isBlank(qr.Category__c)? 'Contact' : qr.Category__c; 
        }       

        public Id Id {get;set;}
        public Boolean Required {get; set;}
        public String Name {get;set;}
        public String Abbreviation {get;set;}
        public String Category {get; set;}

    }

    public static Set<Id> GetQualifiedItems(Set<Id> qualificationIds, Date startDate, Date endDate)
    {    
        Integer contactCategoryCount = 0;
        Integer equipCategoryCount = 0;

        Map<Id, Set<Id>> qualifiedContacts = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> qualifiedEquip = new Map<Id, Set<Id>>();     

        for(Qualification__c q : [select Id, Category__c, (select Id, Contact__c FROM Contact_Qualifications__r WHERE IsDeleted=false AND (Effective_Date__c=null OR Effective_Date__c<=:startDate) AND (Expiration_Date__c=null OR Expiration_Date__c>:endDate)), (Select Id, Equipment__c FROM Equipment_Qualifications__r WHERE IsDeleted=false AND (Effective_Date__c=null OR Effective_Date__c<=:startDate) AND (Expiration_Date__c=null OR Expiration_Date__c>:endDate)) FROM Qualification__c WHERE IsDeleted=false AND Id IN :qualificationIds])
        {
            if(q.Category__c == 'Contact')
            {
                contactCategoryCount++;
                for(Contact_Qualification__c cq : q.Contact_Qualifications__r)                
                {
                    if(!qualifiedContacts.containsKey(cq.Contact__c))
                    {
                        qualifiedContacts.put(cq.Contact__c, new Set<Id>());
                    }
                    qualifiedContacts.get(cq.Contact__c).add(q.Id);
                }
            }
            else if(q.Category__c == 'Equipment')
            {
                equipCategoryCount++;
                for(Equipment_Qualification__c eq : q.Equipment_Qualifications__r)                
                {
                    if(!qualifiedEquip.containsKey(eq.Equipment__c))
                    {
                        qualifiedEquip.put(eq.Equipment__c, new Set<Id>());
                    }
                    qualifiedEquip.get(eq.Equipment__c).add(q.Id);
                }
            }
        }
        Set<Id> results = new Set<Id>();
        if(contactCategoryCount>0)
        {
            for(Id objId : qualifiedContacts.keySet())
            {
                if(qualifiedContacts.get(objId).size() == contactCategoryCount)
                {
                    results.add(objId);
                }
            }
        }
        if(equipCategoryCount>0)
        {
            for(Id objId : qualifiedEquip.keySet())
            {
                if(qualifiedEquip.get(objId).size() == equipCategoryCount)
                {
                    results.add(objId);
                }
            }
        }
        return results;
    }


    static Set<Id> GetQualifiedItems(Id jobId, String category)
    {
        Job__c j = [SELECT Projected_Start_Date__c, Projected_End_Date__c FROM Job__c WHERE Id=:jobId];

        String ns = StringUtility.FXNamespace();

        String dateFilter = '';        
        Datetime dt = j.Projected_Start_Date__c;
        Date jobStartDate = null;
       
        if(dt!=null)
        {
            dateFilter = String.format(' AND (({0}Effective_Date__c=null OR {0}Effective_Date__c<=:jobStartDate) AND ({0}Expiration_Date__c=NULL OR {0}Expiration_Date__c>:jobStartDate))', new String[]{ns});
            jobStartDate =  Date.newinstance(dt.year(), dt.month(), dt.day());
        }
        
        dt = j.Projected_End_Date__c;
        Date jobEndDate = null;
        if(dt!=null)
        {
            dateFilter += String.format(' AND (({0}Effective_Date__c=null OR {0}Effective_Date__c<=:jobEndDate) AND ({0}Expiration_Date__c=NULL OR {0}Expiration_Date__c>=:jobEndDate))', new String[]{ns});           
            jobEndDate = Date.newinstance(dt.year(), dt.month(), dt.day());
        }             
        Set<Id> qualificationIds = GetQualificationIds(GetJobQualifications(jobId, category));

        

        String soql = String.format('SELECT Id, {0}Qualification__c, {0}Effective_Date__c,  {0}Expiration_Date__c, {0}{1}__c FROM {0}{1}_Qualification__c WHERE IsDeleted=false AND {0}Qualification__c IN :qualificationIds {2}',
            new String[]{ns, category, dateFilter});

        System.debug('soql:' + soql);

        Map<Id, Set<Id>> itemCount = new Map<Id, Set<Id>>();

        String effectiveDateField = ns + 'Effective_Date__c';
        String expirationDateField = ns + 'Expiration_Date__c';
        String subjectField = ns + category + '__c';
        String qualificationField = ns + 'Qualification__c';
       
        for(sObject o : Database.query(soql))
        {         

            Id subjectId = (Id)o.get(subjectField);
            Id qualificationId = (Id)o.get(qualificationField);

            if(!itemCount.containsKey(subjectId))
            {
                itemCount.put(subjectId, new Set<Id>());
            }
            itemCount.get(subjectId).add(qualificationId);            
        }

        Set<Id> results = new Set<Id>();
        Integer jobQualificationCount = qualificationIds.size();
        for(Id o : itemCount.keySet())
        {
            if(itemCount.get(o).size()!=jobQualificationCount) continue;
            results.add(o);
        }

        return results;
    }

    public static Set<Id> GetQualifiedContacts(Id jobId)
    {
        return GetQualifiedItems(jobId, 'Contact');
    }

    public static Set<Id> GetQualifiedEquipment(Id jobId)
    {
        return GetQualifiedItems(jobId, 'Equipment'); 
    }

    static Set<Id> GetQualificationIds(Set<ResultItem> items)
    {
        Set<Id> ids = new Set<Id>();
        for(ResultItem r: items)
        {
            ids.add(r.Id);
        }
        return ids;
    }

    public static Set<ResultItem> GetJobQualifications(Id jobId, String category)
    {
        Set<Id> ids = new Set<Id>();
        ids.add(jobId);
        Map<Id, Set<ResultItem>> r = GetJobQualifications(ids, category);
        return (r.isEmpty() || !r.containsKey(jobId))? null : r.get(jobId);
    }

    public static Set<ResultItem> GetJobQualifications(Id jobId)
    {
        return GetJobQualifications(jobId, null);
    }

    public static Map<Id, Set<ResultItem>> GetJobQualifications(Set<Id> jobIds)
    {
        return GetJobQualifications(jobIds, null);
    }

    
    public static Map<Id, Set<ResultItem>> GetJobQualifications(Set<Id> jobIds, String category)
    {
        return GetJobQualifications(jobIds, category, false);
    }
    public static Map<Id, Set<ResultItem>> GetJobQualifications(Set<Id> jobIds, String category, Boolean requiredOnly)
    {
    
        Set<Id> ids = jobIds;
        Set<String> jobFields = new Set<String>();
        for(SObjectField f : Job__c.sObjectType.getDescribe().fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe(); 
            if(!fd.isCustom()) continue;
            jobFields.add(fd.getName());
        }
        String ns = StringUtility.FXNamespace();

        jobFields.remove(ns + 'Category__c');

        Set<String> qualificationRequirementFields = new Set<String>();
        for(SObjectField f : Qualification_Requirement__c.sObjectType.getDescribe().fields.getMap().values())
        {
            Schema.DescribeFieldResult fd = f.getDescribe(); 
            if(!fd.isCustom()) continue;
            qualificationRequirementFields.add(fd.getName());
        }

        Map<String, String> matchingFields = new Map<String, String>();
        
        for(String f : qualificationRequirementFields)
        {          
            if(jobFields.contains(f))
            {
                matchingFields.put(f, f);
            }
            else if(jobFields.contains(f.replace(ns, '')))
            {
                matchingFields.put(f, f.replace(ns, ''));
            }
            else if(jobFields.contains(ns + f))
            {
                matchingFields.put(f, ns + f);
            }
        }
        matchingFields.put(ns + 'Account__c', ns + 'CustomerAccount__c');


        String jobSoql = String.format('SELECT Id, {1} FROM {0}Job__c WHERE IsDeleted=false AND Id IN :ids',
         new String[]{ns, String.join(new List<String>(matchingFields.values()), ',')});

        String categoryFilter = String.isBlank(category)? '' : ' AND (' + ns + 'Category__c=:category)';

        String requiredOnlyFilter = requiredOnly? (' AND ' + ns + 'Required__c=true') : '';
        String qrSoql = String.format('SELECT Id, {0}Required__c, {0}Job__c, {0}Category__c, {0}Qualification__r.Id, {0}Qualification__r.Name, {0}Qualification__r.{0}Abbreviation__c, {1} FROM {0}Qualification_Requirement__c WHERE IsDeleted=false AND ({0}Job__c IN :ids OR {0}Job__c=null) {2} {3}',
            new String[]{ns, 
                String.join(new List<String>(matchingFields.keySet()), ','), 
                categoryFilter,
                requiredOnlyFilter});

        List<Job__c> jobs = (List<Job__c>)Database.query(jobSoql);

        Set<String> keys = matchingFields.keySet();   

        Map<Id, Set<ResultItem>> results = new Map<Id, Set<ResultItem>>();
        
        Map<String, ResultItem> jobQuialificaitonLookup = new Map<String, ResultItem>();

        Map<String, Set<Id>> jobValues = new Map<String, Set<Id>>();

        for(Job__c j : jobs)
        {
            for(String k : matchingFields.keySet())
            {
                String jobField = matchingFields.get(k);
                String v = String.valueOf(j.get(jobField));
                if(String.isBlank(v)) continue;

                String mKey = k+v;               
                
                if(!jobValues.containsKey(mKey))
                {
                    jobValues.put(mKey, new Set<Id>());                
                }
                jobValues.get(mKey).add(j.Id);
            }
        }        

        for(Qualification_Requirement__c qr : Database.query(qrSoql))
        {
            Boolean isMatch = true;

            Set<Id> matchingItems = new Set<Id>();
            if(String.isBlank(qr.Job__c))
            {
                matchingItems.addAll(ids);
            }
            else
            {
                matchingItems.add(qr.Job__c);
            }

            for(String f : keys)
            {
                String v = String.valueOf(qr.get(f));
                if(String.isBlank(v)) continue;

                String key = f + v;
                if(!jobValues.containsKey(key))
                {
                    matchingItems.clear();
                    break;
                }
                matchingItems.retainAll(jobValues.get(key));
            }
            if(!matchingItems.isEmpty())
            {
                for(Id jobId : matchingItems)
                {
                    if(!results.containsKey(jobId))
                    {
                        results.put(jobId, new Set<ResultItem>());
                    }
                    String jobQualificationKey = String.valueOf(jobId) + qr.Qualification__r.Id;

                    if(!jobQuialificaitonLookup.containsKey(jobQualificationKey))
                    {
                        ResultItem r = new ResultItem(qr);
                        results.get(jobId).add(r);
                        jobQuialificaitonLookup.put(jobQualificationKey, r);
                    }
                    else
                    {
                        ResultItem r = jobQuialificaitonLookup.get(jobQualificationKey);
                        if(!r.Required && qr.Required__c)
                        {
                            r.Required = true;
                        }
                    }             
                    
                }
            }
        }
        
        return results;
    }

    public static void ValidateQualifications(List<Equipment_Planning__c> cps)
    {
        if(!FX_Settings__c.getInstance(UserInfo.getUserId()).SkipEquipPlanningTriggerOnQualification__c)
        {
            ValidateJobQualifications(cps, StringUtility.FXNamespace() + 'Equipment2__c');
        }
        
    }

    public static void ValidateQualifications(List<Crew_Planning__c> cps)
    {
        if(!FX_Settings__c.getInstance(UserInfo.getUserId()).SkipCrewPlanningTriggerOnQualification__c)
        {
            ValidateJobQualifications(cps, StringUtility.FXNamespace() + 'Crew_Member__c');
        }
    }

    static void ValidateJobQualifications(List<sObject> planningItems, String subjectFieldName)
    {            
        Set<Id> jobIds = new Set<Id>();
        Set<Id> subjectIds = new Set<Id>();
        List<sObject> itemsOfInterest = new List<sObject>();
        String ns = StringUtility.FXNamespace();

        String jobField = ns + 'Job__c';

        for(sObject o : planningItems)
        {
            if(o.get(subjectFieldName) == null || o.get(jobField)==null) continue;
            jobIds.add((Id)o.get(jobField));
            subjectIds.add((Id)o.get(subjectFieldName));
            itemsOfInterest.add(o);
        }

        String category = (subjectFieldName == ns  + 'Equipment2__c') ? 'Equipment' : 'Contact';

        Map<Id, Set<ResultItem>> jobQualifications = GetJobQualifications(jobIds, category, true);  
        if(jobQualifications.isEmpty()) return;

        Map<Id, Set<Id>> jobQualificationIds = new Map<Id, Set<Id>>();

        Set<Id> qualificationIds = new Set<Id>();

        for(Id jobId : jobQualifications.keySet())
        {
            Set<Id> qIds = GetQualificationIds(jobQualifications.get(jobId));
            qualificationIds.addAll(qIds);
            jobQualificationIds.put(jobId, qIds);
        }

        Map<Id, Job__c> jobsLookup = new Map<Id, Job__c>([SELECT Id, Projected_Start_Date__c, Projected_End_Date__c FROM Job__c WHERE IsDeleted=false AND Id IN :jobIds]);


        Map<Id, Set<Id>> subjectQualificationLookup = new  Map<Id, Set<Id>>();
        
        List<Qualification__c> cqs = [SELECT Id, Name, Abbreviation__c, (SELECT Id, Contact__c, Qualification__c, Effective_Date__c, Expiration_Date__c FROM Contact_Qualifications__r WHERE IsDeleted=false AND Contact__c in :subjectIds), (SELECT Id, Equipment__c, Qualification__c, Effective_Date__c, Expiration_Date__c FROM Equipment_Qualifications__r WHERE IsDeleted=false AND Equipment__c in :subjectIds) FROM Qualification__c WHERE IsDeleted=false AND Id IN :qualificationIds];

        Map<Id, Qualification__c> qMap = new Map<Id, Qualification__c>(cqs);
        Map<Id, Set<Id>> subjectQualifications = new Map<Id, Set<Id>>();
        Map<String, sObject> subQualificationLookup = new Map<String, sObject>();

        String sobjTypeField = ns + category + '__c';

        for(Qualification__c q : cqs)
        {
            String qIdStr = String.valueOf(q.Id);
            List<sObject> subjectQualifiedItems = null;
            if(category =='Equipment')
            {
                subjectQualifiedItems = q.Equipment_Qualifications__r;
            }
            else
            {
                subjectQualifiedItems = q.Contact_Qualifications__r;
            }

            for(sObject o : subjectQualifiedItems)
            {
                Id subjectId = (Id)o.get(sobjTypeField);
                if(!subjectQualifications.containsKey(subjectId))                
                {
                    subjectQualifications.put(subjectId, new Set<Id>());
                }
                subjectQualifications.get(subjectId).add(q.Id);

                subQualificationLookup.put(String.valueOf(subjectId) + qIdStr, o);
            }
        }

        for(sObject o : itemsOfInterest)
        {
            Id jobId = (Id)o.get(ns + 'Job__c');            
            Id subjectId = (Id)o.get(subjectFieldName);
            String subjectIdStr = String.valueOf(subjectId);

            if(!jobQualificationIds.containsKey(jobId))
            {
                continue;
            }

            Set<Id> requiredQualifications = jobQualificationIds.get(jobId);
            Set<Id> subjectQualifiedItems = subjectQualifications.containsKey(subjectId)? subjectQualifications.get(subjectId) : new Set<Id>();
            String errorMsg = '';
            if(!subjectQualifiedItems.containsAll(requiredQualifications))
            {
                Set<Id> required = new Set<Id>();
                required.addAll(requiredQualifications);
                required.removeAll(subjectQualifiedItems);
                List<String> lackedItems = new List<String>();
                for(Id qId : required)
                {
                    Qualification__c q = qMap.get(qId);
                    lackedItems.add(q.Name + ' (' + q.Abbreviation__c + ')');                    
                }
                errorMsg = 'Lacking Qualification: ' + String.join(lackedItems, ', ');
            }
            else
            {
                Job__c j = jobsLookup.get(jobId);
                
                List<String> invalidItems = new List<String>();
                for(Id qId : requiredQualifications)
                {
                    String key = subjectIdStr + String.valueOf(qId);
                    sObject sObj = subQualificationLookup.get(key);
                    Boolean isValid = ValidateDates(j, sObj);
                    if(!isValid)
                    {
                        Qualification__c q = qMap.get(qId);
                        invalidItems.add(q.Name + ' (' + q.Abbreviation__c + ')'); 
                    }
                }
                if(!invalidItems.isEmpty())
                {
                    errorMsg = 'Qualification expired or not yet effective : ' + String.join(invalidItems, ', ');
                }

            }
            if(!String.isBlank(errorMsg))
            {
                o.addError(errorMsg);
            }
        }

    }

    static Boolean ValidateDates(Job__c j, sObject subQualification)
    {
        Date today = Date.today();

        Datetime dt = j.Projected_Start_Date__c;
        Boolean hasJobStartDate = (dt != null);

        Date jobStart = !hasJobStartDate? null : Date.newinstance(dt.year(), dt.month(), dt.day());
        dt = j.Projected_End_Date__c;

        Boolean hasJobEndDate = (dt != null);
        Date jobEnd = !hasJobEndDate? null : Date.newinstance(dt.year(), dt.month(), dt.day());

        String ns = StringUtility.FXNamespace();
        Date effectiveDate = (Date)subQualification.get(ns + 'Effective_Date__c');
        Date expirationDate = (Date)subQualification.get(ns + 'Expiration_Date__c');

        Boolean isValid = true;

        if(effectiveDate!=null && effectiveDate>today
            || expirationDate!=null && expirationDate<today) 
        {
            isValid = false;
        }
        else if(hasJobStartDate)
        {
            if(expirationDate!=null && expirationDate<jobStart
             || effectiveDate!=null && effectiveDate >= jobStart)
                isValid = false;
        }
        else if(hasJobEndDate)
        {
            if(effectiveDate!=null && effectiveDate>jobEnd
                || expirationDate!=null && expirationDate < jobEnd)
                isValid = false;
        }
        return isValid;   
    }

}