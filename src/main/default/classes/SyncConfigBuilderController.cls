public with sharing class SyncConfigBuilderController
{
    public SyncConfigBuilderController()
    {
        syncConfigObj = new Sync_Configuration__c();
        syncConfigFilter = new Sync_Configuration__c();
        contactObj = new Contact();
        SyncConfigContacts='';
       
        NewSyncConfigs = new List<Sync_Configuration__c>();
        NewSyncConfigs.add(syncConfigObj);
        SearchContacts();
        FilterSyncConfigs();
    }

    public SyncConfigBuilderController(ApexPages.StandardController controller)
    {
        this(); 
    }
   
    public List<Contact> contacts {get; protected set;}

    public String keyword {get;set;}

    public Sync_Configuration__c syncConfigObj {get; set;}
    public Sync_Configuration__c syncConfigFilter {get; set;}

    public Contact contactObj {get; set;}

    public List<Sync_Configuration__c> SyncConfigs {get;set;}
    public List<Sync_Configuration__c> NewSyncConfigs {get;set;}

    public static String GetUniqueId(Sync_Configuration__c sc)
    {    
        Id account = sc.Account__c!=null? String.valueOf(sc.Account__c) : null;
        Id office = sc.Office__c!=null? String.valueOf(sc.Office__c) : null;
        Id contactId = String.valueOf(sc.Contact__c);
        String str = 'A' + account +  'JT' + sc.Job_Type__c + 'S' + sc.Segment__c + 'O' + office + 'C' + contactId + 'JC' + (sc.Sync_JobCrewOnly__c ? 'T' : 'F');
        return str.replace('null', '');
    }

    public void FilterSyncConfigs()
    {
        Set<String> contacts = GetSelectedContactIds();
        String ns = UtilityGetNamespace.CurrentNamespace();
        String soql = 'SELECT Id, Name, ns__Account__r.Name, ns__Account__c,ns__Contact__r.Name, ns__Contact__c,ns__Job_Type__c,ns__Office__c, ns__Office__r.Name,ns__Segment__c,ns__Sync_JobCrewOnly__c,ns__User_Login_Name__c FROM ns__Sync_Configuration__c [whereClause] ORDER BY ns__Contact__r.Name,ns__Job_Type__c, ns__Account__r.Name, ns__Office__r.Name, ns__Segment__c LIMIT 100000';

        String whereClause = 'WHERE ns__Contact__r.ns__User__c!=null AND ns__Contact__r.ns__User__r.IsActive=true';
        String sep = ' AND ';
        if(contacts != null && !contacts.isEmpty())
        {
            whereClause += sep + 'ns__Contact__c IN :contacts';
        }
        if(!String.isBlank(syncConfigFilter.Account__c))
        {
            whereClause += sep + 'ns__Account__c =\'' + String.escapeSingleQuotes(syncConfigFilter.Account__c) + '\'';
        }
        if(!String.isBlank(syncConfigFilter.Office__c))
        {
            whereClause += sep + 'ns__Office__c =\'' + String.escapeSingleQuotes(syncConfigFilter.Office__c) + '\'';
       }

        if(!String.isBlank(syncConfigFilter.Segment__c))
        {
            whereClause += sep + 'ns__Segment__c =\'' + String.escapeSingleQuotes(syncConfigFilter.Segment__c) + '\'';
        }
        if(!String.isBlank(syncConfigFilter.Job_Type__c))
        {
            whereClause += sep + 'ns__Job_Type__c =\'' + String.escapeSingleQuotes(syncConfigFilter.Job_Type__c) + '\'';
        }
        
        soql = soql.replace('[whereClause]', whereClause);
        soql = soql.replace('ns__', ns);

        //System.debug('soql = ' + soql);

        SyncConfigs = new List<Sync_Configuration__c>();
        for(sObject s : Database.query(soql))
        {
            SyncConfigs.add((Sync_Configuration__c)s);
        }
    }

    public void DeleteSyncConfigs()
    {
        if(String.isBlank(SelectedSyncConfigIds)) return;
         Set<String> items = new Set<String>();
        for(String item : SelectedSyncConfigIds.split(','))
        {
            if(String.isBlank(item)) continue;
            items.add(item);
        }
        Database.delete([SELECT Id FROM Sync_Configuration__c WHERE Id IN :items]);
        FilterSyncConfigs();
    }


    Set<String> GetSelectedContactIds()
    {        
        Set<String> items = new Set<String>();
        if(!String.isBlank(SyncConfigContacts)) 
        {       
            for(String item : SyncConfigContacts.split(','))
            {
                items.add(item.split(':').get(0));
            }
        }
        return items;

    }

    public void ResetSyncConfigFilter()
    {
        syncConfigFilter = new Sync_Configuration__c();
        FilterSyncConfigs();
    }


    public void SearchContacts()
    {
        String ns = UtilityGetNamespace.CurrentNamespace();
        String soql = 'SELECT Id, Name, Email, ns__Office__c, ns__Office__r.Name, ns__User__r.Username FROM Contact [whereClause] ORDER BY Name LIMIT 20000';

        String whereClause = ' WHERE  ns__User__c!=null AND ns__User__r.IsActive=true AND ns__Available_for_Field_Work__c=true ';

        if(contactObj.Office__c!=null)
        {
            whereClause += ' AND ns__Office__c = \'' + String.escapeSingleQuotes(contactObj.Office__c) +'\'';                     
        }
      

        if(!String.isBlank(keyword))
        {
            String str = '\'%' + String.escapeSingleQuotes(keyword) + '%\'';

            String keywordFilter = ' AND (Name LIKE :keywordFilter OR Email LIKE :keywordFilter OR MobilePhone LIKE :keywordFilter OR Phone LIKE :keywordFilter OR ns__User__r.Username LIKE :keywordFilter)';

            whereClause += keywordFilter.replace(':keywordFilter', str);              
          
        }
        soql = soql.replace('[whereClause]', whereClause).replace('ns__', ns);

        contacts = new List<Contact>();
        for(sObject c : Database.query(soql))
        {
            contacts.add((Contact)c);
        }        
    }

    public void resetSearcher()
    {
        contactObj.Office__c = null;
        keyword = '';
        SearchContacts();
    }

    public void save()
    {
        SaveSyncConfigs();
        FilterSyncConfigs();
        
    }   

    public void SaveGridEdit()
    {
        if(!SyncConfigs.isEmpty()) 
        {
            List<Sync_Configuration__c> items = new List<Sync_Configuration__c>();

            for(Sync_Configuration__c source : SyncConfigs)
            {
                Sync_Configuration__c sc = new Sync_Configuration__c();       
                sc.Contact__c = source.Contact__c;
                sc.Account__c = source.Account__c;
                sc.Office__c = source.Office__c;
                sc.Segment__c = source.Segment__c;
                sc.Job_Type__c = source.Job_Type__c;
                sc.Sync_JobCrewOnly__c = source.Sync_JobCrewOnly__c;
                sc.UniqueId__c = GetUniqueId(sc);
                items.add(sc);

            }
            Save(items);
        }
        FilterSyncConfigs();
    }

    public void CancelGridEdit()
    {
        FilterSyncConfigs();
    }

    void SaveSyncConfigs()
    {
        if(String.isBlank(SyncConfigContacts)) return;

        List<Sync_Configuration__c> newItems = new List<Sync_Configuration__c>();

        for(String c : GetSelectedContactIds())
        {          
            Sync_Configuration__c newItem = new Sync_Configuration__c();
            newItem.Contact__c = c;
            newItem.Account__c = syncConfigObj.Account__c;
            newItem.Office__c = syncConfigObj.Office__c;
            newItem.Segment__c = syncConfigObj.Segment__c;
            newItem.Job_Type__c = syncConfigObj.Job_Type__c;
            newItem.Sync_JobCrewOnly__c = syncConfigObj.Sync_JobCrewOnly__c;

            String uniqueId = GetUniqueId(newItem);
            newItem.UniqueExternalId__c = uniqueId;
            newItem.UniqueId__c = uniqueId;

            newItems.add(newItem);
        }
        Save(newItems);
    }

    void Save(List<Sync_Configuration__c> items)
    {
        if(items.isEmpty()) return;

        String msg = '';

        for(Database.UpsertResult result : Database.upsert(items, Sync_Configuration__c.UniqueExternalId__c, false))
        {
            if(result.isSuccess()) continue;            
            for(Database.Error r : result.getErrors())
            {                
                msg += r.getMessage() + '<br />';
            }                            
        }
        
        if(!String.isBlank(msg))
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
            
        }        
    }  
   
    public String SyncConfigContacts {get;set;} //id:name pair
    public String SelectedSyncConfigIds {get;set;} 
}