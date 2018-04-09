global with sharing class AttachmentExtController
{
    ApexPages.StandardController stdController {get; set;}
    public sObject ParentObj {get; private set;}
    public List<AttachmentInfo> AttachmentInfoItems {get; private set;}
    public String ParentObjType {get; private set;}
    public String ParentObjTypeLabel {get; private set;}
    public String ParentEntityName {get;private set;}
    public List<Schema.FieldSetMember> ExtFields {get;private set;}
    public String SiteUrl {get;private set;}
    String ExtSoql {get; set;}
    public String ParentObjId15 {get;private set;}
    public String ItemsCountStr {get; private set;}
    public Attachment_Ext__c NewAttachmentExt {get;set;}
    public String PackageNamespace {get; private set;}
    public Boolean IsFeedEnabled {get; private set; }
    public FeedItem NewFeedItem {get;set;}
    public Boolean IsChatterFeedSaveAndNew {get;set;}
    public Boolean CloseChatterFeedPopup {get; set;}
    public Integer ChatterAttachmentPopupHeight  {get;set;}   

    global AttachmentExtController() 
    {
        Initialize(ApexPages.currentPage().getParameters().get('id'));
    }
    global AttachmentExtController(String idStr) 
    {
        Initialize(idStr);
    }
    void Initialize(String idStr) 
    {    
        ParentObjId15 = idStr.subString(0, 15);
        Id objId = Id.valueOf(idStr);
        Schema.DescribeSObjectResult r = objId.getSObjectType().getDescribe();

        this.IsFeedEnabled = Schema.SObjectType.User.isFeedEnabled()  && r.isFeedEnabled();

        String soql = MetadataHelper.GetSelectQuery(r) + ' WHERE Id=:objId';

        ParentObj = Database.query(soql);


        ParentEntityName = String.valueOf(ParentObj.get('Name'));

        ParentObjType = r.getName();
        ParentObjTypeLabel = r.getLabel();
        String ns = UtilityGetNamespace.CurrentNamespace();
        PackageNamespace = ns;

        ExtFields = new List<Schema.FieldSetMember>();
        Set<Schema.FieldSetMember> uniqueItems = new Set<Schema.FieldSetMember>();
        String fieldSetName = ParentObjType.replace('__c', '') + 'Fields';

        Schema.DescribeSObjectResult attDesc = Attachment_Ext__c.sObjectType.getDescribe();

        Map<String, Schema.FieldSet> fsMap = attDesc.fieldSets.getMap();
        if(fsMap.containsKey(fieldSetName))
        {
            Schema.FieldSet fieldSet = fsMap.get(fieldSetName );
            for(Schema.FieldSetMember fieldSetMemberObj:fieldSet.getFields())
            {
                if(uniqueItems.contains(fieldSetMemberObj)) continue;
                ExtFields.add(fieldSetMemberObj);
                uniqueItems.add(fieldSetMemberObj);
            }
        }

        if(!String.isBlank(ns))
        {
            fieldSetName = ParentObjType.replace('__c', '').replace(ns, '') + 'Fields';
            if(fsMap.containsKey(fieldSetName))
            {
                Schema.FieldSet fieldSet = fsMap.get(fieldSetName );
                for(Schema.FieldSetMember fieldSetMemberObj:fieldSet.getFields())
                {
                    if(uniqueItems.contains(fieldSetMemberObj)) continue;
                    ExtFields.add(fieldSetMemberObj);
                    uniqueItems.add(fieldSetMemberObj);
                }
            }
        }

        ExtSoql = MetadataHelper.GetSelectQuery(attDesc, true);
        ExtSoql += ' WHERE ' + ns + 'ParentID__c =:parentID'; 
        SiteUrl = URL.getSalesforceBaseUrl().toExternalForm();
        //System.debug('SiteUrl=' + SiteUrl);

        if(!ApexPages.currentPage().getParameters().containsKey('chatterfeed'))
        {
            RefreshDocList();     
        }
        NewFeedItem = new FeedItem(ParentId=objId);  
        NewAttachmentExt = new Attachment_Ext__c(ParentID__c = objId);

        ChatterAttachmentPopupHeight = 250 + ExtFields.size() * 28;
    }

    

    public PageReference SaveChatterFeed()
    {     
        return SaveChatterFeedInternal(false);
    }
    public PageReference SaveAndNewChatterFeed()
    {     
        return SaveChatterFeedInternal(true);

    }
    PageReference SaveChatterFeedInternal(Boolean isSaveAndNew)
    {    
       
        try
        {
            if(NewFeedItem.ContentData==null || String.isBlank(NewFeedItem.ContentFileName)) 
            {
                if(NewFeedItem.ContentData==null)
                {
                    System.debug('NewFeedItem.ContentData=null');
                }
                if(String.isBlank(NewFeedItem.ContentFileName))
                {
                    System.debug('NewFeedItem.ContentFileName is blank');
                }
                return null;
            }
            String fileName = NewFeedItem.ContentFileName;
            Integer index = fileName.lastIndexOfIgnoreCase('.');
            String docTitle = (index>0)? fileName.substring(0, index) : fileName;          
           
            NewFeedItem.Type = 'ContentPost';
            NewFeedItem.Title = docTitle;
            insert NewFeedItem;
            
            NewAttachmentExt.AttachmentID__c = NewFeedItem.Id;
            insert NewAttachmentExt;
        }
        catch(DMLException e)
        {
            System.debug('Exception =' + e);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error uploading file'));

        }
        catch(Exception ex)
        {
            System.debug('Exception =' + ex);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error uploading file'));
        }
        finally
        {
            //NewFeedItem.ContentData = null;
            NewFeedItem = new FeedItem(ParentId=ParentObj.Id);  
            NewAttachmentExt = new Attachment_Ext__c(ParentId__c=ParentObj.Id);
        }  
        if(isSaveAndNew) return null;

        String ns = UtilityGetNamespace.CurrentNamespace(); 
        String pageUrl = '/apex/' + ns + 'ChatterFeedPopupRedirect'; 
        PageReference pageRef = new PageReference(pageUrl);
        pageRef.getParameters().put('Id', ParentObj.Id);

        pageRef.setRedirect(true);
        return pageRef;
    }

    global void RefreshDocList()
    {
        String parentID = String.valueOf(ParentObj.Id);
        List<sObject> attachmentItems = [SELECT Id, ParentId, Name, LastModifiedDate, CreatedById, CreatedBy.Name FROM Attachment WHERE ParentId=:ParentObj.Id AND IsDeleted=false];
        List<sObject> notes = [SELECT Id, Title, ParentId, LastModifiedDate, CreatedById, CreatedBy.Name FROM Note WHERE ParentId=:parentID AND IsDeleted=false];
       
        List<FeedItem> feedItems = FeedItemHandler.getFeedItemsByParent(parentId, 'ContentPost');
        Set<Id> contentVersionIds = new Set<Id>();
        for(FeedItem f: feedItems)
        {
            contentVersionIds.add(f.RelatedRecordId);            
        }

        Map<Id, ContentVersion> conventVersions = new Map<Id, ContentVersion>([SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionIds AND IsDeleted=false]);

        List<sObject> attItems = new List<sObject>();
        attItems.addAll(attachmentItems);
        attItems.addAll(notes);

        Set<Id> attExtIds = new Map<Id, sObject>(attItems).keySet();

        Id userId = UserInfo.getUserId();

        List<UserRecordAccess> recordAccess = [SELECT HasDeleteAccess,HasEditAccess,HasReadAccess,MaxAccessLevel,RecordId FROM UserRecordAccess
WHERE UserId=:userId AND RecordId IN :attExtIds];
        
        Map<Id, UserRecordAccess> accessLookup = new Map<Id, UserRecordAccess>();
        for(UserRecordAccess a : recordAccess)
        {
            if(a.HasReadAccess || a.HasEditAccess || a.HasDeleteAccess)
            {
                accessLookup.put(a.RecordId, a);
            }
        }     

        List<Attachment_Ext__c> attachExts = (List<Attachment_Ext__c>)Database.query(ExtSoql);
        Map<String, Attachment_Ext__c> attExtLookup = new Map<String, Attachment_Ext__c>();
        for(Attachment_Ext__c ext : attachExts)
        {
            attExtLookup.put(ext.AttachmentID__c, ext);
        }

        List<AttachmentInfo> docItems = new List<AttachmentInfo>();       
        for(sObject s : attItems)
        {
            //if(!accessLookup.containsKey(s.Id)) continue;
            String key = String.valueOf(s.Id);
            docItems.add(new AttachmentInfo(s, attExtLookup.containsKey(key)? attExtLookup.get(key): null, accessLookup.get(s.Id)));         
        }   
        for(FeedItem s : feedItems)
        {
            //if(!accessLookup.containsKey(s.Id)) continue;
            String key = String.valueOf(s.Id);
            AttachmentInfo attInfo = new AttachmentInfo(s, attExtLookup.containsKey(key)? attExtLookup.get(key): null, accessLookup.get(s.Id));
            if(conventVersions.containsKey(s.RelatedRecordId))
            {
            attInfo.TitleUrl = conventVersions.get(s.RelatedRecordId).ContentDocumentId;
            }            
            docItems.add(attInfo);         
        }   

        docItems.sort();

        AttachmentInfoItems = docItems;       
        //System.debug('AttachmentInfoItems.size()=' + AttachmentInfoItems.size());
        if(docItems.isEmpty())
        {
            ItemsCountStr = '';
        }
        else 
        {
            ItemsCountStr = '(' + docItems.size() + ')';
        }          
    }
    public PageReference DeleteAttachment() 
    {
        try 
        {
            String msg ='';
            msg += DeleteSObjectById(System.currentPageReference().getParameters().get('coreid'));
            msg += DeleteSObjectById(System.currentPageReference().getParameters().get('extid'));

            if(!String.isBlank(msg))
            {   
                System.debug(msg);
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, msg));

            }
            RefreshDocList();                       
        }
        catch (Exception e)
        {
            ApexPages.addMessages(e);
            System.debug('DeleteAttachment exception: ' + e);
        }
        return null;
    }

    String DeleteSObjectById(String idStr)
    {
        if(String.isBlank(idStr)) return '';

        Id objId = Id.valueOf(idStr);
        String msg = '';
        String sep = '';
        if(objId.getSObjectType().getDescribe().isDeletable())
        {
            Database.DeleteResult dr = Database.delete(objId, false);
            if (!dr.isSuccess())
            {               
                for(Database.Error err : dr.getErrors()) 
                {
                    msg += sep + err.getStatusCode() + ': ' + err.getMessage();
                    sep = ' | ';
                }
            }
        }
        return msg;
    }

    public void SaveAttachmentExt() 
    {
        List<Attachment_Ext__c> itemsToSave = new List<Attachment_Ext__c>();
        for(AttachmentInfo a : this.AttachmentInfoItems)
        {
            itemsToSave.add(a.AttachmentExtension);
        }
        Database.upsert(itemsToSave, false);
        //return null;
    }

    public class AttachmentInfo implements Comparable
    {
        public AttachmentInfo(sObject att, Attachment_Ext__c attExt, UserRecordAccess recordAccess0)
        {
            CoreObject = att;
            RecordAccess = recordAccess0;

            if(attExt != null)
            {
                AttachmentExtension = attExt;
                ExtensionID = attExt.Id;
            }
            else
            {
                AttachmentExtension = new Attachment_Ext__c(AttachmentID__c = String.valueOf(att.Id), ParentID__c = String.valueOf(att.get('ParentId')));
                ExtensionID = '';
            }
            NoteAttachmentID = String.valueOf(att.Id);

            Schema.DescribeSObjectResult r = att.getSObjectType().getDescribe();
            ObjectTypeLabel = r.getLabel();
            ObjectType = r.getName();
            Title = String.valueOf(r.fields.getMap().containsKey('title') ? att.get('title') : att.get('name'));
            LastModifiedDate = (Datetime)att.get('LastModifiedDate');

            if(ObjectType =='Note')
            {
                Note n = (Note)CoreObject;
                this.CreatedBy = n.CreatedBy.Name;
                this.TitleUrl = NoteAttachmentID;
            }
            else if(ObjectType =='Attachment')
            {
                Attachment n = (Attachment)CoreObject;
                this.CreatedBy = n.CreatedBy.Name;
                this.TitleUrl = NoteAttachmentID;
            }
            else if(ObjectType =='FeedItem')
            {
                FeedItem n = (FeedItem)CoreObject;
                this.CreatedBy = n.CreatedBy.Name;
            }           
            CreatedByID = String.valueOf(att.get('CreatedById'));
        }

        public Integer compareTo(Object other) 
        {
            AttachmentInfo theOther = (AttachmentInfo) other;
            Integer result = 0;
            if(this.LastModifiedDate > theOther.LastModifiedDate) result = 1;
            else if(this.LastModifiedDate < theOther.LastModifiedDate) result = -1;
            return -1 * result;
        }

        
        public String TitleUrl {get; set;}

        public String ExtensionID {get; set;}
        public String NoteAttachmentID {get;set;} 
        public String ObjectType {get;set;}
        public String ObjectTypeLabel {get; set;}
        public String Title {get;set;}      
        public Attachment_Ext__c AttachmentExtension {get;set;}
        public Datetime LastModifiedDate {get;set;}
        public String CreatedBy {get;set;}
        public String CreatedByID {get;set;}
        public sObject CoreObject {get;set;}
        UserRecordAccess RecordAccess {get; set; }
        public String SyncToMobile {get;set;}

        public String NoteAttachmentID15 
        {
            get { return NoteAttachmentID.substring(0, 15); }
        }

        public String RelatedRecordId 
        {
            get
            {
                return (ObjectType == 'FeedItem')? String.valueOf(CoreObject.get('RelatedRecordId')).substring(0, 15): '';
            }
        }


        public String AttachmentActionStyle 
        {
            get 
            {
                return (ObjectType == 'Attachment')? 'display: inline' : 'display: none';
            }
        }
        public String NoteActionStyle
        {
            get 
            {
                return (ObjectType == 'Note')? 'display: inline' : 'display: none';
            }
        }
        public String FeedItemActionStyle 
        {
            get 
            {
                return (ObjectType == 'FeedItem')? 'display: inline' : 'display: none';
            }
        }
        public String ParentID { get; set; }
    }
}